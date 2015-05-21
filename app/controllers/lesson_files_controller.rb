class LessonFilesController < ApplicationController

  layout false

  require 'fileutils' # utilizado na remocao de diretorios, pois o "Dir.rmdir" nao remove diretorios que nao estejam vazios
  
  include LessonFileHelper
  include FilesHelper

  def index
    @lesson = Lesson.where(id: params[:lesson_id]).first
    allocation_tags_ids = AcademicAllocation.where(academic_tool_id: @lesson.lesson_module_id, academic_tool_type: 'LessonModule')
    .select(:allocation_tag_id).map(&:allocation_tag_id)

    authorize! :new, Lesson, on: [allocation_tags_ids]
    @address = @lesson.address

    raise 'error' unless @lesson && @lesson.type_lesson == Lesson_Type_File
  rescue
    error = true
  ensure
    render error ? { nothing: true, status: 500 } : { action: :index, satus: 200 }
  end

  def new
    begin
      @lesson  = Lesson.where(id: params[:lesson_id]).first
      verify_owner
      allocation_tags_ids = AcademicAllocation.where(academic_tool_id: @lesson.lesson_module_id, academic_tool_type: 'LessonModule').pluck(:allocation_tag_id)
      authorize! :new, Lesson, on: [allocation_tags_ids]
    
      @lesson.verify_files_before_change
      lesson_path = @lesson.path(true, false)

      if params[:type] == 'folder'
        folder_number, folder_name = '', t(:new_folder, scope: [:lessons, :files])
        params[:path] = '' if (params[:path] == File::SEPARATOR || params[:path] == Lesson.find(params[:lesson_id]).name) # se for pasta raiz, altera o path recebido
        path = File.join(lesson_path, params[:path]) # monta o endereco da nova pasta

        # Se a pasta ja existir, incrementa um numero a ela (Nova Pasta -> Nova Pasta1 -> Nova Pasta2)
        while File.exists?(File.join(path, "#{folder_name}#{folder_number}")) do
          folder_number = 0 if folder_number == ""
          folder_number += 1
        end

        Dir.mkdir(File.join(path, folder_name + "#{folder_number}"))

        log(@lesson, "lesson_files [new folder], lesson: #{@lesson.id}, name: '#{folder_name}'", LogAction::TYPE[:create]) rescue nil
      elsif params[:type] == 'upload' # upload de arquivos

        log_file_names = []
        ActiveRecord::Base.transaction do # so executa se estiverem todos ok
          params[:lesson_files][:files].each do |file|
            # verificacoes caso "passe" pelas que existem no javascript
            raise 'error' if file.tempfile.size > 200.megabytes # de tamanho
            raise 'error' if Solar::Application.config.black_list[:extensions].include?(file.original_filename.split(".").last) # de extensão
            log_file_names << [params[:lesson_files][:path], file.original_filename].compact.join("/")

            tmp  = file.tempfile # arquivo temporario com informacoes do arquivo enviado
            file = File.join(lesson_path, params[:lesson_files][:path], file.original_filename)
            FileUtils.cp tmp.path, file # copia conteudo para o arquivo criado
          end

          log(@lesson, "lesson_files [upload file], lesson: #{@lesson.id}, files: #{log_file_names.join(", ")}", LogAction::TYPE[:create]) rescue nil
        end
      end

      @address = @lesson.address
      receive_updates_lessons = @lesson.receive_updates_lessons
      log(@lesson, "lessons: #{receive_updates_lessons.pluck(:id)}, [remove files and copy original] original: #{@lesson.id}") rescue nil if receive_updates_lessons.any?
    rescue
      error = true
    end

    render error ? { nothing: true, status: 500 } : { action: :index, status: 200 }
  end

  def edit
    begin
      @lesson  = Lesson.where(id: params[:lesson_id]).first
      verify_owner
      allocation_tags_ids = AcademicAllocation.where(academic_tool_id: @lesson.lesson_module_id, academic_tool_type: 'LessonModule')
      .select(:allocation_tag_id).map(&:allocation_tag_id)
      authorize! :new, Lesson, on: [allocation_tags_ids]

      raise 'error' unless @lesson.verify_files_before_change
      lesson_path = @lesson.path(true, false)

      if params[:type] == 'rename' # renomear
        path       = File.join(lesson_path, params[:path])
        path_split = get_path_without_last_dir(path) # recupera caminho sem o nome atual do arquivo/pasta
        new_path   = File.join(path_split, params[:node_name]) # /media/lessons/lesson_id/path_parte1/node_name

        raise 'error' if File.exists?(new_path)
        FileUtils.mv path, new_path # renomeia

        if @lesson.address.include?(params[:path])
          path           = get_path_without_last_dir(params[:path])
          # se for elemento localizado na raiz, o resultado de "get_path_without_last_dir" sera "" ou "/", portanto, nestes casos, não deve ser adicionado ao path a ser renomeado
          renamed_path   = ((path == "/" || path == "") ? [params[:node_name]] : File.join(path, params[:node_name]).split(File::SEPARATOR)) 
          lesson_address = @lesson.address.split(File::SEPARATOR) # quebra o caminho do arquivo inicial da aula
          lesson_address[renamed_path.size-1] = params[:node_name] # altera o elemento renomeado no caminho da aula
          @lesson.update_attribute(:address, File.join(lesson_address))
        end

        log(@lesson, "lesson_files [rename file], lesson: #{@lesson.id}, '#{params[:path]}' to '#{params[:node_name]}'") rescue nil
      elsif params[:type] == 'move' # mover
        params[:paths_to_move].each do |node_path|
          path       = File.join(lesson_path, node_path)
          new_path   = File.join(lesson_path, params[:path_to_move_to])
          path_split = get_path_without_last_dir(path)

          raise 'error' if !File.exist?(path) && (new_path == path_split) # erro se pasta não existir ou se for para ela mesma
          FileUtils.mv path, new_path
        end
        # se moveu para a raiz, "path_to_move_to" vira "", adicionando, assim, uma "/" indevida no momento que realizar o File.join
        new_address = (params[:path_to_move_to] == "" ? params[:initial_file_path] : File.join(params[:path_to_move_to], params[:initial_file_path]))
        @lesson.update_attribute(:address, new_address) unless params[:initial_file_path] == "false"

        log(@lesson, "lesson_files [move file], lesson: #{@lesson.id}, '#{params[:paths_to_move].join(", ")}' to '/#{params[:path_to_move_to]}'") rescue nil
      elsif params[:type] == 'initial_file' # arquivo inicial
        raise 'error'  unless File.file?(File.join(lesson_path, params[:path])) # verifica se existe e se é arquivo
        path = params[:path].split(File::SEPARATOR).delete_if {|f|f == '' || f.nil?}.join(File::SEPARATOR)
        @lesson.update_attribute(:address, path)

        log(@lesson, "lesson_files [initial file], lesson: #{@lesson.id}, '#{params[:path]}'") rescue nil
      end
      @address = @lesson.address

      receive_updates_lessons = @lesson.receive_updates_lessons
      log(@lesson, "lessons: #{receive_updates_lessons.pluck(:id)}, [remove files and copy original] original: #{@lesson.id}") rescue nil if receive_updates_lessons.any?
    rescue
      error = true
    end

    render error ? { nothing: true, status: 500 } : { action: :index, status: :ok }
  end

  def destroy
    begin
      @lesson  = Lesson.where(id: params[:lesson_id]).first
      verify_owner
      allocation_tags_ids = AcademicAllocation.where(academic_tool_id: @lesson.lesson_module_id, academic_tool_type: 'LessonModule').select(:allocation_tag_id).map(&:allocation_tag_id)
      authorize! :new, Lesson, on: [allocation_tags_ids]

      raise 'error' unless @lesson.verify_files_before_change

      params[:path] = '*' if params[:root_node] == 'true' # ignora a pasta raiz caso delete todos os arquivos da aula
      # erro se estiver tentando remover o arquivo inicial ou alguma pasta "superior" à ele e não for a pasta raiz
      raise 'error' if params[:root_node] != 'true' && @lesson.address.include?(params[:path])
      path = @lesson.path(true, false).to_s
      @lesson.update_attributes({ address: '', status: 0 }) if params[:root_node] == 'true'
      @address = @lesson.address

      FileUtils.rm_rf Dir.glob(File.join(path, params[:path])) # remove arquivos sem remover diretorio raiz

      log(@lesson, "lesson_files [destroy file], lesson: #{@lesson.id}, #{params[:path]}", LogAction::TYPE[:destroy]) rescue nil
      receive_updates_lessons = @lesson.receive_updates_lessons
      log(@lesson, "lessons: #{receive_updates_lessons.pluck(:id)}, [remove files and copy original] original: #{@lesson.id}") rescue nil if receive_updates_lessons.any?
    rescue
      error = true
    end

    render error ? { nothing: true, status: 500 } : { action: :index, satus: 200 }
  end

  def extract_files
    @lesson = Lesson.find(params[:lesson_id])
    verify_owner
    allocation_tags_ids = AcademicAllocation.where(academic_tool_id: @lesson.lesson_module_id, academic_tool_type: 'LessonModule')
      .select(:allocation_tag_id).map(&:allocation_tag_id)
    authorize! :update, Lesson, on: [allocation_tags_ids] # com permissao para editar aula

    file = Lesson::FILES_PATH.join(params[:lesson_id], params[:file])
    to   = File.dirname(file)

    result = extract(file, to)
    if result === true
      log(@lesson, "lesson_files [extract file], lesson: #{@lesson.id}, #{params[:file]}") rescue nil
      receive_updates_lessons = @lesson.receive_updates_lessons
      log(@lesson, "lessons: #{receive_updates_lessons.pluck(:id)}, [remove files and copy original] original: #{@lesson.id}") rescue nil if receive_updates_lessons.any?
      render :index
    else
      render json: { success: false, msg: result }, status: :unprocessable_entity
    end
  end

  private

    def get_path_without_last_dir(path)
      path_split = path.split(File::SEPARATOR)       # [media, lessons, lesson_id, path_parte1, path_parte2]
      path_split.delete_at(path_split.size-1)        # [media, lessons, lesson_id, path_parte1]
      return File.join(path_split) + File::SEPARATOR # /media/lessons/lesson_id/path_parte1/
    end

    def params_to_log
      { user_id: current_user.id, ip: request.remote_ip }
    end

    def log(lesson, message, type=LogAction::TYPE[:update])
      lesson.academic_allocations.each do |ac|
        LogAction.create(params_to_log.merge!(description: message, academic_allocation_id: ac.id, log_type: type))
      end
    end

    def verify_owner
      raise CanCan::AccessDenied if @lesson.privacy && @lesson.user_id != current_user.id
    end

end

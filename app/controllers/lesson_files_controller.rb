class LessonFilesController < ApplicationController

  layout false

  require 'fileutils' # utilizado na remoção de diretórios, pois o "Dir.rmdir" não remove diretórios que não estejam vazis
  
  include LessonFileHelper

  def index
    begin 
      @lesson = Lesson.where(id: params[:lesson_id]).first
      authorize! :new, Lesson, on: [@lesson.lesson_module.allocation_tag_id]
      @address = @lesson.address

      raise 'error' unless @lesson and @lesson.type_lesson == Lesson_Type_File
    rescue
      error = true
    end

    render error ? {nothing: true, status: 500} : {action: :index, satus: 200}
  end

  def new
    begin
      @lesson  = Lesson.where(id: params[:lesson_id]).first
      authorize! :new, Lesson, on: [@lesson.lesson_module.allocation_tag_id]
      lesson_path = @lesson.path(true, false)

      if params[:type] == 'folder'
        folder_number, folder_name = '', t(:new_folder, scope: [:lessons, :files])
        params[:path] = '' if (params[:path] == File::SEPARATOR or params[:path] == Lesson.find(params[:lesson_id]).name) # se for pasta raiz, altera o path recebido
        path = File.join(lesson_path, params[:path]) # monta o endereço da nova pasta

        # Se a pasta já existir, incrementa um número à ela (Nova Pasta -> Nova Pasta1 -> Nova Pasta2)
        while File.exists?(File.join(path, "#{folder_name}#{folder_number}")) do
          folder_number = 0 if folder_number == ""
          folder_number += 1
        end

        Dir.mkdir(File.join(path, folder_name + "#{folder_number}"))
      elsif params[:type] == 'upload' # upload de arquivos

        ActiveRecord::Base.transaction do # só executa se estiverem todos ok
          params[:lesson_files][:files].each do |file|
            # verificações caso "passe" pelas que existem no javascript
            raise 'error' if file.tempfile.size > 200.megabytes # de tamanho
            raise 'error' if Solar::Application.config.black_list[:extensions].include?(file.original_filename.split(".").last) # de extensão
            tmp  = file.tempfile # arquivo temporário com informações do arquivo enviado
            file = File.join(lesson_path, params[:lesson_files][:path], file.original_filename)

            FileUtils.cp tmp.path, file # copia conteúdo para o arquivo criado
          end
        end
      end

      @address = @lesson.address

    rescue CanCan::AccessDenied
      error = true
    rescue
      error = true
    end

    render error ? {nothing: true, status: 500} : {action: :index, satus: 200}
  end

  def edit
    begin
      @lesson  = Lesson.where(id: params[:lesson_id]).first
      authorize! :new, Lesson, on: [@lesson.lesson_module.allocation_tag_id]
      lesson_path = @lesson.path(true, false)

      if params[:type] == 'rename' # renomear
        path       = File.join(lesson_path, params[:path])
        path_split = get_path_without_last_dir(path) # recupera caminho sem o nome atual do arquivo/pasta
        new_path   = File.join(path_split, params[:node_name]) # /media/lessons/lesson_id/path_parte1/node_name

        raise "error" if File.exists?(new_path)
        FileUtils.mv path, new_path # renomeia

        if @lesson.address.include?(params[:path])
          path           = get_path_without_last_dir(params[:path])
          # se for elemento localizado na raiz, o resultado de "get_path_without_last_dir" será "" ou "/", portanto, nestes casos, não deve ser adicionado ao path a ser renomeado
          renamed_path   = ((path == "/" or path == "") ? [params[:node_name]] : File.join(path, params[:node_name]).split(File::SEPARATOR)) 
          lesson_address = @lesson.address.split(File::SEPARATOR) # quebra o caminho do arquivo inicial da aula
          lesson_address[renamed_path.size-1] = params[:node_name] # altera o elemento renomeado no caminho da aula
          @lesson.update_attribute(:address, File.join(lesson_address))
        end

      elsif params[:type] == 'move' # mover
        params[:paths_to_move].each do |node_path|
          path       = File.join(lesson_path, node_path)
          new_path   = File.join(lesson_path, params[:path_to_move_to])
          path_split = get_path_without_last_dir(path)

          raise "error" if (not File.exist?(path)) and (new_path == path_split) # erro se pasta não existir ou se for para ela mesma
          FileUtils.mv path, new_path  
        end
        # se moveu para a raiz, "path_to_move_to" virá "", adicionando, assim, uma "/" indevida no momento que realizar o File.join
        new_address = (params[:path_to_move_to] == "" ? params[:initial_file_path] : File.join(params[:path_to_move_to], params[:initial_file_path]))
        # raise "#{params[:path_to_move_to]} - #{new_address} - #{params[:initial_file_path]}"
        @lesson.update_attribute(:address, new_address) unless params[:initial_file_path] == "false"

      elsif params[:type] == "initial_file" # arquivo inicial
        raise "error"  unless File.file?(File.join(lesson_path, params[:path])) # verifica se existe e se é arquivo
        path = params[:path].split(File::SEPARATOR).delete_if {|f|f == '' or f.nil?}.join(File::SEPARATOR)
        @lesson.update_attribute(:address, path)
      end
      @address = @lesson.address

    rescue Exception => error
      # raise "#{error}"
      error = true
    end

    render error ? {nothing: true, status: 500} : {action: :index, satus: :ok}
  end

  def destroy

    begin
      @lesson  = Lesson.where(id: params[:lesson_id]).first
      authorize! :new, Lesson, on: [@lesson.lesson_module.allocation_tag_id]

      params[:path] = '' if params[:root_node] == 'true' # ignora a pasta raiz caso delete todos os arquivos da aula
      # erro se estiver tentando remover o arquivo inicial ou alguma pasta "superior" à ele e não for a pasta raiz
      raise "error" if params[:root_node] != 'true' and @lesson.address.include?(params[:path]) 
      path     = @lesson.path(true, false).to_s
      @lesson.update_attribute(:address, '') if params[:root_node] == 'true'
      @address = @lesson.address

      FileUtils.rm_rf File.join(path, params[:path]) # remove diretório com todo o seu conteúdo
      FileUtils.mkdir_p(path) # cria uma nova pasta para a aula se não existir
    rescue CanCan::AccessDenied
      error = true
    rescue
      error = true
    end

    render error ? {nothing: true, status: 500} : {action: :index, satus: 200}
  end

  private

    def get_path_without_last_dir(path)
      path_split = path.split(File::SEPARATOR)       # [media, lessons, lesson_id, path_parte1, path_parte2]
      path_split.delete_at(path_split.size-1)        # [media, lessons, lesson_id, path_parte1]
      return File.join(path_split) + File::SEPARATOR # /media/lessons/lesson_id/path_parte1/
    end

end

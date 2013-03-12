class LessonFilesController < ApplicationController

  include LessonFileHelper
  require 'fileutils' # utilizado na remoção de diretórios, pois o "Dir.rmdir" não remove diretórios que não estejam vazis

  skip_before_filter :verify_authenticity_token # necessário para, ao excluir um arquivo ou pasta, não perder a token do formulário 
  layout false

  def index

    begin 

      @lesson = Lesson.where(id: params[:lesson_id]).first
      authorize! :new, Lesson, on: [@lesson.lesson_module.allocation_tag_id]
      raise "error" unless @lesson and @lesson.type_lesson == Lesson_Type_File
      # file_default = lesson.address
      file     = File.join(Lesson::FILES_PATH, params[:lesson_id])
      Dir.mkdir(file) unless File.exist?(file)
      @files   = directory_hash(file, @lesson.name).to_json
      @folders = directory_hash(file, @lesson.name, false).to_json
    rescue CanCan::AccessDenied
      error = true
    rescue Exception => error
      error = true
    end

    respond_to do |format|
      format.html{ render error ? {nothing: true, status: 500} : {action: :index, satus: 200} }
    end

  end

  def new
    
    begin
      
      @lesson  = Lesson.where(id: params[:lesson_id]).first
      authorize! :new, Lesson, on: [@lesson.lesson_module.allocation_tag_id]

      if params[:type] == "folder"

        folder_number, folder_name = "", t(:new_folder, scope: [:lessons, :files])

        params[:path] = "" if params[:path].split(File::SEPARATOR)[1] == Lesson.find(params[:lesson_id]).name # se for pasta raiz, altera o path recebido
        path          = File.join("#{Rails.root}", "media", "lessons", params[:lesson_id], params[:path]) # monta o endereço da nova pasta

        # Se a pasta já existir, incrementa um número à ela (Nova Pasta -> Nova Pasta1 -> Nova Pasta2)
        while File.exists?(File.join(path, "#{folder_name}#{folder_number}")) do
          folder_number = 0 if folder_number == ""
          folder_number += 1
        end

        Dir.mkdir(File.join(path, folder_name + "#{folder_number}"))

      elsif params[:type] == "upload" # upload de arquivos

        ActiveRecord::Base.transaction do # só executa se estiverem todos ok
          params[:lesson_files][:files].each do |file|
            # verificações caso "passe" pelas que existem no javascript
            raise "error" if file.tempfile.size > 200.megabytes # de tamanho
            raise "error" if Solar::Application.config.black_list[:extensions].include?(file.original_filename.split(".").last) # de extensão
            tmp  = file.tempfile # arquivo temporário com informações do arquivo enviado
            file = File.join("#{Rails.root}", "media", "lessons", params[:lesson_id], params[:lesson_files][:path], file.original_filename) #adicionar parametro: path_to_add_to # cria arquivo vazio
            FileUtils.cp tmp.path, file # copia conteúdo para o arquivo criado
          end
        end

      end
    rescue CanCan::AccessDenied
      error = true
    rescue Exception => error
      error = true
    end

    # como está renderizando, os valores devem ser enviados novamente
    file     = File.join(Lesson::FILES_PATH, params[:lesson_id])
    @files   = directory_hash(file, @lesson.name).to_json
    @folders = directory_hash(file, @lesson.name, false).to_json

    respond_to do |format|
      format.html{ render error ? {nothing: true, status: 500} : {action: :index, satus: 200} }
    end
  end

  def edit

    begin
      
      @lesson  = Lesson.where(id: params[:lesson_id]).first
      authorize! :new, Lesson, on: [@lesson.lesson_module.allocation_tag_id]

      if params[:type] == "rename" # renomear

        path       = File.join("#{Rails.root}", "media", "lessons", params[:lesson_id], params[:path])
        path_split = get_path_without_last_dir(path) # recupera caminho sem o nome atual do arquivo/pasta
        new_path   = File.join(path_split, params[:node_name]) # /media/lessons/lesson_id/path_parte1/node_name
        FileUtils.mv path, new_path # renomeia

      elsif params[:type] == "move" # mover

        params[:paths_to_move].each do |node_path|
          path       = File.join("#{Rails.root}", "media", "lessons", params[:lesson_id], node_path)
          new_path   = File.join("#{Rails.root}", "media", "lessons", params[:lesson_id], params[:path_to_move_to])
          path_split = get_path_without_last_dir(path)
          FileUtils.mv path, new_path if File.exist?(path) and (new_path != path_split) # tenta mover a não ser que não exista ou que seja para a mesma pasta
        end
      end

    rescue CanCan::AccessDenied
      error = true
    rescue Exception => error
      error = true
    end

    # como está renderizando, os valores devem ser enviados novamente
    file     = File.join(Lesson::FILES_PATH, params[:lesson_id])
    @files   = directory_hash(file, @lesson.name).to_json
    @folders = directory_hash(file, @lesson.name, false).to_json

    respond_to do |format|
      format.html{ render error ? {nothing: true, status: 500} : {action: :index, satus: 200} }
    end
  end

  def destroy

    begin
      @lesson  = Lesson.where(id: params[:lesson_id]).first
      authorize! :new, Lesson, on: [@lesson.lesson_module.allocation_tag_id]

      params[:path] = "" if params[:root_node] == true # ignora a pasta raiz caso delete todos os arquivos da aula
      path          = File.join("#{Rails.root}", "media", "lessons", params[:lesson_id])
      FileUtils.rm_rf File.join(path, params[:path]) # remove diretório com todo o seu conteúdo
      Dir.mkdir(path) if params[:root_node] == true # cria uma nova pasta para a aula
    rescue CanCan::AccessDenied
      error = true
    rescue 
      error = true
    end

    # como está renderizando, os valores devem ser enviados novamentes
    file     = File.join(Lesson::FILES_PATH, params[:lesson_id])
    @files   = directory_hash(file, @lesson.name).to_json
    @folders = directory_hash(file, @lesson.name, false).to_json

    respond_to do |format|
      format.html{ render error ? {nothing: true, status: 500} : {action: :index, satus: 200} }
    end
  end

  private

  def get_path_without_last_dir(path)
    path_split = path.split(File::SEPARATOR)       # [media, lessons, lesson_id, path_parte1, path_parte2]
    path_split.delete(path_split.last)             # [media, lessons, lesson_id, path_parte1]
    return File.join(path_split) + File::SEPARATOR # /media/lessons/lesson_id/path_parte1/
  end

end

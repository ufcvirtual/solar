class LessonFilesController < ApplicationController

  include LessonFileHelper
  require 'fileutils' # utilizado na remoção de diretórios, pois o "Dir.rmdir" não remove diretórios que não estejam vazis

  skip_before_filter :verify_authenticity_token # necessário para, ao excluir um arquivo ou pasta, não perder a token do formulário 

  layout false

  def index
    @lesson = Lesson.where(id: params[:lesson_id]).first

    if @lesson and @lesson.type_lesson == Lesson_Type_File
      # file_default = lesson.address
      file     = File.join(Lesson::FILES_PATH, params[:lesson_id])
      Dir.mkdir(file) unless File.exist?(file)
      @files   = directory_hash(file, @lesson.name).to_json
      @folders = directory_hash(file, @lesson.name, false).to_json
    end

  end

  def new
    if params[:type] == "folder"
      begin
        params[:path] = "" if params[:path].split(File::SEPARATOR)[1] == Lesson.find(params[:lesson_id]).name
        path          = File.join("#{Rails.root}", "media", "lessons", params[:lesson_id], params[:path], params[:folder_name])
        Dir.mkdir(path)
      rescue
        error = true
      end

      @lesson  = Lesson.where(id: params[:lesson_id]).first
      file     = File.join(Lesson::FILES_PATH, params[:lesson_id])
      @files   = directory_hash(file, @lesson.name).to_json
      @folders = directory_hash(file, @lesson.name, false).to_json

      respond_to do |format|
        format.html{ render (error ? {:nothing => true} : :index), :status => (error ? 500 : 200) }
      end
    end
  end

  def edit

    file = File.join(Lesson::FILES_PATH, params[:lesson_id])
    Dir.mkdir(file) unless File.exist?(file)

    begin
      if params[:type] == "rename" # renomear

        path       = File.join("#{Rails.root}", "media", "lessons", params[:lesson_id], params[:path])
        path_split = get_path_without_last_dir(path)
        new_path   = File.join(path_split, params[:node_name]) # /media/lessons/lesson_id/path_parte1/node_name
        FileUtils.mv path, new_path # renomeia

      elsif params[:type] == "move" # mover

        params[:paths_to_move].each do |node_path|
          path       = File.join("#{Rails.root}", "media", "lessons", params[:lesson_id], node_path)
          new_path   = File.join("#{Rails.root}", "media", "lessons", params[:lesson_id], params[:path_to_move_to])
          path_split = get_path_without_last_dir(path)
          FileUtils.mv path, new_path if File.exist?(path) and (new_path != path_split) # tenta mover a não ser que não exista ou que seja para a mesma pasta
        end

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

    rescue Exception => error
      error = true
    end

    @lesson  = Lesson.where(id: params[:lesson_id]).first
    file     = File.join(Lesson::FILES_PATH, params[:lesson_id])
    @files   = directory_hash(file, @lesson.name).to_json
    @folders = directory_hash(file, @lesson.name, false).to_json

    respond_to do |format|
      format.html{ render (error ? {:nothing => true} : :index), :status => (error ? 500 : 200) }
    end
  end

  def destroy
    begin
      params[:path] = "" if params[:root_node] == true # ignora a pasta raiz caso delete todos os arquivos da aula
      path          = File.join("#{Rails.root}", "media", "lessons", params[:lesson_id])
      FileUtils.rm_rf File.join(path, params[:path]) # remove diretório com todo o seu conteúdo
      Dir.mkdir(path) if params[:root_node] == true # cria uma nova pasta para a aula
    rescue 
      error = true
    end

    @lesson  = Lesson.where(id: params[:lesson_id]).first
    file     = File.join(Lesson::FILES_PATH, params[:lesson_id])
    @files   = directory_hash(file, @lesson.name).to_json
    @folders = directory_hash(file, @lesson.name, false).to_json

    respond_to do |format|
      format.html{ render (error ? {:nothing => true} : :index), :status => (error ? 500 : 200) }
    end
  end

  private

  def get_path_without_last_dir(path)
    path_split = path.split(File::SEPARATOR)       # [media, lessons, lesson_id, path_parte1, path_parte2]
    path_split.delete(path_split.last)             # [media, lessons, lesson_id, path_parte1]
    return File.join(path_split) + File::SEPARATOR # /media/lessons/lesson_id/path_parte1/
  end

end

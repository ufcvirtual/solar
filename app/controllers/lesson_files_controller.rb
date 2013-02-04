class LessonFilesController < ApplicationController

  layout "define_token"
  require 'fileutils' # utilizado na remoção de diretórios, pois o "Dir.rmdir" não remove diretórios que não estejam vazis


  def index
    @lesson = Lesson.where(id: params[:lesson_id]).first

    if @lesson and @lesson.type_lesson == Lesson_Type_File
      # file_default = lesson.address
      file     = File.join(Lesson::FILES_PATH, params[:lesson_id])
      Dir.mkdir(file) unless File.exist?(file)
      @files   = directory_hash(file, @lesson.name).to_json
      @folders = directory_hash(file, @lesson.name, false).to_json
    end

    # render :layout => "define_token"
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

      @lesson = Lesson.where(id: params[:lesson_id]).first
      file     = File.join(Lesson::FILES_PATH, params[:lesson_id])
      @files   = directory_hash(file, @lesson.name).to_json
      @folders = directory_hash(file, @lesson.name, false).to_json

      respond_to do |format|
        format.html{ render (error ? {:nothing => true} : :index), :status => (error ? 500 : 200) }
      end
    end
  end

  def edit

    begin
      if params[:type] == "rename" # renomear

        path       = File.join("#{Rails.root}", "media", "lessons", params[:lesson_id], params[:path])
        path_split = path.split(File::SEPARATOR)               #[media, lessons, lesson_id, path_parte1, path_parte2]
        path_split.delete(path_split.last)                     #[media, lessons, lesson_id, path_parte1]
        new_path   = File.join(path_split, params[:node_name]) #/media/lessons/lesson_id/path_parte1/node_name]
        FileUtils.mv path, new_path # renomeia

      elsif params[:type] == "move" # mover
        params[:paths_to_move].each do |node_path|
          path     = File.join("#{Rails.root}", "media", "lessons", params[:lesson_id], node_path)
          new_path = File.join("#{Rails.root}", "media", "lessons", params[:lesson_id], params[:path_to_move_to])
          FileUtils.mv path, new_path if File.exist?(path) # move
        end

      end

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

  def destroy
    begin
      params[:path] = "" if params[:root_node] == true # ignora a pasta raiz caso delete todos os arquivos da aula
      path          = File.join("#{Rails.root}", "media", "lessons", params[:lesson_id])
      FileUtils.rm_rf File.join(path, params[:path]) # remove diretório com todo o seu conteúdo
      Dir.mkdir(path) if params[:root_node] == true # cria uma nova pasta para a aula
    rescue 
      error = true
    end

    @lesson = Lesson.where(id: params[:lesson_id]).first
    file     = File.join(Lesson::FILES_PATH, params[:lesson_id])
    @files   = directory_hash(file, @lesson.name).to_json
    @folders = directory_hash(file, @lesson.name, false).to_json

    respond_to do |format|
      format.html{ render (error ? {:nothing => true} : :index), :status => (error ? 500 : 200) }
    end
  end

  private

    def directory_hash(path, name=nil, get_children=true)
      data = {title: (name || path)}
      data[:children] = children = []
      data[:isFolder] = true
      Dir.foreach(path) do |entry|
        next if ['.', '..'].include?(entry)
        full_path = File.join(path, entry)
        if File.directory?(full_path)
          children << directory_hash(full_path, entry, get_children)
        elsif get_children
          children << entry
        end
      end
      return data
    end

end

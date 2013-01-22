class LessonFilesController < ApplicationController

   require 'fileutils' # utilizado na remoção de diretórios, pois o "Dir.rmdir" não remove diretórios que não estejam vazis

  def index
    # raise "#{params[:lesson_id]}"
    @lesson = Lesson.where(id: params[:lesson_id]).first

    if @lesson and @lesson.type_lesson == Lesson_Type_File
      # file_default = lesson.address
      file    = File.join(Lesson::FILES_PATH, params[:lesson_id])
      @files  = directory_hash(file, @lesson.name).to_json if File.exist?(file)
    end
  end

  def show
  end

  def new
  end

  def new_folder
    begin
      params[:path] = "" if params[:path].split("/")[1] == Lesson.find(params[:lesson_id]).name
      path = File.join("#{Rails.root}", "media", "lessons", params[:lesson_id], params[:path], params[:folder_name])
      Dir.mkdir(path)
      respond_to do |format|
        format.html{ render :nothing => true, :status => 500 }
      end
    rescue 
      respond_to do |format|
        format.html{ render :nothing => true, :status => 200 }
      end
    end
  end

  def rename_node
    print "#{params[:current_name]} - #{params[:new_name]} - #{params[:path]}"
  end

  def remove_node
    path = File.join("#{Rails.root}", "media", "lessons", params[:lesson_id], params[:path])
    FileUtils.rm_rf path
  end

  private

    def directory_hash(path, name=nil)
      data = {title: (name || path)}
      data[:children] = children = []
      data[:isFolder] = true
      Dir.foreach(path) do |entry|
        next if ['.', '..'].include?(entry)
        full_path = File.join(path, entry)
        if File.directory?(full_path)
          children << directory_hash(full_path, entry)
        else
          children << entry
        end
      end
      return data
    end

end

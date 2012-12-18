class LessonFilesController < ApplicationController

  def index
    lesson = Lesson.where(id: params[:lesson_id]).first

    if lesson and lesson.type_lesson == Lesson_Type_File
      # file_default = lesson.address
      file    = File.join(Lesson::FILES_PATH, params[:lesson_id])
      @files  = directory_hash(file, 'Raiz').to_json if File.exist?(file)
    end
  end

  def show
  end

  def new
  end

  def create
  end

  def update
  end

  def destroy
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

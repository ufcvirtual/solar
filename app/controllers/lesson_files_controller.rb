class LessonFilesController < ApplicationController

  def index
    ## verificar se a lesson existe
    # lesson = Lesson.find(params[:lesson_id])
    file = File.join(Lesson::FILES_PATH, params[:lesson_id])
    @files = directory_hash(file, 'RAIZ').to_json
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
      Dir.foreach(path) do |entry|
        next if (entry == '..' || entry == '.')
        full_path = File.join(path, entry)
        if File.directory?(full_path)
          data[:isFolder] = true
          children << directory_hash(full_path, entry)
        else
          children << entry
        end
      end
      return data
    end

end

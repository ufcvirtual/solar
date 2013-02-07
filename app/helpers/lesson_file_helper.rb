module LessonFileHelper

  ##
  # Retorna os diretórios existentes no caminho especificado
  ##
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
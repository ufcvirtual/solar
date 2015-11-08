module FilesHelper

  def download_file(redirect_error, pathfile, filename = nil)
    if (not pathfile.nil?) and (File.exist?(pathfile))
      send_file pathfile, filename: filename
    else
      redirect_to redirect_error, alert: t(:file_error_nonexistent_file)
    end
  end

  ##
  # {
  #   files: ['objfile1', 'objfile2', 'objfile3'],
  #   table_column_name: 'attachment'
  #   name_zip_file: 'ziped_file'
  # }
  # or
  # {
  #   under_path: ['/path/to/1', '/path/to/2'],
  #   name_zip_file: 'ziped_file'
  #   folders_names: ['folder_path1', 'folder_path2']
  # }
  ##
  def compress(opts = {})
    require 'zip'

    some_file_doesnt_exist = false

    ## arquivos e o caminho principal nao foram indicados
    return if not(opts[:files].present?) and not(opts[:under_path].present?)

    archive = File.join(Rails.root.to_s, 'tmp', '%s') << '.zip'
    ## arquivos armazenados sem uso de banco de dados
    if not(opts[:files].present?) # under_path present
      name_zip_file = opts[:name_zip_file].present? ? opts[:name_zip_file] : Digest::SHA1.hexdigest(opts[:under_path].join)
      archive       = archive % name_zip_file
      paths         = [opts[:under_path]].flatten.compact.uniq # caminhos de todos os arquivos

      FileUtils.rm archive, force: true
      Zip::File.open(archive, Zip::File::CREATE) do |zipfile| # criação do zip
        paths.each_with_index do |path, idx|
          dir = (opts[:folders_names].present?) ? opts[:folders_names][idx] : path.split('/').last
          zipfile.mkdir(dir)
          Dir["#{path}/**/**"].each do |file| # varre cada diretório/arquivo (file) dentro do diretório atual (path) e adiciona no zip
            zipfile.add(File.join(dir, file.sub(path + '/', '')), file) # nome do arquivo, path do arquivo 
          end # dir
        end # each
      end # zip
    else # :files esta presente
      ## objeto do banco de dados
      if opts[:files].first.respond_to?(opts[:table_column_name].to_sym)
        name_zip_file = Digest::SHA1.hexdigest(opts[:files].map(&opts[:table_column_name].to_sym).flatten.compact.sort.join)
        archive       = archive % name_zip_file

        return archive if File.exists?(archive)

        Zip::File.open(archive, Zip::File::CREATE) do |zipfile| # criação do zip
          make_tree(opts[:files], opts[:name_zip_file]).each do |dir, files|
            zipfile.mkdir(dir.to_s)
            # adiciona todos os arquivos do nível em questão no zip
            files.map do |file| 
              if File.exists?(file.attachment.path.to_s)
                begin
                  zipfile.add(File.join(dir.to_s, file.attachment_file_name), file.attachment.path.to_s) 
                rescue
                end
              else
                some_file_doesnt_exist = true
              end
            end
          end # each
        end # zip
      end # if
    end # if

    if some_file_doesnt_exist
      FileUtils.rm archive, force: true # remove o zip criado
      return false
    else
      return archive
    end
  end # compress

  ##
  # path_zip_file: File.join(Rails.root, 'media', 'lessons', 'lesson_id', 'aula_1', 'aula.zip') # ./media/lessons/lesson_id/aula_1/aula.zip
  # destination: File.join(Rails.root, 'media', 'lessons', 'lesson_id', 'aula_1', 'aula')       # ./media/lessons/lesson_id/aula_1/aula/
  ##
  def extract(path_zip_file, destination)
    require 'zip'

    return t(:file_doesnt_exist, scope: :lesson_files) unless File.exist?(path_zip_file)
    has_files_on_black_list = (Zip::File.open(path_zip_file).map {|f| f.to_s.split('.').last }.uniq.compact & Solar::Application.config.black_list[:extensions])
    return t(:zip_contains_invalid_files, scope: :lesson_files, files: has_files_on_black_list.join(', ')) if has_files_on_black_list.any?

    Zip::File.open(path_zip_file) do |zipfile|
      zipfile.each do |f|
        f_path = File.join(destination, f.name)
        FileUtils.mkdir_p(File.dirname(f_path))
        zipfile.extract(f, f_path) unless File.exist?(f_path)
      end # each
    end # zip

    return true
  end # extract

  def copy_file(from, to, dir, method='attachment')
    FileUtils.cp from.send(method.to_sym).path, File.join("#{Rails.root}", 'media', dir, [to.id.to_s, from.send("#{method}_file_name".to_sym)].join('_'))
  end

  private

    ## files with folder
    def make_tree(files, name_folder = nil)
      tree = {}
      # apenas um nível de arquivos/pastas
      if name_folder
        tree[name_folder] = files
      else
        # monta uma estrutura indicando os arquivos de cada pasta para quando há mais de um nível
        files.each do |file|
          tree[file.folder.to_sym] = [] unless tree[file.folder.to_sym].present?
          tree[file.folder.to_sym] << file if file.respond_to?(:folder) && !file.attachment_file_name.nil?
        end # each
      end
      tree.delete_if { |k,v| v.empty? }
    end

end

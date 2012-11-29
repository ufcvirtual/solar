module FilesHelper

  def download_file(redirect_error, pathfile, filename = nil)
    if File.exist?(pathfile)
      send_file pathfile, filename: filename
    else
      redirect_to redirect_error, alert: t(:file_error_nonexistent_file)
    end
  end

  ## DEPRECATED: use compress
  def make_zip_files(files, table_column_name, zip_name_folder = nil)
    compress({ files: files, table_column_name: table_column_name, name_zip_file: zip_name_folder })
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
  #   folders_names: ['folder_file1', 'folder_file2']
  # }
  ##
  def compress(opts = {})
    require 'zip/zip'

    ## arquivos e o caminho principal nao foram indicados
    return if not(opts[:files].present?) and not(opts[:under_path].present?)

    archive = File.join(Rails.root.to_s, 'tmp', '%s') << '.zip'
    if not(opts[:files].present?) # under_path present
      name_zip_file = opts[:name_zip_file].present? ? opts[:name_zip_file] : Digest::SHA1.hexdigest(opts[:under_path].join)
      archive       = archive % name_zip_file
      paths         = [opts[:under_path]].flatten.compact.uniq

      FileUtils.rm archive, force: true
      Zip::ZipFile.open(archive, Zip::ZipFile::CREATE) do |zipfile|
        paths.each_with_index do |path, idx|
          dir = (opts[:under_path].present? and opts[:folders_names].present?) ? opts[:folders_names][idx] : dir = path.split('/').last
          zipfile.mkdir(dir)
          Dir["#{path}/**/**"].each do |file|
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

        Zip::ZipFile.open(archive, Zip::ZipFile::CREATE) do |zipfile|
          make_tree(opts[:files]).each do |dir, files|
            zipfile.mkdir(dir.to_s)
            files.map { |file| zipfile.add(File.join(dir.to_s, file.attachment_file_name), file.attachment.path.to_s) if File.exists?(file.attachment.path.to_s) }
          end # each
        end # zip
      end # if
    end # if

    return archive
  end # compress

  def extract
    raise "not done yet"
  end

  private

    ## files with folder
    def make_tree(files)
      tree = {}
      files.each do |file|
        tree[file.folder.to_sym] = [] unless tree[file.folder.to_sym].present?
        tree[file.folder.to_sym] << file if file.respond_to?(:folder) and not(file.attachment_file_name.nil?)
      end # each
      tree.delete_if { |k,v| v.empty? }
    end

end

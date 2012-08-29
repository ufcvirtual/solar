module FilesHelper

  def download_file(redirect_error, pathfile, filename = nil)
    if File.exist?(pathfile)
      send_file pathfile, :filename => filename
    else
      respond_to do |format|
        format.html { redirect_to redirect_error, :alert => t(:file_error_nonexistent_file) }
      end
    end
  end

  ##
  # Cria zip de arquivos com folders internos e retorna o path do zip
  #
  # Obs.: O zip será gerado com um hash. Se o um arquivo com um mesmo hash já existir ele não será criado, apenas o path será retornado.
  #
  # Parameters:
  # - table_column_name: Coluna da tabela que identifica o nome do arquivo.
  # - zip_name_folder: Nome do folder principal do zip. Se nao for informado os arquivos serão criados sem diretório.
  ##
  def make_zip_files(files, table_column_name, zip_name_folder = nil)
    require 'zip/zip'

    all_file_names = files.collect{|file| [file[table_column_name]]}.flatten
    hash_name = Digest::SHA1.hexdigest(all_file_names.to_s)
    zip_name_folder = hash_name if zip_name_folder.nil?

    # hash que será usado como nome do arquivo zip
    all_files_ziped_name = File.join('tmp', "#{hash_name}.zip")

    ##
    # Verifica se já existe um arquivo zipado na tmp com o mesmo conteúdo.
    # Assim não será necessário recriar o zip, o usuário faz apenas download.
    ##
    existing_zip_files = Dir.glob('tmp/*') # lista dos arquivos .zip existentes no '/tmp'
    zip_created = existing_zip_files.include?(all_files_ziped_name) # informa se ja existe o arquivo de zip desejado
    name_internal_folder = ''

    # cria o zip caso nao esteja criado
    unless zip_created
      Zip::ZipFile.open(all_files_ziped_name, Zip::ZipFile::CREATE) do |zipfile|
        files.each do |file|
          unless file.attachment_file_name.nil?
            unless zip_created
              zipfile.mkdir(zip_name_folder) # cria folder geral para colocar todos os outros folders dentro dele
              zip_created = true
            end

            # cria um novo folder interno
            unless !file.attributes.include?('folder') or file.folder.nil?
              if name_internal_folder != file.folder and file.folder != ''
                name_internal_folder = file.folder
                zipfile.mkdir(File.join(zip_name_folder, name_internal_folder))
              end
            end

            zipfile.add(File.join(zip_name_folder, name_internal_folder, file.attachment_file_name), file.attachment.path) if File.exists?(file.attachment.path.to_s)
          end
        end
      end
    end

    unless zip_created
      # recupera arquivo
      zip_name = Zip::ZipFile.open(hash_name + ".zip", Zip::ZipFile::CREATE).to_s
      path_zip = File.join(Rails.root.to_s, 'tmp', zip_name)
    else
      pathfile = "#{Rails.root}/#{all_files_ziped_name}"
      send_file pathfile, :filename => all_files_ziped_name
    end
  end

end

class SupportMaterialFileController < ApplicationController

  include FilesHelper

  before_filter :prepare_for_group_selection, :only => [:list]

  def list
    authorize! :list, SupportMaterialFile

    allocation_tag_ids = AllocationTag.find_related_ids(active_tab[:url]['allocation_tag_id'])
    @list_files = SupportMaterialFile.find_files(allocation_tag_ids)

    # construindo um conjunto de objetos
    @folders_list = {}
    @list_files.collect { |file|
      @folders_list[file["folder"]] = [] unless @folders_list[file["folder"]].is_a?(Array) # utiliza nome do folder como chave da lista
      @folders_list[file["folder"]] << file
    }
  end

  def download
    authorize! :download, SupportMaterialFile

    curriculum_unit_id = active_tab[:url]['id']
    file = SupportMaterialFile.find(params[:id])
    download_file({:action => 'list', :id => curriculum_unit_id}, file.attachment.path, file.attachment_file_name)
  end

  def download_all_file_ziped
    authorize! :download_all_file_ziped, SupportMaterialFile

    allocation_tag_ids = AllocationTag.find_related_ids(active_tab[:url]['allocation_tag_id'])
    curriculum_unit_id = active_tab[:url]["id"]
    redirect_error = {:action => 'list', :id => curriculum_unit_id}

    # Recupearndo todos os arquivos e separando por folder
    all_files = SupportMaterialFile.find_files(allocation_tag_ids)
    path_zip = make_folders_zip(all_files, 'attachment_file_name', t(:support_folder_name))

    # download do zip
    download_file(redirect_error, path_zip)
  end

  def download_folder_file_ziped
    authorize! :download_folder_file_ziped, SupportMaterialFile

    allocation_tag_ids = AllocationTag.find_related_ids(active_tab[:url]['allocation_tag_id'])

    curriculum_unit_id = active_tab[:url]["id"]
    redirect_error = {:action => 'list', :id => curriculum_unit_id}
    
    all_files = SupportMaterialFile.find_files(allocation_tag_ids, params[:folder])
    path_zip = make_folders_zip(all_files, 'attachment_file_name', t(:support_folder_name))

    # download do zip
    download_file(redirect_error, path_zip)
  end

  private

  ##
  # Cria zip de arquivos com folders internos e retorna o path do zip
  #
  # Obs.: O zip será gerado com um hash. Se o um arquivo com um mesmo hash já existir ele não será criado, apenas o path será retornado.
  #
  # Parameters:
  # - table_column_name: Coluna da tabela que identifica o nome do arquivo.
  # - zip_name_folder: Nome do folder principal do zip. Se nao for informado os arquivos serão criados sem diretório.
  ##
  def make_folders_zip(files, table_column_name, zip_name_folder = nil)
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
      Zip::ZipFile.open(all_files_ziped_name, Zip::ZipFile::CREATE) { |zipfile|
        files.each do |file|
          unless file.attachment_file_name.nil?
            unless zip_created
              zipfile.mkdir(zip_name_folder) # cria folder geral para colocar todos os outros folders dentro dele
              zip_created = true
            end

            # cria um novo folder interno
            if name_internal_folder != file.folder and file.folder != ''
              name_internal_folder = file.folder
              zipfile.mkdir(File.join(zip_name_folder, name_internal_folder))
            end

            zipfile.add(File.join(zip_name_folder, name_internal_folder, file.attachment_file_name), file.attachment.path)
          end
        end
      }
    end

    # recupera arquivo
    zip_name = Zip::ZipFile.open(hash_name + ".zip", Zip::ZipFile::CREATE).to_s
    path_zip = File.join(Rails.root.to_s, 'tmp', zip_name)
  end
end

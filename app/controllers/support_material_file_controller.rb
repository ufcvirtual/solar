class SupportMaterialFileController < ApplicationController

  include FilesHelper

  before_filter :prepare_for_group_selection, :only => [:list]

  def list
    authorize! :list, SupportMaterialFile

    allocation_tag_id = active_tab[:url]['allocation_tag_id']

    @list_files = SupportMaterialFile.search_files(allocation_tag_id) # Pegar por allocation tag e colocar o combo da seleção de turma

    # construindo um conjunto de objetos
    @folders_list = {}
    @list_files.collect {|file|
      @folders_list[file["folder"]] = [] unless @folders_list[file["folder"]].is_a?(Array)
      @folders_list[file["folder"]] << file
    }

  end

 # DOWNLOADS
  def download
    authorize! :download, SupportMaterialFile

    curriculum_unit_id = active_tab[:url]['id']
    download_file({:action => 'list', :id => curriculum_unit_id}, SupportMaterialFile.find(params[:id]).attachment.path)
  end

  def download_all_file_ziped
    authorize! :download_all_file_ziped, SupportMaterialFile

    require 'zip/zip'
    allocation_tag_id = active_tab[:url]['allocation_tag_id']

    # Parâmetros de entrada pela página
    curriculum_unit_id = active_tab[:url]["id"]
    redirect_error = {:action => 'list', :id => curriculum_unit_id}

    # Consultas pela tabela
    nomes_files = SupportMaterialFile.search_files(allocation_tag_id).collect{|file| [file["attachment_file_name"]]}
    folder = SupportMaterialFile.search_files(allocation_tag_id).collect{|file| [file["folder"]]}
    lista_zips = Dir.glob('tmp/*') #lista dos arquivos .zip existentes no '/tmp'

    # nome do pacote que será criado
    zip_in_test = "tmp/"+Digest::SHA1.hexdigest(nomes_files.to_s)+".zip"

    exist_zip = false
    folder_create = ""
    file_cont = 0
    nulo = []

    lista_zips.each do |file_test|
      if file_test == zip_in_test # se não houver zip, na pasta 'tmp/' de mesmo conteúdo, então criasse o .zip
        exist_zip = true
        break
      end
    end

    if !exist_zip
      folder, nulo = folder.partition{|r| r != 'LINKS'}
      while file_cont < folder.length
        folder[file_cont] = folder[file_cont][0].to_s
        file_cont += 1
      end
      file_cont = 0

      Zip::ZipFile.open("tmp/#{Digest::SHA1.hexdigest(nomes_files.to_s)}.zip", Zip::ZipFile::CREATE) { |zipfile|
        nomes_files.each do |zipers|
          zipers = zipers[0].to_s
          unless(zipers[0].nil?)
            if !exist_zip
              zipfile.mkdir("Todos arquivos")
              exist_zip = true
           end
           #folder = SupportMaterialFile.where("allocation_tag_id = ? AND attachment_file_name = ?", allocation_tag_id, zipers).collect{|file| [file["folder"]]}
           #folder = folder[0][0].to_s
            if folder_create != folder[file_cont] && folder[file_cont] != ""
              folder_create = folder[file_cont].to_s
              zipfile.mkdir("Todos arquivos"+"/"+folder_create)
            end
              zipfile.add("Todos arquivos/"+folder_create+"/"+zipers,"media/support_material_file/"+SupportMaterialFile.where("attachment_file_name = "+"'"+zipers+"'").collect{|file| [file["id"]]}[0][0].to_s+"_"+zipers)
          end
          file_cont += 1
        end
      }
      exist_zip = false
    end

    # recupera arquivo

    zip_name = Zip::ZipFile.open(Digest::SHA1.hexdigest(nomes_files.to_s)+".zip", Zip::ZipFile::CREATE).to_s
    path_zip = "#{::Rails.root.to_s}/tmp/#{zip_name}"

    # download do zip
    download_file(redirect_error, path_zip)

  end

  def download_folder_file_ziped
    authorize! :download_all_file_ziped, SupportMaterialFile

    require 'zip/zip'
    allocation_tag_id = active_tab[:url]['allocation_tag_id']

    lista_zips = Dir.glob('tmp/*') #lista dos arquivos .zip existentes no '/tmp'

    curriculum_unit_id = active_tab[:url]["id"]
    redirect_error = {:action => 'list', :id => curriculum_unit_id}
    folder = params[:folder]

    nomes_files = SupportMaterialFile.where("allocation_tag_id = ? and folder = ?", allocation_tag_id, folder).collect{|file| [file["attachment_file_name"]]}

    # nome do pacote que será criado
    zip_in_test = "tmp/"+Digest::SHA1.hexdigest(nomes_files.to_s)+".zip"

    exist_zip = false

    lista_zips.each do |file_test|
      if file_test == zip_in_test # se não houver zip, na pasta 'tmp/' de mesmo conteúdo, então criasse o .zip
        exist_zip = true
        break
      end
    end

    if !exist_zip
      Zip::ZipFile.open("tmp/#{Digest::SHA1.hexdigest(nomes_files.to_s)}.zip", Zip::ZipFile::CREATE) { |zipfile|
        nomes_files.each do |zipers|
          zipers = zipers[0].to_s
          if !exist_zip
            zipfile.mkdir(folder)
            exist_zip = true
          end
          unless(zipers[0].nil?)
            zipfile.add(folder+"/"+zipers,"media/support_material_file/"+SupportMaterialFile.where("attachment_file_name = "+"'"+zipers+"'").collect{|file| [file["id"]]}[0][0].to_s+"_"+zipers)
          end
        end
      }
      exist_zip = false
    end

    # recupera arquivo

    zip_name = Zip::ZipFile.open(Digest::SHA1.hexdigest(nomes_files.to_s)+".zip", Zip::ZipFile::CREATE).to_s
    path_zip = "#{::Rails.root.to_s}/tmp/#{zip_name}"

    # download do zip
    download_file(redirect_error, path_zip)

  end
end

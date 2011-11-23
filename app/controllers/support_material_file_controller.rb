class SupportMaterialFileController < ApplicationController

  include FilesHelper

  before_filter :prepare_for_group_selection, :only => [:list]

  def list
    authorize! :list, SupportMaterialFile

    allocation_tag_id = user_session[:tabs][:opened][user_session[:tabs][:active]]['allocation_tag_id']

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

    curriculum_unit_id = user_session[:tabs][:opened][user_session[:tabs][:active]]['id']
    download_file({:action => 'list', :id => curriculum_unit_id}, SupportMaterialFile.find(params[:id]).attachment.path)
  end

  def download_all_file_ziped
    authorize! :download_all_file_ziped, SupportMaterialFile

    require 'zip/zip'
    active_tab = user_session[:tabs][:opened][user_session[:tabs][:active]]
    allocation_tag_id = active_tab['allocation_tag_id']

    # Parâmetros de entrada pela página
    curriculum_unit_id = active_tab["id"]
    redirect_error = {:action => 'list', :id => curriculum_unit_id}

    # Consultas pela tabela
    nomes_files = SupportMaterialFile.search_files(allocation_tag_id).collect{|file| [file["attachment_file_name"]]}
    lista_zips = Dir.glob('tmp/*') #lista dos arquivos .zip existentes no '/tmp'
    
    # nome do pacote que será criado
    zip_in_test = "tmp/"+Digest::SHA1.hexdigest(nomes_files.to_s)+".zip"

    result_test = 0

    lista_zips.each do |file_test|
      if file_test == zip_in_test # se não houver zip, na pasta 'tmp/' de mesmo conteúdo, então criasse o .zip
        result_test = 1
        break
      end
    end

    if result_test == 0
      Zip::ZipFile.open("tmp/#{Digest::SHA1.hexdigest(nomes_files.to_s)}.zip", Zip::ZipFile::CREATE) { |zipfile|
        nomes_files.each do |zipados|
          zipados = zipados[0].to_s
          unless(zipados[0].nil?)
            zipfile.add(zipados,"media/support_material_file/"+SupportMaterialFile.where("attachment_file_name = "+"'"+zipados+"'").collect{|file| [file["id"]]}[0][0].to_s+"_"+zipados)
          end
        end
      }
      result_test = 0
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
    active_tab = user_session[:tabs][:opened][user_session[:tabs][:active]]
    allocation_tag_id = active_tab['allocation_tag_id']

    lista_zips = Dir.glob('tmp/*') #lista dos arquivos .zip existentes no '/tmp'

    curriculum_unit_id = active_tab["id"]
    redirect_error = {:action => 'list', :id => curriculum_unit_id}
    folder = params[:folder]
        
    nomes_files = SupportMaterialFile.where("allocation_tag_id = ? and folder = ?", allocation_tag_id, folder).collect{|file| [file["attachment_file_name"]]}
        
    # nome do pacote que será criado
    zip_in_test = "tmp/"+Digest::SHA1.hexdigest(nomes_files.to_s)+".zip"

    result_test = 0

    lista_zips.each do |file_test|
      if file_test == zip_in_test # se não houver zip, na pasta 'tmp/' de mesmo conteúdo, então criasse o .zip
        result_test = 1
        break
      end
    end
        
    if result_test == 0
      Zip::ZipFile.open("tmp/#{Digest::SHA1.hexdigest(nomes_files.to_s)}.zip", Zip::ZipFile::CREATE) { |zipfile|
        nomes_files.each do |zipados|
          zipados = zipados[0].to_s
          unless(zipados[0].nil?)
            zipfile.add(zipados,"media/support_material_file/"+SupportMaterialFile.where("attachment_file_name = "+"'"+zipados+"'").collect{|file| [file["id"]]}[0][0].to_s+"_"+zipados)
          end
        end
      }
      result_test = 0
    end

    # recupera arquivo

    zip_name = Zip::ZipFile.open(Digest::SHA1.hexdigest(nomes_files.to_s)+".zip", Zip::ZipFile::CREATE).to_s
    path_zip = "#{::Rails.root.to_s}/tmp/#{zip_name}"

    # download do zip
    download_file(redirect_error, path_zip)

  end
end

include FilesHelper

class SupportMaterialFileController < ApplicationController
  before_filter :prepare_for_group_selection, :only => [:list]

  def list
    authorize! :list, SupportMaterialFile

    #    offer_id = session[:opened_tabs][session[:active_tab]]["offers_id"]
    #    group_id = session[:opened_tabs][session[:active_tab]]["groups_id"]
    #    user_id = current_user.id

    @list_files = SupportMaterialFile.search_files(3) # Pegar por allocation tag e colocar o combo da seleção de turma 

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

    filename = SupportMaterialFile.find(params[:id]).attachment_file_name
    prefix_file = params[:id]
    file_allocation_tag = params[:file_allocation_tag_id]
    path_file = "#{::Rails.root.to_s}/media/support_material_file/allocation_tags/#{file_allocation_tag}/"

    curriculum_unit_id = session[:opened_tabs][session[:active_tab]]["id"]
    redirect_error = {:action => 'list', :id => curriculum_unit_id}

    # recupera arquivo
    download_file(redirect_error, path_file, filename, prefix_file)

  end

  def download_all_file_ziped
    #raise "COLOCAR ALLOCATION TAG AQUI TAMBÉM!!!"
    authorize! :download_all_file_ziped, SupportMaterialFile
    require 'zip/zip'

    # Parâmetros de entrada pela página
    curriculum_unit_id = session[:opened_tabs][session[:active_tab]]["id"]
    redirect_error = {:action => 'list', :id => curriculum_unit_id}
    group_id = session[:opened_tabs][session[:active_tab]]["groups_id"]

    # Consultas pela tabela
    nomes_files = SupportMaterialFile.search_files(3).collect{|file| [file["attachment_file_name"]]}
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
                zipfile.add(zipados,"media/support_material_file/allocation_tags/"+3.to_s+"/"+SupportMaterialFile.where("attachment_file_name = "+"'"+zipados+"'").collect{|file| [file["id"]]}[0][0].to_s+"_"+zipados)
            end
        end
      }
      result_test = 0
    end

    # recupera arquivo

    zip_name = Zip::ZipFile.open(Digest::SHA1.hexdigest(nomes_files.to_s)+".zip", Zip::ZipFile::CREATE).to_s
    path_zip = "#{::Rails.root.to_s}/tmp/"

    # download do zip
    download_file(redirect_error, path_zip, zip_name)

  end
  
    def download_folder_file_ziped
        authorize! :download_all_file_ziped, SupportMaterialFile
        require 'zip/zip'

        lista_zips = Dir.glob('tmp/*') #lista dos arquivos .zip existentes no '/tmp'

        curriculum_unit_id = session[:opened_tabs][session[:active_tab]]["id"]
        redirect_error = {:action => 'list', :id => curriculum_unit_id}
        group_id = session[:opened_tabs][session[:active_tab]]["groups_id"]
        folder = params[:folder]
        
        nomes_files = SupportMaterialFile.where("allocation_tag_id = ? and folder = ?", 3, folder).collect{|file| [file["attachment_file_name"]]}
        
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
                    zipfile.add(zipados,"media/support_material_file/allocation_tags/"+3.to_s+"/"+SupportMaterialFile.where("attachment_file_name = "+"'"+zipados+"'").collect{|file| [file["id"]]}[0][0].to_s+"_"+zipados)
                end
            end
          }
          result_test = 0
        end

        # recupera arquivo

        zip_name = Zip::ZipFile.open(Digest::SHA1.hexdigest(nomes_files.to_s)+".zip", Zip::ZipFile::CREATE).to_s
        path_zip = "#{::Rails.root.to_s}/tmp/"

        # download do zip
        download_file(redirect_error, path_zip, zip_name)

    end
end

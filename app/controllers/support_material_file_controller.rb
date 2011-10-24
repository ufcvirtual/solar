class SupportMaterialFileController < ApplicationController
  before_filter :prepare_for_group_selection, :only => [:list]
  
  def list

    authorize! :list, SupportMaterialFile

    offer_id = session[:opened_tabs][session[:active_tab]]["offers_id"]
    group_id = session[:opened_tabs][session[:active_tab]]["groups_id"]
    user_id = current_user.id

    list_files = SupportMaterialFile.search_files(user_id, offer_id, group_id)
    
    # construindo um conjunto de objetos
    @folders_list = {}
    list_files.collect {|file|
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
    authorize! :download_all_file_ziped, SupportMaterialFile
    
    raise "Ainda nao implementado"
  end

end

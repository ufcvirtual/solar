class SupportMaterialController < ApplicationController

  before_filter :prepare_for_group_selection, :only => [:list]

  def list

#    authorize! :download_file_public_area, Portfolio

#    filename = SupportMaterial.find(params[:id]).attachment_file_name
#    prefix_file = params[:id]
#    path_file = "#{::Rails.root.to_s}/media/support_material/"
#
#    curriculum_unit_id = session[:opened_tabs][session[:active_tab]]["id"]
#    redirect_error = {:action => 'show', :id => curriculum_unit_id}
#
#    # recupera arquivo
#    download_file(redirect_error, path_file, filename, prefix_file)
    
  end

end

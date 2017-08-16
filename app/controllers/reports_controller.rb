class ReportsController < ApplicationController

  include ReportsHelper

  $document_title
  
  def index
    authorize! :index, Report
    @types = ((!EDX.nil? && EDX['integrated']) ? CurriculumUnitType.all : CurriculumUnitType.where('id <> 7'))
  rescue
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  end

  def types_reports
 
    allocation_tags = AllocationTag.get_by_params(params)
    @allocation_tags_ids, @selected, @offer_id = allocation_tags.values_at(:allocation_tags, :selected, :offer_id)
    authorize! :index, Report 
    @user_profiles       = current_user.resources_by_allocation_tags_ids(@allocation_tags_ids)
    @allocation_tags_ids = @allocation_tags_ids.join(" ")
    @is_curriculum_unit = params[:curriculum_unit_id].nil? ? nil : params[:curriculum_unit_id]
    @is_group = params[:groups_id].nil? ? nil : params[:groups_id]
    @is_semester = params[:semester_id].nil? ? nil : params[:semester_id]

    render partial: 'types_reports'
  rescue
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  def render_reports
   
    time = Time.now
    info = {  :Title        => "Solar",
              :Author       => "UFC Virtual",
              :Subject      => "Solar system reports examples",
              :Keywords     => "reports",
              :Creator      => "ACME Soft App",
              :Producer     => "Prawn",
              :CreationDate => Time.now}          

    Prawn::Document.new(:info => info) do |pdf|
      pdf.font_families.update("Ubuntu Condensed" => {
        :normal => "#{Rails.root}/app/assets/stylesheets/fonts/ubuntucondensed-regular-webfont.ttf",
        })
      pdf.font_families.update("PT Sans" => {
        :normal => "#{Rails.root}/app/assets/stylesheets/fonts/pt_sans-web-normal-webfont.ttf",
        :bold => "#{Rails.root}/app/assets/stylesheets/fonts/pt_sans-web-bold-webfont.ttf",
        :italic => "#{Rails.root}/app/assets/stylesheets/fonts/pt_sans-web-italic-webfont.ttf",
        :bold_italic => "#{Rails.root}/app/assets/stylesheets/fonts/pt_sans-web-bolditalic-webfont.ttf",
        })

      solar_logo = "#{Rails.root}/app/assets/images/reports/solar_logo_black.png"
      virtual = "#{Rails.root}/app/assets/images/reports/logovirtual.png"
      ufc = "#{Rails.root}/app/assets/images/reports/ufc_logo_oficial.png"

      pdf.font("PT Sans", :style => :bold)
      title = t('reports.index.main_document_title')
      pdf.text title, :align => :center

      # imagens...
      pdf.image virtual, :at => [500,pdf.cursor + 15], :width => 50
      pdf.image ufc, :at => [0,pdf.cursor + 15 ], :width => 40
      pdf.font("PT Sans", :style => :bold_italic, :size => 10)
      pdf.draw_text ReportsHelper::get_timestamp_pattern, :at => [0,0]

      set_document_title_final(params[:query_type])

      # document title
      pdf.move_down 15
      pdf.font("Ubuntu Condensed")
      pdf.fill_color '003E7A'
      pdf.text $document_title, :align => :center, :size => 14

      #information allocation
      if params[:query_type].to_i>1
        @ats = AllocationTag.find(params[:allocation_tags_ids])
        pdf.move_down 30 # documento referente ao periodo tal......
        pdf.font("PT Sans", :style => :italic ,:size => 10)
        pdf.fill_color '000000'
        pdf.text @ats.no_group_info.to_s
         #groups
        if !params[:groups].empty? 
          groups = Array.new 
          ats = params[:allocation_tags_ids].split(' ').map { |at| 
            groups << AllocationTag.find(at.to_i).groups.first.code
          }
          pdf.text groups.join(" , ")
        end  
      end  

      pdf.move_down 15 # documento referente ao periodo tal......
      pdf.font("PT Sans", :style => :italic ,:size => 10)
      pdf.fill_color '000000'
      pdf.text t('reports.commun_texts.timestamp_info')+ ": " + time.strftime("%d/%m/%Y %H:%M:%S"), :align=> :right

      pdf.font("PT Sans", :style => :italic ,:size => 12)
      # key

      models_info = Report.query(params[:query_type], params[:allocation_tags_ids], params[:groups])
      @options_array = Report.get_options_array
      
      pdf.font("PT Sans", :style => :italic ,:size => 10)

      if params[:query_type].to_i ==4
        header = [@options_array[9], @options_array[3], @options_array[4], @options_array[5], @options_array[6]]
      elsif params[:query_type].to_i ==6  
        header = [@options_array[9], @options_array[3], @options_array[4], @options_array[5]]
      else
         header = [@options_array[9], @options_array[3], @options_array[4]]
      end  
      table_data = []
      table_data << header
      
      index = 0
      models_info.each do |model|
        index = index +1
        if params[:query_type].to_i ==4
          table_data << [index ,model.name_model, model.total, model.total1, model.total2]
        elsif params[:query_type].to_i ==6 
          table_data << [index ,model.name_model, model.total, model.total1]
        else
          table_data << [index ,model.name_model, model.total]
        end  
      end
      if params[:query_type].to_i ==4
        pdf.table(table_data, :header => true, :column_widths => [25, 300, 70, 70, 70], :row_colors => ["EBE6DD", "FFFFFF"]) do |t|
          t.row(0).font_style = :bold
          t.row(0).background_color = 'EEE8AA' #AMARELO
        end
      elsif params[:query_type].to_i ==6
        pdf.table(table_data, :header => true, :column_widths => [25, 350, 80, 80], :row_colors => ["EBE6DD", "FFFFFF"]) do |t|
          t.row(0).font_style = :bold
          t.row(0).background_color = 'EEE8AA' #AMARELO
        end  
      else
        pdf.table(table_data, :header => true, :column_widths => [25, 425, 90], :row_colors => ["EBE6DD", "FFFFFF"]) do |t|
          t.row(0).font_style = :bold
          t.row(0).background_color = 'EEE8AA' #AMARELO
        end  
      end  
      # enumerando paginas
      string = t('reports.commun_texts.pages')
      options = { :at => [pdf.bounds.right - 150, 0],
                  :width => 150,
                  :align => :right,
                  :start_count_at => 1 }
      pdf.number_pages string, options

      # nome do documento
      send_data pdf.render, :filename => "report_"+time.strftime("%d-%m-%Y_%H-%M-%S")+".pdf", :type => "application/pdf", disposition: 'inline'

    end
 
  end
  # form
  private
    def semesters_params
      params.require(:reports).permit(:name,:id)
    end

  def set_document_title_final(index)
    case index
    when '1'
      $document_title = t('reports.index.report_summary_system.document_title')
    when '2'
      $document_title = t('reports.index.report_two.document_title')
    when '3'
      $document_title = t('reports.index.report_three.document_title')
    when '4'
      $document_title = t('reports.index.report_four.document_title')
    when '5'
      $document_title = t('reports.index.report_seven.document_title')
    when '6'
      $document_title = t('reports.index.report_six.document_title')  
    end
  end

end

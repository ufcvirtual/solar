class ReportsController < ApplicationController

  include ReportsHelper

  $document_title
  
  def index
    authorize! :index, Report
    @semesters = Semester.order('id ASC')
    @types = [ [t(:courses, scope: [:editions, :academic]), 'courses'],[t(:curriculum_units, scope: [:editions, :academic]), 'curriculum_units'], [t(:offers, scope: [:editions, :academic]), 'offers'], [t(:groups, scope: [:editions, :academic]), 'groups'] ]
    session.delete(:period_name)
    session.delete(:semester_id)
    session.delete(:type_report)
  end

  def create
    authorize! :index, Report
    if params['semesters'] 
      semesters = Semester.find(params['semesters'])
      session[:period_name] = semesters.name
      session[:semester_id] = semesters.id 
      session[:type_report] = params['type']
    end   
    render :layout => false
  end

  def render_reports
    authorize! :index, Report
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

      # period information
      pdf.move_down 30 # documento referente ao periodo tal......
      pdf.font("PT Sans", :style => :italic ,:size => 10)
      pdf.fill_color '000000'
      pdf.text t('reports.commun_texts.period_reference')+ ": #{session[:period_name]}", :align=> :right

      pdf.font("PT Sans", :style => :italic ,:size => 12)
      # key
      models_info = Report.query(params[:query_type], session[:semester_id], session[:type_report])
      @options_array = Report.get_options_array
      
      pdf.font("PT Sans", :style => :italic ,:size => 10)

      header = [@options_array[9], @options_array[3], @options_array[4]]
      table_data = []
      table_data << header
      
      index = 0
      models_info.each do |model|
        index = index +1
        table_data << [index ,model.name_model, model.total]
      end

      pdf.table(table_data, :header => true, :column_widths => [25, 425, 90], :row_colors => ["EBE6DD", "FFFFFF"]) do |t|
        t.row(0).font_style = :bold
        t.row(0).background_color = 'EEE8AA' #AMARELO
      end
      # enumerando paginas
      string = t('reports.commun_texts.pages')
      options = { :at => [pdf.bounds.right - 150, 0],
                  :width => 150,
                  :align => :right,
                  :start_count_at => 1 }
      pdf.number_pages string, options

      # nome do documento
      time = Time.now
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
      $document_title = t('reports.index.report_one.document_title')
    when '2'
      $document_title = t('reports.index.report_two.document_title')+t(session[:type_report], scope: [:editions, :academic])
    when '3'
      $document_title = t('reports.index.report_three.document_title')
    when '4'
      $document_title = t('reports.index.report_four.document_title')+t(session[:type_report], scope: [:editions, :academic])
    when '5'
      $document_title = t('reports.index.report_seven.document_title')+t(session[:type_report], scope: [:editions, :academic])
    end
  end

end

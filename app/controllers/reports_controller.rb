class ReportsController < ApplicationController

  include ReportsHelper

  $document_title
  $colors_used = {
    :black => "000000",
    :light_yellow => "EEE8AA",
    :gray => "EBE6DD",
    :blue_solar_theme => "003E7A"
  }
  def index
    @semesters = Semester.order('id ASC')
    @types = [ [t(:courses, scope: [:editions, :academic]), 'courses'],[t(:curriculum_units, scope: [:editions, :academic]), 'curriculum_units'], [t(:offers, scope: [:editions, :academic]), 'offers'], [t(:groups, scope: [:editions, :academic]), 'groups'] ]
    session.delete(:period_name)
    session.delete(:semester_id)
    session.delete(:type_report)
  end

  def create
    if params['semesters'] 
      semesters = Semester.find(params['semesters'])
      session[:period_name] = semesters.name
      session[:semester_id] = semesters.id 
      session[:type_report] = params['type']
    end   
    render :layout => false
  end

  def render_reports
      info = {  :Title => "Solar",
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
      pdf.fill_color $colors_used[:blue_solar_theme]
      pdf.text $document_title, :align => :center, :size => 14

      # period information
      pdf.move_down 30 # documento referente ao periodo tal......
      pdf.font("PT Sans", :style => :italic ,:size => 10)
      pdf.fill_color $colors_used[:black]
      pdf.text t('reports.commun_texts.period_reference')+ ": #{session[:period_name]}", :align=> :right

      pdf.font("PT Sans", :style => :italic ,:size => 12)

      # key
      models_info = ReportsHelper::query(params[:query_type], session[:semester_id], session[:type_report])

      # barra amarela
      pdf.fill_color $colors_used[:light_yellow]
      #pdf.fill_and_stroke_rectangle [0, 637.5], 540, 14.5       # para usar versão com linhas pretas em volta da barra amarela, descomentar essa linha
      pdf.fill_rectangle [0, 637.5], 540, 14.5                   # e comentar essa

      pdf.font("PT Sans", :style => :bold_italic ,:size => 11)
      pdf.fill_color $colors_used[:black]
      pdf.draw_text ReportsHelper::get_options_array[9], :at =>[10,pdf.cursor-12] #number simbol
      pdf.draw_text ReportsHelper::get_options_array[3], :at =>[31,pdf.cursor-12] #main info
      pdf.draw_text ReportsHelper::get_options_array[4], :at =>[445,pdf.cursor-12] #second column

      pdf.font("PT Sans", :style => :italic ,:size => 10)
      #if ReportsHelper::models_info.size > 0
        index = 0
        models_info.each do |model|
          index = index +1
          pdf.move_down 16 # posição...
          if( pdf.cursor < 60.000) # exeplo de margem
            pdf.start_new_page
            pdf.move_down 50
            pdf.font("PT Sans", :style => :bold_italic, :size => 9)
            pdf.draw_text ReportsHelper::get_timestamp_pattern, :at => [0,0]
          end
          pdf.float do
            pdf.font("PT Sans", :style => :italic ,:size => 10)
            pdf.bounding_box([0, pdf.cursor], :width => 540,:height => 16) do
            pdf.fill_color "EBE6DD"
            pdf.fill_rectangle [0,pdf.cursor], 540, 15
            pdf.fill_color "000000"
            pdf.move_down 12

            pdf.text_box " "+(index).to_s.rjust(3, "0")+"   "+
            "#{model.name_model }", :at =>[0, 12], :width => 450
            pdf.draw_text "#{ model.total }", :at =>[475,pdf.cursor]

            pdf.vertical_line pdf.cursor-4,pdf.cursor+12, :at => 29
            pdf.vertical_line pdf.cursor-4,pdf.cursor+12, :at => ReportsHelper::get_options_array[0]
            pdf.vertical_line pdf.cursor-4,pdf.cursor+12, :at => ReportsHelper::get_options_array[1]
            pdf.vertical_line pdf.cursor-4,pdf.cursor+12, :at => ReportsHelper::get_options_array[2]

            # pdf.stroke_bounds # documento com linhas pretas em volta de todos os dados? descomentar essa linha e ajustar a barra amarela acima.

            end
          end
        end
      #end
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

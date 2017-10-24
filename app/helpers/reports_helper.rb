require "prawn"
require "prawn/table"

module ReportsHelper

  def self.get_timestamp_pattern
    time = Time.now
      I18n.t('reports.commun_texts.timestamp_info')+" "+time.strftime(I18n.t('time.formats.long'))
  end

  def self.generate_pdf type, ats, user, curriculum_unit, is_student, grade, tool, access, access_count, public_files
    info = {
      :Title        => "Solar",
      :Author       => "UFC Virtual",
      :Subject      => "Solar system reports",
      :Keywords     => "reports",
      :Creator      => "ACME Soft App",
      :Producer     => "Prawn",
      :CreationDate => Time.now
    }

    pdf = Prawn::Document.new(info: info, page_size: "A4", page_layout: :landscape)

    # Cabeçalho
    pdf.text I18n.t('scores.pdf.time', time: I18n.l(Time.now, format: :long)), size: 7, align: :right
    pdf.move_down 3
    cursor = pdf.cursor
    pdf.image "#{Rails.root}/app/assets/images/ufc.png", width: 150, height: 50, position: :left
    pdf.image "#{Rails.root}/app/assets/images/ufcVirtual.png", width: 70, height: 50, at: [700, cursor]

    pdf.text ats.info, size: 14, style: :bold, align: :center
    pdf.move_down 10
    pdf.text  I18n.t(:report, scope: [:scores, :info]) + I18n.t(type, scope: [:scores, :info]), size: 12, align: :center

    pdf.image "#{Rails.root}/app/assets/images/#{user.user_photo(:medium)}", width: 120, height: 110, alt: I18n.t(:mysolar_alt_img_user)

    pdf.bounding_box([125, pdf.cursor + 100], width: 520, height: 110) do
      pdf.move_down 10
      pdf.text user.name, size: 12, style: :bold, align: :center
      pdf.text "(#{user.nick})", size: 12, style: :bold, align: :center
      pdf.move_down 10
      pdf.text strip_htlm_tags(curriculum_unit.try(:working_hours).nil? ? I18n.t('scores.info.uc_without_wh') : I18n.t('scores.info.frequency_uc', wh: curriculum_unit.try(:working_hours))), align: :center
      pdf.move_down 10
      if is_student
        unless grade.final_grade.blank?
          pdf.text strip_htlm_tags(I18n.t('scores.info.grade_i', grade: grade.final_grade.round(2).to_s)), align: :center
        end
        unless grade.working_hours.blank?
          pdf.text strip_htlm_tags(I18n.t('scores.info.frequency_i', wh: grade.working_hours)), align: :center
        end
      end
    end

    # Criação da primeira tabela
    unless tool.empty?
      table = line_itens pdf, type, tool
      style(pdf, table)
    else
      pdf.move_down 20
      pdf.text I18n.t(:itens_not_found)
    end

    # Cabeçalho da tabela de acessos
    pdf.move_down 40
    pdf.text I18n.t("scores.info.history_access", amount: access_count), size: 14, style: :bold
    pdf.move_down 20

    # Criação da tabela de acessos
    if access.any?
      table_acces = line_itens_acess(pdf, access)
      style(pdf, table_acces)
    else
      pdf.move_down 20
      pdf.text I18n.t("scores.access.no_access")
    end

    # Cabeçalho da tabela de arquivos públicos
    pdf.move_down 40
    pdf.text I18n.t(:public_files, scope: [:scores, :info]), size: 14, style: :bold
    pdf.move_down 20

    # Criação da tabela de arquivos públicos
    unless public_files.blank?
      table_public_files = line_itens_public_files(pdf, public_files)
      style(pdf, table_public_files)
    else
      pdf.move_down 20
      pdf.text I18n.t(:itens_not_found)
    end

    # Enumerando paginas
    string = I18n.t('reports.commun_texts.pages')
    options = { :at => [pdf.bounds.right - 150, 0],
                :width => 150,
                :align => :right,
                :start_count_at => 1 }

    pdf.number_pages string, options

    return pdf
  end

  private

    def self.line_itens(pdf, type, tool)
      # Cabeçalho da tabela
      thead = [I18n.t(:tool, scope: [:scores, :info]), I18n.t(:title, scope: [:scores, :info]), I18n.t(:date_range, scope: [:scores, :info]), I18n.t(:situation, scope: [:scores, :info]), I18n.t(:interactions, scope: [:scores, :info])]

      if type == 'evaluative' || type == 'all'
        thead << I18n.t(:grade, scope: [:scores, :info])
      end

      if type == 'frequency' || type == 'all'
        thead << I18n.t(:frequency, scope: [:scores, :info])
      end

      # Corpo da tabela
      tbody = tool.each.map do |item|
        if item.academic_tool_type.downcase == 'webconference'
          date = I18n.l(item.start_hour.to_datetime, format: :at_date)
        else
          date = [I18n.l(item.start_date.to_date), I18n.l(item.end_date.to_date)].join(' - ')
          date += "\n#{[(item.start_hour), (item.end_hour)].join(' - ')}" unless item.start_hour.blank?
        end

        situation = I18n.t(item.situation, :scope => [:scores, :situation]) unless item.situation.blank?
        count = item.count unless item.count.blank?
        grade = item.grade.blank? ? ' - ' : item.grade.to_f
        frequency = item.working_hours.blank? ? ' - ' : item.working_hours.to_i

        case type
        when 'not_evaluative'
          [I18n.t(item.academic_tool_type.downcase, scope: [:activerecord, :models]), item.name, date, situation, count]
        when 'evaluative'
          [I18n.t(item.academic_tool_type.downcase, scope: [:activerecord, :models]), item.name, date, situation, count, grade]
        when 'frequency'
          [I18n.t(item.academic_tool_type.downcase, scope: [:activerecord, :models]), item.name, date, situation, count, frequency]
        else
          [I18n.t(item.academic_tool_type.downcase, scope: [:activerecord, :models]), item.name, date, situation, count, grade, frequency]
        end
      end

      return [thead] + tbody
    end

    def self.line_itens_acess(pdf, access)
      pdf.text I18n.t('scores.info.last_five'), align: :right

      # Cabeçalho da tabela de acessos
      thead = [I18n.t("posts.user_posts.date"), I18n.t("posts.user_posts.time")]

      # Corpo da tabela de acessos
      tbody = access.each.map do |item|
        [I18n.l(item.created_at.to_datetime, format: :normal), I18n.l(item.created_at.to_datetime, format: :clock_time)]
      end

      return [thead] + tbody
    end

    def self.line_itens_public_files(pdf, public_files)
      # Cabeçalho da tabela
      thead = [I18n.t(:file, scope: [:scores, :info]), I18n.t(:size, scope: [:scores, :info]), I18n.t(:sent_on, scope: [:scores, :info])]

      # Corpo da tabela
      tbody = public_files.each.map do |file|
        [file.attachment_file_name, format('%.2f KB', file.attachment_file_size.to_i/1024.0), (file.attachment_updated_at.nil? ? " " : I18n.l(file.attachment_updated_at, format: :files))]
      end

      return [thead] + tbody
    end

    def self.style(pdf, table)
      pdf.table table, position: :center, width: 770 do |t|
        t.header = true
        t.row(0).font_style = :bold
        t.row(0).background_color = 'FFEFDB'
        t.row_colors = ['D3D3D3', 'FFFFFF']
        t.columns(0..7).align = :center
        t.column(3).style do |cell|
          # As cores usadas abaixo foram tiradas do arquivo pdf.css.scss
          cell.text_color = '666666' if cell.content == I18n.t('scores.situation.not_started')
          cell.text_color = '003E7A' if cell.content == I18n.t('scores.situation.to_answer')
          cell.text_color = '003E7A' if cell.content == I18n.t('scores.situation.not_finished')
          cell.text_color = '2900C2' if cell.content == I18n.t('scores.situation.finished')
          cell.text_color = '2D7035' if cell.content == I18n.t('scores.situation.corrected')
          cell.text_color = '0B610B' if cell.content == I18n.t('scores.situation.evaluated')
          cell.text_color = 'E03838' if cell.content == I18n.t('scores.situation.not_corrected')
          cell.text_color = 'CC0033' if cell.content == I18n.t('scores.situation.not_answered')
          cell.text_color = '003E7A' if cell.content == I18n.t('scores.situation.retake')
          cell.text_color = '666666' if cell.content == I18n.t('scores.situation.message_did_not_start')
          cell.text_color = 'E12227' if cell.content == I18n.t('scores.situation.closed')
          cell.text_color = '003E7A' if cell.content == I18n.t('scores.situation.started')
          cell.text_color = '2900C2' if cell.content == I18n.t('scores.situation.sent')
          cell.text_color = 'E12227' if cell.content == I18n.t('scores.situation.not_sent')
          cell.text_color = '003E7A' if cell.content == I18n.t('scores.situation.to_be_sent')
          cell.text_color = 'B15759' if cell.content == I18n.t('scores.situation.without_group')
          cell.text_color = '006666' if cell.content == I18n.t('scores.situation.opened')
        end
      end
    end

    def self.strip_htlm_tags(string)
      ActionView::Base.full_sanitizer.sanitize(string)
    end

end

require "prawn"
require "prawn/table"
require "nokogiri"

module ReportsHelper

  def self.get_timestamp_pattern
    time = Time.now
      I18n.t('reports.commun_texts.timestamp_info')+" "+time.strftime(I18n.t('time.formats.long'))
  end

  def self.generate_pdf type, ats, user, curriculum_unit, is_student, grade, tool, access, access_count, public_files
    pdf = inicializa_pdf(:landscape)

    # Logo da UFC e data de geração do pdf
    pdf.text I18n.t('scores.pdf.time', time: I18n.l(Time.now, format: :long)), size: 7, align: :right
    pdf.move_down 3
    cursor = pdf.cursor
    pdf.image "#{Rails.root}/app/assets/images/ufc.png", width: 150, height: 50, position: :left
    pdf.image "#{Rails.root}/app/assets/images/ufcVirtual.png", width: 70, height: 50, at: [700, cursor]

    # Título do pdf
    pdf.text ats.info, size: 14, style: :bold, align: :center
    pdf.move_down 10
    pdf.text  I18n.t(:report, scope: [:scores, :info]) + I18n.t(type, scope: [:scores, :info]), size: 12, align: :center

    pdf.image "#{Rails.root}/app/assets/images/#{user.user_photo(:medium)}", width: 120, height: 110, alt: I18n.t(:mysolar_alt_img_user)

    pdf.bounding_box([125, pdf.cursor + 100], width: 520, height: 110) do
      pdf.move_down 5
      pdf.text user.name, size: 12, style: :bold, align: :center
      pdf.text "(#{user.nick})", size: 12, style: :bold, align: :center
      pdf.move_down 5
      pdf.text strip_htlm_tags(curriculum_unit.try(:working_hours).nil? ? I18n.t('scores.info.uc_without_wh') : I18n.t('scores.info.frequency_uc', wh: curriculum_unit.try(:working_hours))), align: :center
      if is_student
        pdf.text strip_htlm_tags(I18n.t('scores.info.final_exam_grade', grade: (grade.final_exam_grade.blank? ? ' - ' : grade.final_exam_grade))), align: :center
        unless grade.final_grade.blank?
          pdf.text strip_htlm_tags(I18n.t('scores.info.grade_i', grade: grade.final_grade.round(2).to_s)), align: :center
        end
        pdf.text strip_htlm_tags(I18n.t('scores.info.frequency_i', wh: (grade.working_hours.blank? ? 0 : grade.working_hours))), align: :center
        unless grade.grade_situation.blank?
          pdf.text strip_htlm_tags(I18n.t('scores.info.situation2', situation: I18n.t("scores.index.#{Allocation.status_name(grade.grade_situation)}"))), align: :center
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
    page_enumeration(pdf)

    return pdf
  end

  def self.result_exam(ats, exam, user, grade_pdf, exam_questions, preview, last_attempt, disabled)
    pdf = inicializa_pdf(:portrait)

    # Logo da UFC e data de geração do pdf
    pdf.text I18n.t('scores.pdf.time', time: I18n.l(Time.now, format: :long)), size: 7, align: :right
    pdf.move_down 3
    cursor = pdf.cursor
    pdf.image "#{Rails.root}/app/assets/images/ufc.png", width: 120, height: 50, position: :left
    pdf.image "#{Rails.root}/app/assets/images/ufcVirtual.png", width: 70, height: 50, at: [460, cursor]
    pdf.move_down 10

    # Título do pdf
    pdf.text ats.info, size: 14, style: :bold, align: :center
    pdf.move_down 10
    pdf.text  I18n.t(:report, scope: [:scores, :info]) + I18n.t('exams.result_exam.title_pdf', name: exam.name), size: 12, align: :center

    pdf.image "#{Rails.root}/app/assets/images/#{user.user_photo(:medium)}", width: 110, height: 100, alt: I18n.t(:mysolar_alt_img_user)

    pdf.bounding_box([125, pdf.cursor + 100], width: 290, height: 100) do
      pdf.move_down 10
      pdf.text user.name, size: 12, style: :bold, align: :center
      pdf.text "(#{user.nick})", size: 12, style: :bold, align: :center
      pdf.move_down 10
      pdf.text strip_htlm_tags(I18n.t('scores.info.grade_i', grade: (grade_pdf.blank? ? ' - ' : grade_pdf.to_s))), align: :center
      # pdf.transparent(0.5) { pdf.stroke_bounds }
    end
    pdf.move_down 20

    # Corpo da prova
    number_question = 0

    exam_questions.each_with_index do |question, idx|
      exam_responses = last_attempt.exam_responses.where(question_id: question.id).first
      number_question = number_question + 1

      score = I18n.t('exams.open.scores', score: question.score) if disabled || preview
      anull = I18n.t('exams.open.anull') if question.annulled
      text = QuestionText.find(question.question_text_id).text unless question.question_text_id.nil?

      # Texto associado a questão
      unless question.question_text_id.nil?
        pdf.text strip_htlm_tags((Nokogiri::HTML(text)).inner_html), align: :center
        pdf.move_down 10
      end

      # Enunciado da questão
      question_text = strip_htlm_tags((Nokogiri::HTML([question.enunciation, anull, score].compact.join(' '))).inner_html)
      pdf.text "#{number_question}) #{question_text}", align: :justify
      pdf.move_down 10

      # Enunciado com imagem
      question_images = QuestionImage.list(question.id)
      render_images(pdf, question_images)

      disabled = disabled || question.annulled

      number_question_response = -1
      arr_alf = ('A'..'Z').to_a
      arra_correted, arra_correted2, arra_marked, arra_marked2 = [], [], [], []

      responses = question.question_items.joins(:exam_responses_question_items).where(exam_responses_question_items: {:'exam_response_id' => exam_responses.id}).select("question_items.id, question_items.description, question_items.item_image_file_name AS image_name, question_items.value AS correct_value, exam_responses_question_items.value AS marked_value, question_items.comment")

      responses.each do |item|
        number_question_response += 1

        arra_marked << arr_alf[number_question_response] if item.marked_value == "t"
        arra_marked2 << arr_alf[number_question_response] if item.marked_value == "f"
        arra_correted << arr_alf[number_question_response] if item.correct_value == "t"
        arra_correted2 << arr_alf[number_question_response] if item.correct_value == "f"
        image_name = "#{item.id}_#{item.image_name}" unless item.image_name.blank?

        if item.marked_value == item.correct_value
          if question.type_question.to_i == Question::UNIQUE
            bullet(pdf, item.marked_value, image_name, "#{arr_alf[number_question_response]}) (#{I18n.t('exams.selected_correctly')}) #{item.description}", "0B610B")
          elsif question.type_question.to_i == Question::MULTIPLE
            checkbox(pdf, image_name, "#{arr_alf[number_question_response]}) (#{I18n.t('exams.selected_correctly')}) #{item.description}", item.marked_value, "0B610B")
          else
            selected_correctly = I18n.t('exams.result_exam_user.true_item') if item.marked_value == "t"
            selected_correctly = I18n.t('exams.result_exam_user.false_item') if item.marked_value == "f"
            dropdown(pdf, item.marked_value, image_name, "#{arr_alf[number_question_response]}) (#{I18n.t('exams.selected_correctly')}) (#{selected_correctly}) #{item.description}", "0B610B")
          end
        else
          if (item.correct_value == "f" && item.marked_value == "t")
            if question.type_question.to_i == Question::UNIQUE
              bullet(pdf, item.marked_value, image_name, "#{arr_alf[number_question_response]}) (#{I18n.t('exams.selected_incorrectly')}) #{item.description}", "E03838")
            elsif question.type_question.to_i == Question::MULTIPLE
              checkbox(pdf, image_name, "#{arr_alf[number_question_response]}) (#{I18n.t('exams.selected_incorrectly')}) #{item.description}", item.marked_value, "E03838")
            else
              dropdown(pdf, item.marked_value, image_name, "#{arr_alf[number_question_response]}) (#{I18n.t('exams.selected_incorrectly')}) (#{I18n.t('exams.result_exam_user.false_item')}) #{item.description}", "E03838")
            end
          elsif item.correct_value == "t" && item.marked_value != "t"
            if question.type_question.to_i == Question::UNIQUE
              bullet(pdf, item.marked_value, image_name, "#{arr_alf[number_question_response]}) (#{I18n.t('exams.correct_item')}) #{item.description}", "E03838")
            elsif question.type_question.to_i == Question::MULTIPLE
              checkbox(pdf, image_name, "#{arr_alf[number_question_response]}) (#{I18n.t('exams.correct_item')}) #{item.description}", item.marked_value, "E03838")
            else
              dropdown(pdf, item.marked_value, image_name, "#{arr_alf[number_question_response]}) (#{I18n.t('exams.selected_incorrectly')}) (#{I18n.t('exams.result_exam_user.true_item')}) #{item.description}", "E03838")
            end
          else
            if question.type_question.to_i == Question::UNIQUE
              bullet(pdf, item.marked_value, image_name, "#{arr_alf[number_question_response]}) #{item.description}", "2900C2")
            elsif question.type_question.to_i == Question::MULTIPLE
              checkbox(pdf, image_name, "#{arr_alf[number_question_response]}) #{item.description}", item.marked_value, "2900C2")
            else
              selected_correctly = I18n.t('exams.result_exam_user.true_item') if item.correct_value == "t"
              selected_correctly = I18n.t('exams.result_exam_user.false_item') if item.correct_value == "f"
              dropdown(pdf, item.marked_value, image_name, "#{arr_alf[number_question_response]}) (#{I18n.t('exams.selected_incorrectly')}) (#{selected_correctly}) #{item.description}", "E03838")
            end
          end
        end

        pdf.move_down 5
        pdf.text "#{item.comment}" unless item.comment.blank?
        pdf.move_down 10
      end

      if question.type_question.to_i == Question::UNIQUE || question.type_question.to_i == Question::MULTIPLE
        pdf.text I18n.t('exams.result_exam_user.itens_marked') + arra_marked.join(", ")
        pdf.text I18n.t('exams.result_exam_user.itens_corrected') + arra_correted.join(", ")
      end

      if question.type_question.to_i != Question::UNIQUE && question.type_question.to_i != Question::MULTIPLE
        pdf.text I18n.t('exams.result_exam_user.itens_marked')
        pdf.text I18n.t('exams.result_exam_user.true_items') + arra_marked.join(", ")
        pdf.text I18n.t('exams.result_exam_user.false_items') + arra_marked2.join(", ")

        pdf.move_down 10

        pdf.text I18n.t('exams.result_exam_user.itens_corrected')
        pdf.text I18n.t('exams.result_exam_user.true_items') + arra_correted.join(", ")
        pdf.text I18n.t('exams.result_exam_user.false_items') + arra_correted2.join(", ")
      end

      pdf.move_down 10
    end

    # Enumerando paginas
    page_enumeration(pdf)

    return pdf
  end

  private
    def self.inicializa_pdf(orientation)
      info = {
        :Title        => "Solar",
        :Author       => "UFC Virtual",
        :Subject      => "Solar system reports",
        :Keywords     => "reports",
        :Creator      => "ACME Soft App",
        :Producer     => "Prawn",
        :CreationDate => Time.now
      }

      Prawn::Font::AFM.hide_m17n_warning = true

      Prawn::Document.new(info: info, page_size: "A4", page_layout: orientation) do |pdf|
        pdf.font_families.update("Ubuntu Condensed" => {
          :normal => "#{Rails.root}/app/assets/stylesheets/fonts/ubuntucondensed-regular-webfont.ttf",
          })

        pdf.font_families.update("PT Sans" => {
          :normal => "#{Rails.root}/app/assets/stylesheets/fonts/pt_sans-web-regular-webfont.ttf",
          :bold => "#{Rails.root}/app/assets/stylesheets/fonts/pt_sans-web-bold-webfont.ttf",
          :italic => "#{Rails.root}/app/assets/stylesheets/fonts/pt_sans-web-italic-webfont.ttf",
          :bold_italic => "#{Rails.root}/app/assets/stylesheets/fonts/pt_sans-web-bolditalic-webfont.ttf",
          })

        pdf.font "PT Sans", :style => :normal
      end
    end

    def self.strip_htlm_tags(string)
      ActionView::Base.full_sanitizer.sanitize(string)
    end

    def self.page_enumeration(pdf)
      string = I18n.t('reports.commun_texts.pages')
      options = { :at => [pdf.bounds.right - 150, 0],
                  :width => 150,
                  :align => :right,
                  :start_count_at => 1 }

      pdf.number_pages string, options
    end

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

    def self.bullet(pdf, marked_value, image, text, color = "000000")
      pdf.image "#{Rails.root}/app/assets/images/bullet.png", width: 12, height: 12, at: [0, pdf.cursor]
      pdf.bounding_box([0, pdf.cursor], width: 10, height: 12) do
        value = marked_value ? "•" : " "
        pdf.text(value, align: :center, valign: :center)
      end
      pdf.move_up 12
      pdf.span(500, position: :right) do
        pdf.text strip_htlm_tags(text), align: :justify, color: color
      end
      pdf.move_down 5
      pdf.image "#{Rails.root}/media/questions/items/#{image}" unless image.blank?
    end

    EMPTY_CHECKBOX   = "\u2610" # "☐"
    CHECKED_CHECKBOX = "\u2611" # "☑"
    EXED_CHECKBOX    = "\u2612" # "☒"
    CHECKBOX_FONT    = "#{Rails.root}/app/assets/stylesheets/fonts/DejaVuSans.ttf"

    def self.checkbox(pdf, image, label, checked, color = "000000")
      pdf.font "#{CHECKBOX_FONT}" do
        pdf.text strip_htlm_tags((checked ? "#{CHECKED_CHECKBOX} #{label}" : "#{EMPTY_CHECKBOX} #{label}")), color: color
      end
      pdf.move_down 5
      pdf.image "#{Rails.root}/media/questions/items/#{image}" unless image.blank?
    end

    def self.dropdown(pdf, marked_value, image, text, color = "000000")
      pdf.image "#{Rails.root}/app/assets/images/box.png", width: 20, height: 12, at: [0, pdf.cursor]
      pdf.bounding_box([0, pdf.cursor], width: 10, height: 12) do
        if marked_value == nil
          value = ""
        else
          value = marked_value == "t" ? I18n.t('questions.form.t_option') : I18n.t('questions.form.f_option')
        end
        pdf.text(value, align: :center, valign: :center)
      end
      pdf.move_up 12
      pdf.span(500, position: :right) do
        pdf.text strip_htlm_tags(text), align: :justify, color: color
      end
      pdf.move_down 5
      pdf.image "#{Rails.root}/media/questions/items/#{image}" unless image.blank?
    end

    def self.render_images(pdf, images)
      Timeout::timeout(10) do
        images.each do |q_image|
          pdf.image "#{Rails.root}/media/questions/images/#{q_image.id}_#{q_image.image_file_name}", alt: q_image.img_alt unless q_image.image_file_name.blank?
          pdf.move_down 10
          pdf.text q_image.legend, align: :center unless q_image.legend.blank?
          pdf.move_down 10
        end
      end
    rescue
      false
    end

end

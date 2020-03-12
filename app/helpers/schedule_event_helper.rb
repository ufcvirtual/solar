module ScheduleEventHelper

  def get_deficiency(deficiency_code)
    case deficiency_code
      when 1
        I18n.t("deficiency.autism")
      when 2
        I18n.t("deficiency.low_vision")
      when 3
        I18n.t("deficiency.blindness")
      when 4
        I18n.t("deficiency.hearing_deficiency")
      when 5
        I18n.t("deficiency.physical_disability")
      when 6
        I18n.t("deficiency.intellectual_deficiency")
      when 7
        I18n.t("deficiency.multiple_disability")
      when 8
        I18n.t("deficiency.deafness")
      when 9
        I18n.t("deficiency.deafblindness")
      when 10
        I18n.t("deficiency.aspergers_syndrome")
      when 11
        I18n.t("deficiency.rett_syndrome")
      when 12
        I18n.t("deficiency.childhood_disintegrative_disorder")
      when 13
        I18n.t("deficiency.other")
      else
        ""
    end
  end

  def get_deficiency_class_css(deficiency_code)
    case deficiency_code
      when 1
        "autism"
      when 2
        "low_vision"
      when 3
        "blindness"
      when 4
        "hearing_deficiency"
      when 5
        "physical_disability"
      when 6
        "intellectual_deficiency"
      when 7
        "multiple_disability"
      when 8
        "deafness"
      when 9
        "deafblindness"
      when 10
        "aspergers_syndrome"
      when 11
        "rett_syndrome"
      when 12
        "childhood_disintegrative_disorder"
      when 13
        "other"
      else
        nil
    end
  end

  def pictures_with_abs_path(html)
    if !html.blank? && (html.include?("href") || html.include?("src"))
      html.gsub!(/(href|src)=(['"])\/([^\"']*|[^"']*)['"]/i, '\1=\2' + "#{Rails.root}/" + '\3\2')
    end
    html
  end

end
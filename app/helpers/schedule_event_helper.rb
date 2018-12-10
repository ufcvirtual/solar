module ScheduleEventHelper

  def get_deficiency(deficiency)
    case deficiency
      when "Autismo"
        I18n.t("deficiency.autism")
      when "Baixa visão"
        I18n.t("deficiency.low_vision")
      when "Cegueira"
        I18n.t("deficiency.blindness")
      when "Deficiência auditiva"
        I18n.t("deficiency.hearing_deficiency")
      when "Deficiência física"
        I18n.t("deficiency.physical_disability")
      when "Deficiência intelectual"
        I18n.t("deficiency.intellectual_deficiency")
      when "Deficiência múltipla"
        I18n.t("deficiency.multiple_disability")
      when "Surdez"
        I18n.t("deficiency.deafness")
      when "Surdocegueira"
        I18n.t("deficiency.deafblindness")
      when "Síndrome de Asperger"
        I18n.t("deficiency.aspergers_syndrome")
      when "Síndrome de Rett"
        I18n.t("deficiency.rett_syndrome")
      when "Transtorno desintegrativo de infância"
        I18n.t("deficiency.childhood_disintegrative_disorder")
      when "Outra"
        I18n.t("deficiency.other")
      else
        ""
    end
  end

  def get_deficiency_class_css(deficiency)
    case deficiency
      when "Autismo"
        "autism"
      when "Baixa visão"
        "low_vision"
      when "Cegueira"
        "blindness"
      when "Deficiência auditiva"
        "hearing_deficiency"
      when "Deficiência física"
        "physical_disability"
      when "Deficiência intelectual"
        "intellectual_deficiency"
      when "Deficiência múltipla"
        "multiple_disability"
      when "Surdez"
        "deafness"
      when "Surdocegueira"
        "deafblindness"
      when "Síndrome de Asperger"
        "aspergers_syndrome"
      when "Síndrome de Rett"
        "rett_syndrome"
      when "Transtorno desintegrativo de infância"
        "childhood_disintegrative_disorder"
      when "Outra"
        "other"
      else
        nil
    end
  end

end
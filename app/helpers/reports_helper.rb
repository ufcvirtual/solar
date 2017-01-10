module ReportsHelper

  def self.get_timestamp_pattern
    time = Time.now
      I18n.t('reports.commun_texts.timestamp_info')+" "+time.strftime(I18n.t('time.formats.long'))
  end


end

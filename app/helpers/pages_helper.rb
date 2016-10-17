module PagesHelper
  def get_file(locale, name, title)
    unless File.exist? File.expand_path File.join("#{Rails.root}", 'public', "/tutorials/#{name}_#{locale}.pdf")
      if File.exist? File.expand_path File.join("#{Rails.root}", 'public', "/tutorials/#{name}_en_US.pdf")
        locale = 'en_US'
        text =  t('tutorials.new_language_en')
      else
        locale = 'pt_BR'
        text =  t('tutorials.new_language_pt')
      end
    else
      text = ''
    end

    %{
      <a href="/tutorials/#{name}_#{locale}.pdf", target="_blank">#{title}</a> 
      <div class='subtitle_tutorial'> #{text} </div>
    }
  end
end
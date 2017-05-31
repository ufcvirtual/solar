module PagesHelper
  def get_file(locale, name, title)
    file = File.expand_path File.join("#{Rails.root}", 'public', "/tutorials/#{name}_#{locale}.pdf")
    unless File.exist? file
      file = File.expand_path File.join("#{Rails.root}", 'public', "/tutorials/#{name}_en_US.pdf")
      if File.exist? file
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
      <a href="/tutorials/#{name}_#{locale}.pdf", target="_blank">#{title} (#{format('%.2f MB', File.size(file)/1024.0/1024.0)})</a> 
      <div class='subtitle_tutorial'> #{text} </div>
    }
  end
end
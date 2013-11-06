Solar::Application.config.black_list = {:mime_types => [
    'application/x-asp',
    'magnus-internal/cgi', # cgi, exe, bat
    'application/exe',
    'application/x-msdownload',
    'application/x-exe',
    'application/dos-exe',
    'application/x-msdos-program', # exe-DOS/Windowns
    'vms/exe',
    'application/x-winexe',
    'application/msdos-windows',
    'application/bin',
    'application/binary',
    'application/x-msdownload',
    'application/x-php',
    'text/x-java',
    'application/x-java' # class
  ], :extensions => [
    'jsp',
    'exe',
    'msi',
    'php'
  ]
}

ActiveRecord::Base.class_eval do
  # Verifica se o content type do arquivo em questao se encontra na blacklist
  # caso se encontre, sera lancado um erro
  def self.validates_attachment_content_type_in_black_list name, options = {}
    validation_options = options.dup
    # se a lista nao for passada por parametro, é recuperada do ambiente
    list = validation_options[:blacklist] || Solar::Application.config.black_list

    rejected_types = [list].flatten # transforma em um array simples

    # verificar se eh apenas um array ou se possui as opcoes de mimetype e extensions
    rjd_mime_types = []
    rjd_mime_types = rejected_types unless rejected_types.first.is_a?(Hash)
    rjd_mime_types = rejected_types.first[:mime_types] if rejected_types.first.is_a?(Hash) && rejected_types.first.include?(:mime_types)

    rjd_extensions = []
    rjd_extensions = rejected_types.first[:extensions] if rejected_types.first.is_a?(Hash) && rejected_types.first.include?(:extensions)

    # verifica o mime-type antes
    validates_each(:"#{name}_content_type", validation_options) do |record, attr, value|

      file_name_extension = nil
      # verificando a extensao do arquivo
      unless rjd_extensions.nil?
        file_name = nil
        file_name = record.attributes["#{name}_file_name"] if record.attribute_present?("#{name}_file_name")
        file_name_extension = file_name.to_s.split('.').last
      end

      if rjd_mime_types.include?(value) || rjd_extensions.include?(file_name_extension)
        message = options[:message] || :invalid_type
        record.errors.add(:"#{name}_content_type", message)
      end
    end

  end

end


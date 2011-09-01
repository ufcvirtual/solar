module ActiveRecord
  module Validations
    module ClassMethods

      # Verifica se o content type do arquivo em questao se encontra na blacklist
      # caso se encontre, sera lancado um erro
      def validates_attachment_content_type_in_black_list name, options = {}
        validation_options = options.dup
        list = validation_options[:blacklist] || Solar::Application.config.black_list # se a lista nao for passada por parametro, é recuperada do ambiente
        rejected_types = [list].flatten # transforma em um array simples
        validates_each(:"#{name}_content_type", validation_options) do |record, attr, value|
          if rejected_types.include?(value)
            message = options[:message] || :invalid_type
            record.errors.add(:"#{name}_content_type", message)
          end
        end
      end

    end
  end
end
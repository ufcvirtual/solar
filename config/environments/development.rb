Solar::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false



  # Para poder usar o "descendants" em desenvolvimento:
  # Conforme em http://avinmathew.com/using-rails-descendants-method-in-development,
  # O "cache_classes = false" definido em desenvolvimento, faz com que a aplicação 
  # não carregue as classes até que elas sejam referenciadas. Com isso, o método
  # "descendants" pode não retornar todas as classes esperadas. Com as linhas abaixo,
  # todas as classes são carregadas assim que a aplicação é iniciada e, em seguida,
  # as classes são "requeridas" pela aplicação em cada requisição
  config.eager_load_paths += Dir['app/models/*.rb']
  ActionDispatch::Reloader.to_prepare do
    Dir['app/models/*.rb'].each {|file| require_dependency file}
  end

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  # config.action_view.debug_rjs             = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = true

  # Not logging any DEBUG message
  config.log_level = :info

  # Mostra log do activerecord
  # config.active_record.logger = Logger.new(STDOUT)

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Desabilitando compressão de assets
  config.assets.enabled = true
  config.assets.compress = false

  # Habilitando debug_info do SASS, permitindo uma análise mais fácil através do FireSASS
  config.sass.line_comments = false
  config.sass.cache = false
  config.sass.debug_info = true

end

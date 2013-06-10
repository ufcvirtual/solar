require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
# Bundler.require(:default, Rails.env) if defined?(Bundler)

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module Solar
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    #Tags e atributos permitidos pelo método auxiliador "sanitize"
    config.action_view.sanitized_allowed_tags = %w(h1 h2 h3 h4 hr b i p u a pre div span br ul ol li em strong strike img sup sub abbr big small code)
    config.action_view.sanitized_allowed_attributes = %w(name style class href cite title src height datetime alt abbr width)

    config.active_record.observers = :user_observer, :tag_observer
    config.active_record.default_timezone = :local

    #Itens por página para a paginação.
    config.items_per_page = 30

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.

    #config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]

    #definindo locales#
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]
    config.i18n.default_locale = "pt-BR"
    config.time_zone = 'Buenos Aires' # Estamos utilizando 'Buenos Aires' para evitar problemas com horário de verão.

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable the asset pipeline
    config.assets.enabled = true
    config.assets.compress = true
    config.assets.precompile += %w( *.js *.css )

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    # layout
    config.to_prepare do
      Devise::SessionsController.layout "login"
      Devise::RegistrationsController.layout proc{ |controller| user_signed_in? ? "application" : "login" }
      Devise::ConfirmationsController.layout "login"
      Devise::UnlocksController.layout "login"
      Devise::PasswordsController.layout "login"
    end

    #config.action_controller.allow_forgery_protection = false
    #config.gem "koala"
  end
end

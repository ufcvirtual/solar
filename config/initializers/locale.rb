
I18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]
I18n.default_locale = "pt_BR"

Date::DATE_FORMATS[:default] = I18n.t('date.formats.default')

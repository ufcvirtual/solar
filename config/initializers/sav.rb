module SavConfig
  CONFIG = YAML.load_file(Rails.root.join("config","sav.yml"))[Rails.env] rescue nil
  unless CONFIG.nil?
    IV     = CONFIG['IV']
    KEY    = CONFIG['key']
    WSDL   = CONFIG['wsdl']
    METHOD = CONFIG['method']
  end
end
module SavConfig
  CONFIG = ENV['SAV_CONFIG_ENABLE'] rescue nil
  unless CONFIG.nil?
    IV     = ENV['SAV_IV']
    KEY    = ENV['SAV_KEY']
    WSDL   = ENV['SAV_WSDL']
    METHOD = ENV['SAV_METHOD']
  end
end
Rails.application.configure do
    config.lograge.enabled = true
    config.lograge.formatter = Lograge::Formatters::KeyValue.new
end
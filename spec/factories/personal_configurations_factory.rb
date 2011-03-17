Factory.define :personal_configuration do |personal_configurations|
  include ActionDispatch::TestProcess
  personal_configurations.default_locale "pt-BR"
  personal_configurations.mysolar_portlets "1&4|3|5&2"
  personal_configurations.user_id	1
end
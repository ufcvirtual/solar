Rabl.configure do |config|
  config.include_json_root = false
  config.include_child_root = false
  config.view_paths = "#{::Rails.root}/app/api/templates/"
end

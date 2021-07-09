# config/initializers/assets.rb
# Be sure to restart your server when you modify this file.
assets = Rails.application.config.assets
# Enable the asset pipeline
assets.enabled = true
#assets.quiet = true
assets.compress = true
#config.assets.precompile << /(^[^_\/]|\/[^_])[^\/]*$/
#config.assets.precompile += ['ckeditor/*']
#config.assets.check_precompiled_asset = false
# Version of your assets, change this if you want to expire all your assets
assets.version = '1.0'

#assets.unknown_asset_fallback = false
#config.assets.precompile += %w(creative/manifest.js creative/manifest.css images/* fonts/* stylesheets/* javascripts/*)
assets.paths << Rails.root.join("app", "assets", "fonts")

#assets.configure do |env|
#  env.context_class.class_eval do
#    include AppsHelper
#  end
#end
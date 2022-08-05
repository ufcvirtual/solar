# Be sure to restart your server when you modify this file.

#original:
#Solar::Application.config.session_store :cookie_store, :key => '_solar_session'

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")

#mudando armazenamento de sessao para o banco
#Solar::Application.config.session_store :active_record_store

#mudando armazenamento de sessao para o banco nosql(redis)
Rails.application.config.session_store :cookie_store, key: '_solar_session'
Solar::Application.config.session_store :redis_store, servers: "#{ENV['DB_URL_REDIS']}", expire_after: "#{ENV['DAYS_TO_EXPIRE']}".to_i.days, key: '_solar_session', httponly: true

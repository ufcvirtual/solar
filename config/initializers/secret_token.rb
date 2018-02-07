# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.

Solar::Application.config.secret_token = ENV["SOLAR_SECRET_KEY_BASE"]
Solar::Application.config.secret_key_base =  "07cc9ec4cb6392e9a863a41bbe5359cdea5754f10e3e45d0a2aa912cc7b0b0b4dfc098054b034377dbbd39a3970ad828246e5c07f400d04822652193b7a58c78"


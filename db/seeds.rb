# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

# pre-requisito para executar os outros arquivos de seeds
require File.join(Rails.root.to_s, 'db', 'production.rb') if Rails.env == 'production'
require File.join(Rails.root.to_s, 'db', 'development.rb') if Rails.env == 'development'

require 'rubygems'
require 'hpricot'
require 'yaml'
require 'active_record'
DATABASE_ENV = ENV['DATABASE_ENV'] || 'development'

dbconfig = YAML.load_file('config/database.yml')[DATABASE_ENV]
ActiveRecord::Base.establish_connection(dbconfig)

Dir["./models/*.rb"].each {|file| require file }
Dir["./*.rb"].each {|file| require file }

# Run the Script
Script.start

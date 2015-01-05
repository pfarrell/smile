require 'sequel'
require 'logger'

#$console = Logger.new STDOUT
DB = Sequel.connect(ENV['DATABASE_URL'] || 'postgres://localhost/droppings',logger: nil)

DB.sql_log_level = :info
DB.extension(:pagination)

Sequel::Model.plugin :timestamps
Sequel::Model.plugin :json_serializer

require 'models/message'
require 'models/error'
require 'models/timing'
require 'models/elastic_search'

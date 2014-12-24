require 'sequel'
require 'logger'

$console = Logger.new STDOUT
DB = Sequel.connect(ENV['DATABASE_URL'] || 'postgres://localhost/droppings',logger: $console)

DB.sql_log_level = :debug
Sequel::Model.plugin :timestamps
Sequel::Model.plugin :json_serializer

require 'models/entry'
require 'models/error'

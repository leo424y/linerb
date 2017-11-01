require './app'
run Sinatra::Application

$stdout.sync = true
config.logger = Logger.new(STDOUT)

require 'sinatra'   # gem 'sinatra'
require 'line/bot'  # gem 'line-bot-api'
require "sinatra/activerecord"
require './config/environments'
require 'nokogiri'
require 'open-uri'
require 'json'
require 'bitly'
require 'date'
require 'erb'
require 'csv'
require 'wikipedia'

Dir["./lib/*.rb"].each {|file| require file }

get '/x/:yy' do download_csv end
get '/n/:yy' do display_info end
get '/s/:yy' do render_html end

post '/callback' do
  events = client.parse_events_from(request.body.read)
  events.each { |event|
    user_id = event['source']['userId']
    group_id = event['source']['groupId'] || event['source']['roomId']

    handle_event event, user_id, group_id
  }
  'OK'
end

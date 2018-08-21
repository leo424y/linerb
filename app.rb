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
require './model.rb'
require './view.rb'
require './constant.rb'
require './helper.rb'
require './handle_location.rb'
require './handle_message.rb'
require './reply.rb'

get '/x/:yy' do download_csv end
get '/n/:yy' do display_name end
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

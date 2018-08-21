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
    is_vip = Vip.find_by(user_id: user_id)
    group_id = event['source']['groupId'] || event['source']['roomId']

    case event
    when Line::Bot::Event::Join
      Group.create(group_id: group_id, status: 'join')
      reply_text(event, IO.readlines("data/join").map(&:chomp))

    when Line::Bot::Event::Leave
      Group.find_by(group_id: group_id).update(status: 'leave')

    when Line::Bot::Event::Postback
      data = event['postback']['data']
      if data.end_with? 'nearby'
        place_id = data.chomp('nearby')
        store = Store.find_by(place_id: place_id)
        handle_location(event, user_id, group_id, store.lat, store.lng, store.name_sys)
      elsif data.split('/')[0] == 'book'
        Book.create(user_id: data.split('/')[1], place_id: data.split('/')[2], cost: data.split('/')[4])
        reply_text(event, "已新增你在#{data.split('/')[3]}的消費#{data.split('/')[4]}元")
      else
        reply_text(event, data)
      end

    when Line::Bot::Event::Message
      Group.create(group_id: group_id, status: 'join') unless Group.find_by(group_id: group_id)
      handle_message(event, user_id, is_vip, group_id)
    end
  }
  'OK'
end

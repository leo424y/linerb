require 'sinatra'   # gem 'sinatra'
require 'line/bot'  # gem 'line-bot-api'
require "sinatra/activerecord"
require './config/environments'

def client
  @client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
  }
end

class Log < ActiveRecord::Base
end

post '/callback' do
  body = request.body.read
  events = client.parse_events_from(body)
  events.each { |event|
    case event
    when Line::Bot::Event::Message
      case event.type
      when Line::Bot::Event::MessageType::Text
        m = event.message['text']
        reply = case m
        when /區/ then
          m = m.split(%r{區\s*})
          if m[1]
            Log.create(area: m[0], info: m[1])
            "#{m[0]}區 #{Log.where(area: m[0]).order(id: :desc).pluck(:info)}"
          end
        when /你好/ then "😄"
        else
          tips = Log.where("name LIKE ?", "車禍")
          "#{tips.pluck(:area)}有車禍資訊，請小心#{tips.pluck(:info)}"
        end

        message = {
          type: 'text',
          text: reply
        }

        client.reply_message(event['replyToken'], message)
      end
    end
  }

  "OK"
end

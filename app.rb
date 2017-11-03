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
  # signature = request.env['HTTP_X_LINE_SIGNATURE']
  # unless client.validate_signature(body, signature)
  #   error 400 do 'Bad Request' end
  # end
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
          Log.create(area: m[0], info: m[1])
          "#{m[0]}區 #{Log.where(area: m[0]).pluck(:info)}"
        when /你好/ then "😄"
        else ''
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

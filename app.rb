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
        m = event.message['text'].split(%r{區\s*})
        Log.create(area: m[0], count: m[1])

        reply = case m[0]
        when '西' then "你提供的資訊是：在#{m[0]}區發現#{m[1]}。謝謝你，我收到囉！想知道更多#{m[0]}區情報？請輸入：#{m[0]}區 #{Log.where(area: m[0]+'區').count}"
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

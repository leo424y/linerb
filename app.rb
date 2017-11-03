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
        when /跑了/ then
          run_number = m.gsub(/[^0-9]/, '')
          Log.create(area: '跑單', info: run_number)
          "目前跑#{run_number}單的伙伴，共有#{Log.where(info: run_number).count}人了，實在是太拼了，加油！"
        when /你好/ then "😄"
        when /車禍/ then
          tips = Log.where("info LIKE ?", "%車禍%")
          "#{tips.pluck(:area)}區有車禍資訊，請小心#{tips.pluck(:info)}"
        else
          "請輸入OO區XXX(天候路況店家等有益大家的情報) ex. 東西南北區下大雨 可一併看該區其它情報"
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

require 'sinatra'   # gem 'sinatra'
require 'line/bot'  # gem 'line-bot-api'
require "sinatra/activerecord"
require './config/environments'
require 'nokogiri'
require 'open-uri'

def client
  @client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
  }
end

class Log < ActiveRecord::Base
end

class Place < ActiveRecord::Base
end

post '/callback' do
  body = request.body.read
  events = client.parse_events_from(body)
  events.each { |event|
    case event
    when Line::Bot::Event::Message
      # profile = client.get_profile(event['source']['userId'])
      # profile = JSON.parse(profile.read_body)
      # user_id = event['source']['userId']
      # reply_text(event, [
      #   "Display name\n#{profile['displayName']}",
      #   "Status message\n#{profile['statusMessage']}"
      # ])

      case event.type
      # when Line::Bot::Event::MessageType::Location
      #   l = event.message['address']
      #   area = l.string_between_markers("台中市", "區")
      #   Place.create(address: l)
      #   message = {
      #     type: 'text',
      #     text: "#{area}區 #{Log.where(area: area).where('created_at >= ?', (Time.now - 60*60*24*7) ).order(id: :desc).pluck(:info).join(' 🚴 ')}"
      #   }
      #
      #   client.reply_message(event['replyToken'], message)

      when Line::Bot::Event::MessageType::Text
        m = event.message['text']
        user_id = event['source']['userId']
        profile = client.get_profile(user_id)
        profile = JSON.parse(profile.read_body)
        count = m.split.map{|x| x[/\d+/]}[0].to_i

        reply = case m
        when /福賴我要打/ then
          Log.create(ticket_user: user_id, info: m, ticket_count: count, ticket_status: 'on')
          # users = Log.where(ticket_status: 'on').pluck(:ticket_user)
          # users.each do
          #   user_name << JSON.parse(client.get_profile(user_id).read_body)['displayName']
          # end
          # 目前#{user_name.join(', ')}總共要打#{Log.where(ticket_status: 'on').sum(:ticket_count)}個
          "#{profile['displayName']}要打#{count}個！大家總共要打#{Log.where(ticket_status: 'on').sum(:ticket_count)}個"
        when /福賴我不/ then
          Log.where(ticket_user: user_id).update_all(ticket_status: 'off')
          "#{profile['displayName']}不要打了。剩下的人總共要打#{Log.where(ticket_status: 'on').sum(:ticket_count)}個，請求支援！"
          # 剩下總共要打#{Log.where(ticket_status: 'on').sum(:ticket_count)}"
        when /北運/ then
          tndcsc_count = ''
          url = 'http://tndcsc.com.tw/'
          doc = Nokogiri::HTML(open(url))

          doc.css('.w3_agile_logo p').each do |link|
            tndcsc_count += link.content
          end
          tndcsc_count
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

class String
  def string_between_markers marker1, marker2
    self[/#{Regexp.escape(marker1)}(.*?)#{Regexp.escape(marker2)}/m, 1]
  end
end

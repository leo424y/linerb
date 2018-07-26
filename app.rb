require 'sinatra'   # gem 'sinatra'
require 'line/bot'  # gem 'line-bot-api'
require "sinatra/activerecord"
require './config/environments'
require 'nokogiri'
require 'open-uri'
require 'json'


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
        if m.start_with? '福賴'
          reply = case m
          when /開/ then
            name = m.split('開')[1]
            place=URI.escape(name)
            url = "https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=#{place}&inputtype=textquery&fields=photos,formatted_address,name,rating,opening_hours,geometry&key=AIzaSyCM51UZILRPOLidkBTTHC_hpQ4OZOO9i_k"
            doc = JSON.parse(open(url).read, :headers => true)
            begin
              doc['candidates'][0]['opening_hours']['open_now'] ? "現在#{name}有開" : "現在#{name}沒開"
            rescue
              "#{name}查無資料，你確定有個地方？"
            end
          when /福賴我要打/ then
            Log.create(ticket_user: user_id, info: m, ticket_count: count, ticket_status: 'on')
            # users = Log.where(ticket_status: 'on').pluck(:ticket_user)
            # users.each do
            #   user_name << JSON.parse(client.get_profile(user_id).read_body)['displayName']
            # end
            # 目前#{user_name.join(', ')}總共要打#{Log.where(ticket_status: 'on').sum(:ticket_count)}個
            "#{profile['displayName']}要打#{count}個！大家總共要打#{Log.where(ticket_status: 'on').sum(:ticket_count)}個"
          when /福賴我不要不要打了/ then
            Log.update_all(ticket_status: 'off')
            "沒有半個人要打了"
          when /福賴我不/ then
            Log.where(ticket_user: user_id).update_all(ticket_status: 'off')
            total = Log.where(ticket_status: 'on').sum(:ticket_count)
            result = total == 0 ? '居沒有半個人能打，我要說在座的都是XX！' : "剩下的人總共要打#{total}個，請求支援！"
            "#{profile['displayName']}不要打了。#{result}"
          when /好運/ then
            tndcsc_count = ''
            tndcsc_url = 'http://tndcsc.com.tw/'
            tndcsc_doc = Nokogiri::HTML(open(tndcsc_url))

            tndcsc_doc.css('.w3_agile_logo p').each do |link|
              tndcsc_count += " #{link.content}"
            end

            cmcsc_url = 'https://cmcsc.cyc.org.tw/api'
            cmcsc_doc = JSON.parse(open(cmcsc_url).read, :headers => true)

            "【北區】#{tndcsc_count}   【朝馬】🏊 #{cmcsc_doc['swim'][0]}/#{cmcsc_doc['swim'][1]} 💪 #{cmcsc_doc['gym'][0]}/#{cmcsc_doc['gym'][1]} 快來減脂增肌！"
          else
            '歹勢偶只懂：福賴我要打10個、福賴我不要打了、福賴好運'
          end

          message = {
            type: 'text',
            text: reply
          }

          client.reply_message(event['replyToken'], message)
        end
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

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
          "#{profile['displayName']}要打#{count}個！總共要打#{Log.where(ticket_status: 'on').sum(:ticket_count)}"
        when /福賴我不/ then
          Log.where(ticket_user: user_id).update_all(ticket_status: 'off')
          "#{profile['displayName']}不要打了，請求支援！總共要打#{Log.where(ticket_status: 'on')}"
          # 剩下總共要打#{Log.where(ticket_status: 'on').sum(:ticket_count)}"

        # when /罰單/ then
        #   m = m.split(%r{罰單\s*})
        #   if (m[1].to_f > 0)
        #     Log.create(area: '交罰單', info: m[1])
        #     "謝謝提升國庫#{m[1]}銀兩，目前累計#{Log.where(area: '交罰單').sum(:info)}"
        #   elsif m[1].nil?
        #     "目前累計#{Log.where(area: '罰單們').sum(:info)}"
        #   end
        # when /鴿子在/ then
        #   m = m.split(%r{鴿子在\s*})
        #   if m[1]
        #     Log.create(area: '鴿子', info: m[1])
        #     "謝謝猴主人回報#{m[1]}有鴿子"
        #   end
        # when /區/ then
        #   m = m.split(%r{區\s*})
        #   if m[1]
        #     Log.create(area: m[0], info: m[1])
        #
        #     "#{m[0]}區 #{Log.where(area: m[0]).where('created_at >= ?', (Time.now - 60*60*24*7) ).order(id: :desc).pluck(:info).join(' 🚴 ')}"
        #   end
        # when /我覺得/ then
        #   m = m.split(%r{我覺得\s*})
        #   if m[1]
        #     Log.create(area: '我覺得', info: m[1])
        #     "猴主人們最近覺得：#{Log.where(area: '我覺得').order(id: :desc).pluck(:info).join(' 🚴 ')}"
        #   end
        # when /鴿子/ then
        #     "猴主人回報這些地方有鴿子：#{Log.where(area: '鴿子').order(id: :desc).pluck(:info).join('🐦')}"
        # when /我跑了/ then
        #   run_number = m.gsub(/[^0-9]/, '')
        #   Log.create(area: '跑單數', info: run_number)
        #
        #   all_number = Log.where(area: '跑單數').where('created_at >= ?', (Time.now - 60*60*24*1)).group(:info).count.keys
        #   all_msg = ''
        #   all_number.each do |a|
        #     all_msg << ("達#{a}單#{Log.where('created_at >= ?', (Time.now - 60*60*24*1)).group(:info).count[a]}人 🚴 ")
        #   end
        #
        #   "一天內累計跑#{run_number}單的猴主人共有#{Log.where('created_at >= ?', (Time.now - 60*60*24*1)).where(info: run_number).count}人。#{all_msg} 讓🐵優猴繼續為你加油！ 🚴 送餐平安，日日平安 🚴 "
        # when /你好/ then "😄"
        # when /車禍/ then
        #   tips = Log.where("info LIKE ?", "%車禍%").where('created_at >= ?', (Time.now - 60*60*24*1))
        #   "#{tips.pluck(:area)}區有車禍資訊，請小心#{tips.pluck(:info)}"
        # else
        #   [
        #     "🍌 餵我【OO區X】(X是天候路況店家等情報) 例：東西南北區下大雨 可一併看該區其他情報",
        #     "🍌 餵我【我跑了(數量)單】看看多少夥伴與你一樣拼",
        #     "🍌 餵我【全區加油】為奔波的自己與彼此打氣！",
        #     "🍌 餵我【全區開跑】宣告今天即將爆單！",
        #     "🍌 餵我【我覺得(感受)】抒發心情或給猴子管理員建議，也看看其他主人們心情如何。",
        #     "🍌 餵我【鴿子在...】與【鴿子】分別能回報與查詢牠們，避免一天的辛苦成為飼料。🐦",
        #     "🌏 按左下➕號分享位置資訊可查詢附近情報",
        #   ].shuffle.first
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

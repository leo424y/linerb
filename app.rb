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

def client
  @client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
  }
end

class Log < ActiveRecord::Base
end

class Store < ActiveRecord::Base
end

class Place < ActiveRecord::Base
end

get '/storecsv' do
  csv_string = CSV.generate do |csv|
    csv << @stores.attribute_names
    @stores.all.each do |user|
      csv << user.attributes.values
    end
  end
  content_type 'application/octet-stream'
  csv_string
end

get '/storeyy' do
  @stores = Store.last(100)

  erb <<-EOF
  <!DOCTYPE html>
  <html>
    <head>
      <title>LinerbSite</title>
    </head>
    <body>
      <table>
        <thead>
          <tr>
            <th>Name</th>
            <th>Info</th>
          </tr>
        </thead>

        <tbody>
          <% @stores.each do |store| %>
            <% profile = JSON.parse(client.get_profile(store.info).read_body)['displayName'] %>
            <tr>
              <td><%= store.name %></td>
              <td><%= profile %></td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </body>
  </html>
  EOF
end


post '/callback' do
  body = request.body.read
  events = client.parse_events_from(body)
  events.each { |event|
    case event
    when Line::Bot::Event::Message
      case event.type
      when Line::Bot::Event::MessageType::Text
        m = event.message['text'].rstrip.chomp('？').chomp('?').chomp('!').chomp('！').chomp('嗎')
        user_id = event['source']['userId']
        profile = client.get_profile(user_id)
        profile = JSON.parse(profile.read_body)
        # count = m.split.map{|x| x[/\d+/]}[0].to_i

        suffixes = %w(有沒有開 有開沒開 開了沒 沒開 有開 開了)
        name = m.chomp('有沒有開').chomp('開了沒').chomp('沒開').chomp('有開').chomp('開了')

        if m.end_with?(*suffixes) && (name != '') && (name.bytesize < 40)
          gmap_key = ENV["GMAP_API_KEY"]
          place = URI.escape(name)
          # weekday = Date.today.strftime('%A')
          url = "https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=#{place}&inputtype=textquery&fields=place_id,photos,formatted_address,name,rating,opening_hours,geometry&key=#{gmap_key}"
          link = "https://www.google.com/maps/search/?api=1&query=#{place}"
          s_link = %x(ruby bin/bitly.rb '#{link}').chomp
          doc = JSON.parse(open(url).read, :headers => true)
          begin
            formatted_phone_number = ''
            opening_hours = ''
            funny = (m.include? "沒開") ? '啦!~~~~' : ""
            place_id = doc['candidates'][0]['place_id']
            # thumbnailImageUrl = 'https://cdn.pixabay.com/photo/2018/05/21/12/43/sign-3418163_960_720.png'
            unless place_id.nil?
              place_id_url = "https://maps.googleapis.com/maps/api/place/details/json?placeid=#{place_id}&fields=name,formatted_phone_number,rating,opening_hours&key=#{gmap_key}"
              place_id_doc = JSON.parse(open(place_id_url).read, :headers => true)
              formatted_phone_number = "#{place_id_doc['result']['formatted_phone_number'].gsub(" ","")}" unless place_id_doc['result']['formatted_phone_number'].nil?
              is_open_now = place_id_doc['result']['opening_hours']['open_now']

              opening_hours = is_open_now ? "😃 現在有開#{funny}" : "🔴 現在沒開"
              # image_url = URI.parse("https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=#{place_id_doc['result']['photos'][0]['photo_reference']}&key=#{gmap_key}")
              # thumbnailImageUrl = "https://#{Net::HTTP.get(image_url).string_between_markers('https://','=s1600-w400')}=s1600-w400"
            end
            # rating = (doc['candidates'][0]['rating'].to_f * 2).to_i
            # star = '⭐'* (rating/2)+'✨' * (rating%2)
            # reply = "【#{name}】\n#{opening_hours}📍 地圖 #{s_link}\n#{promote}"
            actions_phone_h = {
                                type: 'uri',
                                label: '📞 通話',
                                uri: "tel:#{formatted_phone_number}"
                              }
            actions_a = [
              {
                type: 'uri',
                label: '📍 地圖',
                uri: s_link
              },
              (actions_phone_h if is_open_now),
              {
                type: 'uri',
                label: '👍 推薦',
                uri: "line://nv/recommendOA/@gxs2296l"
              },
              {
                type: 'uri',
                label: '💡 回報',
                uri: 'line://home/public/post?id=gxs2296l&postId=1153267270308077285'
              },
            ].compact
            message_buttons = {
              type: 'template',
              altText: '...',
              template: {
                type: 'buttons',
                title: name,
                text: opening_hours,
                actions: actions_a,
              }
            }
          rescue
            reply = "藏在你心底的【#{name}】有點神秘，直接看地圖結果如何？ \n📍 #{s_link}"
            message = {
              type: 'text',
              text: reply
            }
          end

          Store.create(name: name, info: user_id)
          client.reply_message(event['replyToken'], (message_buttons.nil? ? message :  message_buttons) )
        end

        if m.start_with? '福賴'
          reply = case m
          # when /福賴我要打/ then
          #   Log.create(ticket_user: user_id, info: m, ticket_count: count, ticket_status: 'on')
          #   "#{profile['displayName']}要打#{count}個！大家總共要打#{Log.where(ticket_status: 'on').sum(:ticket_count)}個"
          # when /福賴我不要不要打了/ then
          #   Log.update_all(ticket_status: 'off')
          #   "沒有半個人要打了"
          # when /福賴我不/ then
          #   Log.where(ticket_user: user_id).update_all(ticket_status: 'off')
          #   total = Log.where(ticket_status: 'on').sum(:ticket_count)
          #   result = total == 0 ? '居沒有半個人能打，我要說在座的都是XX！' : "剩下的人總共要打#{total}個，請求支援！"
          #   "#{profile['displayName']}不要打了。#{result}"
          when /好運/ then
            tndcsc_count = ''
            tndcsc_url = 'http://tndcsc.com.tw/'
            tndcsc_doc = Nokogiri::HTML(open(tndcsc_url))
            tndcsc_doc.css('.w3_agile_logo p').each_with_index do |l, index|
              tndcsc_count += (" #{l.content}".split.map{|x| x[/\d+/]}[0] + (index==0 ? '/350 🏊 ' : '/130 💪'))
            end
            cmcsc_url = 'https://cmcsc.cyc.org.tw/api'
            cmcsc_doc = JSON.parse(open(cmcsc_url).read, :headers => true)
            "【北區】#{tndcsc_count}     【朝馬】#{cmcsc_doc['swim'][0]}/#{cmcsc_doc['swim'][1]} 🏊 #{cmcsc_doc['gym'][0]}/#{cmcsc_doc['gym'][1]} 💪 快來減脂增肌！"
          # else
            # '歹勢偶只懂：福賴我要打10個、福賴我不要打了、福賴好運、福賴開(你要查的店名)'
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
end


class String
  def string_between_markers marker1, marker2
    self[/#{Regexp.escape(marker1)}(.*?)#{Regexp.escape(marker2)}/m, 1]
  end
end

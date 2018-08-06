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

class Log < ActiveRecord::Base; end
class Store < ActiveRecord::Base; end
class Vip < ActiveRecord::Base; end

get '/x/:yy' do
  content_type 'application/octet-stream'
  CSV.generate do |csv|
    yy=[Vip, Store].find { |c| c.to_s == params['yy'] }
    csv << yy.attribute_names
    yy.all.each do |user|
      csv << user.attributes.values
    end
  end
end

get '/storeyy' do
  @stores = Store.last(20)
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
            <th>Group</th>
          </tr>
        </thead>

        <tbody>
          <% @stores.each do |store| %>
            <% profile = JSON.parse(client.get_profile(store.info).read_body)['displayName'] %>
            <tr>
              <td><%= store.name %></td>
              <td><%= profile %></td>
              <td><%= store.group_id %></td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </body>
  </html>
  EOF
end

post '/callback' do
  events = client.parse_events_from(request.body.read)
  events.each { |event|
    case event
    when Line::Bot::Event::Join
      message = []
      message << {
        type: 'text',
        text: '大家好，歡迎使用【XXX有開嗎】'
      }
      message << {
        type: 'text',
        text: '【有開嗎】會自動幫你查詢想去的店家喔！'
      }
      client.reply_message(event['replyToken'], message)
    when Line::Bot::Event::Message
      case event.type
      when Line::Bot::Event::MessageType::Text
        user_id = event['source']['userId']
        group_id = event['source']['groupId']
        in_vip = Vip.find_by(user_id: user_id)
        is_vip = in_vip ? "👑 LVX：不再落空開兒" : "☘ LV0：暫不落空開兒"
        suffixes = IO.readlines("data/keywords").map(&:chomp)
        skip_name = IO.readlines("data/top200_731a").map(&:chomp)

        m = event.message['text'].downcase.delete(" .。，,!！?？\t\r\n").chomp('嗎')
        name = m.chomp('有沒有開').chomp('開了沒').chomp('沒開').chomp('有開').chomp('開了').chomp('は開いていますか').chomp('現在')
        place = URI.escape(name)
        link = "https://www.google.com/maps/search/?api=1&query=#{place}"
        s_link = %x(ruby bin/bitly.rb '#{link}').chomp

        if m.end_with?(*suffixes) && (name != '') && (name.bytesize < 40)
          level_up_button = {
            type: 'message',
            label: '🥇 升級',
            text: IO.readlines("data/promote_text").join
          } unless in_vip
          actions_a = [
            {
              type: 'uri',
              label: '📍 詳情',
              uri: s_link
            },
            {
              type: 'uri',
              label: '💡 建議',
              uri: 'line://home/public/post?id=gxs2296l&postId=1153267270308077285'
            },
            {
              type: 'uri',
              label: '👍 推薦',
              uri: "line://nv/recommendOA/@gxs2296l"
            },
            level_up_button,
          ].compact
          if name == '麥當勞中港四店'
            message_buttons_text = '😃 現在有開'
          elsif user_id && (!skip_name.include? name)
            gmap_key = ENV["GMAP_API_KEY"]
            url = "https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=#{place}&inputtype=textquery&language=zh-TW&fields=place_id,name&key=#{gmap_key}"
            doc = JSON.parse(open(url).read, :headers => true)
            place_id = doc['candidates'][0]['place_id'] if doc['candidates'][0]
            begin
              unless place_id.nil?
                place_id_url = "https://maps.googleapis.com/maps/api/place/details/json?placeid=#{place_id}&language=zh-TW&fields=name,type,address_component,geometry,opening_hours,formatted_address&key=#{gmap_key}"
                place_id_doc = JSON.parse(open(place_id_url).read, :headers => true)
                res = place_id_doc['result']
                formatted_address = res['formatted_address']
                address_components = res['address_components']
                name_sys = res['name']
                lat = res['geometry']['location']['lat']
                lng = res['geometry']['location']['lng']
                if res['opening_hours']
                  place_types = res['types']
                  is_open_now = res['opening_hours']['open_now']
                  periods = res['opening_hours']['periods']
                  weekday_text = res['opening_hours']['weekday_text']
                  opening_hours = is_open_now ? "😃 現在有開" : "🔴 現在沒開"
                  message_buttons_text = opening_hours
                else
                  message_buttons_text = '😬 無營業時間，請老闆幫忙加上如何？'
                end
                Store.create(
                  name: name,
                  name_sys: name_sys,
                  address_components: address_components,
                  formatted_address: formatted_address,
                  lat: lat,
                  lng: lng,
                  place_types: place_types,
                  info: user_id,
                  group_id: group_id,
                  place_id: place_id,
                  opening_hours: res['opening_hours'] ? is_open_now.to_s : 'no',
                  weekday_text: weekday_text,
                  periods: periods,
                  s_link: s_link
                )
              else
                message_buttons_text = '⏰ 請見詳情'
              end
            rescue
              message_buttons_text = '😂 請見詳情'
            end
          else
            message_buttons_text = '🤔 請見詳情'
          end
          message_buttons = {
            type: 'template',
            altText: '...',
            template: {
              type: 'buttons',
              title: name,
              text: "#{message_buttons_text}\n#{is_vip}",
              actions: actions_a,
            }
          }
          client.reply_message(event['replyToken'], message_buttons )
        end
        if (m.start_with? '不再落空') && user_id && (group_id || (m.end_with? '讚'))
          Vip.create(user_id: user_id, group_id: (group_id || 'sponsor'))
          message = {
            type: 'text',
            text: IO.readlines("data/promote_check").join
          }
          client.reply_message(event['replyToken'], message)
        end

        if m.start_with? '福賴'
          reply = case m
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

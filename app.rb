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

def reply_text(event, texts)
  texts = [texts] if texts.is_a?(String)
  client.reply_message(
    event['replyToken'],
    texts.map { |text| {type: 'text', text: text} }
  )
end

def reply_content(event, messages)
  res = client.reply_message(
    event['replyToken'],
    messages
  )
  puts res.read_body if res.code != 200
end

class Log < ActiveRecord::Base; end
class Group < ActiveRecord::Base; end
class Pocket < ActiveRecord::Base; end
class Store < ActiveRecord::Base; end
class Vip < ActiveRecord::Base; end

get '/x/:yy' do
  content_type 'application/octet-stream'
  CSV.generate do |csv|
    yy=[Vip, Store, Group, Pocket].find { |c| c.to_s == params['yy'] }
    csv << yy.attribute_names
    yy.all.each do |user|
      csv << user.attributes.values
    end
  end
end

get '/n/:yy' do
  erb <<-EOF
  <!DOCTYPE html>
  <html>
    <body>
      <%= JSON.parse(client.get_profile(params['yy']).read_body)['displayName'] %>
    </body>
  </html>
  EOF
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
    user_id = event['source']['userId']
    group_id = event['source']['groupId'] || event['source']['roomId']
    sys_group = Group.where(group_id: group_id, status: 'join').first
    is_group = sys_group ? sys_group : Group.create(group_id: group_id, status: 'join')
    is_group.update(talk_count: is_group.talk_count+1) unless group_id.nil?
    case event
    when Line::Bot::Event::Join
      message = []
      message << {
        type: 'text',
        text: '大家好，歡迎輸入【XXX有開嗎】(XXX是你想去的店)，【有開嗎】會自動幫你查詢想去的店家喔！'
      }
      message << {
        type: 'text',
        text: '嘿！熱情邀請我進來的朋友，或許可以請你示範一下？ 😘'
      }
      Group.create(group_id: group_id, status: 'join')
      client.reply_message(event['replyToken'], message)
    when Line::Bot::Event::Leave
      Group.update(group_id: group_id, status: 'leave')
    when Line::Bot::Event::Postback
      message = "[POSTBACK]\n#{event['postback']['data']} (#{JSON.generate(event['postback']['params'])})"
      reply_text(event, message)
    when Line::Bot::Event::Message
      case event.type
      when Line::Bot::Event::MessageType::Location
        # handle_location(event)
        message = event.message
        my_lat = message['latitude'].to_s[0..4]
        my_lng = message['longitude'].to_s[0..5]
        my_store = Store.where("lat like ?", "#{my_lat}%").where("lng like ?", "#{my_lng}%")
        result = my_store.pluck(:name, :s_link).uniq.join("\n")
        result_message = result ? "附近開民怕落空的店\n#{result}" : "附近尚無開民，趕快來當第一吧！"
        reply_text(event, result_message)
      when Line::Bot::Event::MessageType::Text
        in_vip = Vip.find_by(user_id: user_id)
        is_vip = in_vip ? "👑 LVX：不再落空" : "☘ LV0：暫不落空"
        suffixes = IO.readlines("data/keywords").map(&:chomp)
        skip_name = IO.readlines("data/top200_731a").map(&:chomp)

        m = event.message['text'].downcase.delete(" .。，,!！?？\t\r\n").chomp('嗎')
        name = m.chomp('有沒有開').chomp('開了沒').chomp('沒開').chomp('有開').chomp('開了').chomp('は開いていますか').chomp('現在')
        place = URI.escape(name)
        link = "https://www.google.com/maps/search/?api=1&query=#{place}"
        s_link = %x(ruby bin/bitly.rb '#{link}').chomp

        if in_vip
          level_up_button = {
            type: 'message',
            label: "👜 放口袋",
            text: "#{name}放口袋~"
          }
        else
          level_up_button = {
            type: 'message',
            label: '🥇 升級',
            text: IO.readlines("data/promote_text").join
          }
        end

        if name.end_with?('放口袋~')
          if in_vip
            Pocket.create(user_id: user_id, place_name: name.chomp('放口袋~'))
            message_text = "👜 已將#{name}"
          else
            message_text = '🥇 請先升級就能放口袋囉'
          end
          message = {
            type: 'text',
            text: message_text
          }
          client.reply_message(event['replyToken'], message)
        elsif m.end_with?(*suffixes) && (name != '') && (name.bytesize < 40)
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
          elsif name == '鬼門'
            message_buttons_text = (Date.today < Date.new(2018,8,10)) ? '👻 現在沒開' : '👻👻👻 現在正開'
          elsif user_id && (!skip_name.include? name)
            is_group.update(use_count: is_group.use_count+1) unless group_id.nil?
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
                is_group.update(result_count: is_group.result_count+1) unless group_id.nil?
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

def handle_location(event)
  message = event.message
  reply_content(event, {
    type: 'location',
    title: message['title'] || message['address'],
    address: message['address'],
    latitude: message['latitude'],
    longitude: message['longitude']
  })
end

class String
  def string_between_markers marker1, marker2
    self[/#{Regexp.escape(marker1)}(.*?)#{Regexp.escape(marker2)}/m, 1]
  end
end

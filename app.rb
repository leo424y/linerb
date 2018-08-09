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

GG_SEARCH_URL = "https://www.google.com/maps/search/?api=1&query="
GG_FIND_URL = "https://maps.googleapis.com/maps/api/place/findplacefromtext/json"
GG_DETAIL_URL = 'https://maps.googleapis.com/maps/api/place/details/json'
GMAP_KEY = ENV["GMAP_API_KEY"]

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
class Position < ActiveRecord::Base; end
class Store < ActiveRecord::Base; end
class Talk < ActiveRecord::Base; end
class Vip < ActiveRecord::Base; end

get '/x/:yy' do download_csv end
get '/n/:yy' do display_name end
get '/s/:yy' do render_html end

post '/callback' do
  events = client.parse_events_from(request.body.read)
  events.each { |event|
    user_id = event['source']['userId']
    in_vip = Vip.find_by(user_id: user_id)
    group_id = event['source']['groupId'] || event['source']['roomId']
    sys_group = Group.where(group_id: group_id, status: 'join').first
    is_group = sys_group ? sys_group : Group.create(group_id: group_id, status: 'join')
    is_group.update(talk_count: is_group.talk_count+1) unless group_id.nil?

    case event
    when Line::Bot::Event::Join
      handle_join(event, group_id)

    when Line::Bot::Event::Leave
      Group.update(group_id: group_id, status: 'leave')

    when Line::Bot::Event::Postback
      message = "[POSTBACK]\n#{event['postback']['data']} (#{JSON.generate(event['postback']['params'])})"
      reply_text(event, message)

    when Line::Bot::Event::Message
      handle_message(event, user_id, in_vip, group_id, is_group)
    end
  }
end

def download_csv
  content_type 'application/octet-stream'
  CSV.generate do |csv|
    yy = [Vip, Store, Group, Pocket, Position, Talk].find { |c| c.to_s == params['yy'] }
    csv << yy.attribute_names
    yy.all.each do |user|
      csv << user.attributes.values
    end
  end
end

def display_name
  erb <<-EOF
  <!DOCTYPE html>
  <html>
    <body>
      <%= JSON.parse(client.get_profile(params['yy']).read_body)['displayName'] %>
    </body>
  </html>
  EOF
end

def render_html
  yy = [Vip, Store, Group, Pocket, Position, Talk].find { |c| c.to_s == params['yy'] }
  @datas = yy.last(100)

  erb <<-EOF
  <!DOCTYPE html>
  <html>
    <head>
      <title>LinerbSite</title>
    </head>
    <body>
      <table>
        <tbody>
          <% @datas.each do |d| %>
            <tr>
              <% values = d.attributes.values %>
              <% values.each do |v| %>
                <% if v.instance_of?(DateTime) %>
                  <td><%= v.strftime('%m%d%H%M%S') %></td>
                <% elsif v.to_s.length < 50 %>
                  <td><%= v %></td>
                <% end %>
              <% end %>
            </tr>
          <% end %>
        </tbody>
      </table>
    </body>
  </html>
  EOF
end

def handle_join(event, group_id)
  Group.create(group_id: group_id, status: 'join')
  reply_text(event, IO.readlines("data/join").map(&:chomp))
end

def handle_location(event, user_id)
  message = event.message
  my_lat = message['latitude'].to_s[0..4]
  my_lng = message['longitude'].to_s[0..5]
  my_store = Store.where("lat like ?", "#{my_lat}%").where("lng like ?", "#{my_lng}%")
  results = my_store.pluck(:name_sys).uniq[0..3]
  result_message = results.empty? ? "🗽 附近尚無開民蹤影，趕快來當第一吧！" : "🎐 附近開民怕落空的地點有..."
  Position.create(user_id: user_id, lat: message['latitude'], lng: message['longitude'])
  actions_a = results.map do |result|
    {
      type: 'uri', label: "📍 #{result}", uri: "#{GG_SEARCH_URL}#{result}"
    }
  end
  message_buttons = {
    type: 'template',
    altText: '...',
    template: {
      type: 'buttons',
      title: '開民雷達',
      text: result_message,
      actions: actions_a,
    }
  }
  reply_content(event, message_buttons)
end

def handle_message(event, user_id, in_vip, group_id, is_group)
  Talk.create(user_id: user_id, group_id: group_id, talk: event.message['text'])

  case event.type
  when Line::Bot::Event::MessageType::Location
    group_id ? handle_location(event, user_id) : reply_text(event, '請於群組中使用')

  when Line::Bot::Event::MessageType::Text
    is_vip = in_vip ? "👑 LVX：不再落空" : "☘ LV0：暫不落空"
    suffixes = IO.readlines("data/keywords").map(&:chomp)
    skip_name = IO.readlines("data/top200_731a").map(&:chomp)

    m = event.message['text'].downcase.delete(" .。，,!！?？\t\r\n").chomp('嗎')
    name = m.chomp('有沒有開').chomp('開了沒').chomp('沒開').chomp('有開').chomp('開了').chomp('は開いていますか').chomp('現在')
    place = URI.escape(name)
    link = "#{GG_SEARCH_URL}#{place}"

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
    if ['福賴好運', '北運', '朝運'].include? m
      message = count_exercise
      reply_text(event, message)

    elsif name.end_with?('放口袋~')
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
      s_link = %x(ruby bin/bitly.rb '#{link}').chomp

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
        url = "#{GG_FIND_URL}?input=#{place}&inputtype=textquery&language=zh-TW&fields=place_id,name&key=#{GMAP_KEY}"
        doc = JSON.parse(open(url).read, :headers => true)
        place_id = doc['candidates'][0]['place_id'] if doc['candidates'][0]
        begin
          unless place_id.nil?
            place_id_url = "#{GG_DETAIL_URL}?placeid=#{place_id}&language=zh-TW&fields=name,type,address_component,geometry,opening_hours,formatted_address&key=#{GMAP_KEY}"
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
              if user_id && group_id && !in_vip
                vip_msg = [
                  "【#{name}】#{opening_hours}",
                  add_vip(event, user_id, group_id, opening_hours),
                ]
                reply_text(event, vip_msg)
              end
            else
              message_buttons_text = '😬 請見詳情'
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
      reply_content(event, message_buttons)
    end

    # to remove
    if !in_vip && (m.start_with? '不再落空') && user_id && (group_id || (m.end_with? '讚'))
      reply_text(event, add_vip(event, user_id, group_id, opening_hours=''))
    end
    # to remove
  end
end

def add_vip(event, user_id, group_id, opening_hours)
  Vip.create(user_id: user_id, group_id: (group_id || 'sponsor'))
  "#{user_name user_id}#{IO.readlines("data/promote_check").join}"
end

def user_name id
  JSON.parse(client.get_profile(id).read_body)['displayName']
end

def count_exercise
  tndcsc_count = ''
  tndcsc_url = 'http://tndcsc.com.tw/'
  tndcsc_doc = Nokogiri::HTML(open(tndcsc_url))
  tndcsc_doc.css('.w3_agile_logo p').each_with_index do |l, index|
    tndcsc_count += (" #{l.content}".split.map{|x| x[/\d+/]}[0] + (index==0 ? '/350 🏊 ' : '/130 💪'))
  end
  cmcsc_url = 'https://cmcsc.cyc.org.tw/api'
  cmcsc_doc = JSON.parse(open(cmcsc_url).read, headers: true)
  "【北區】#{tndcsc_count}     【朝馬】#{cmcsc_doc['swim'][0]}/#{cmcsc_doc['swim'][1]} 🏊 #{cmcsc_doc['gym'][0]}/#{cmcsc_doc['gym'][1]} 💪 快來減脂增肌！"
end

class String
  def string_between_markers marker1, marker2
    self[/#{Regexp.escape(marker1)}(.*?)#{Regexp.escape(marker2)}/m, 1]
  end
end

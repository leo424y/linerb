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
class Place < ActiveRecord::Base; end
class Vip < ActiveRecord::Base; end

get '/storecsv' do
  content_type 'application/octet-stream'
  CSV.generate do |csv|
    csv << Store.attribute_names
    Store.all.each do |user|
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
  body = request.body.read
  events = client.parse_events_from(body)
  events.each { |event|
    case event
    when Line::Bot::Event::Message
      case event.type
      when Line::Bot::Event::MessageType::Text
        m = event.message['text'].rstrip.chomp('？').chomp('?').chomp('!').chomp('！').chomp('嗎')
        user_id = event['source']['userId']
        group_id = event['source']['groupId']
        user_name = JSON.parse(client.get_profile(user_id).read_body)['displayName']

        suffixes = %w(有沒有開 有開沒開 開了沒 沒開 有開 開了)
        skip_name = IO.readlines("data/top200_731a")

        name = m.chomp('有沒有開').chomp('開了沒').chomp('沒開').chomp('有開').chomp('開了')
        place = URI.escape(name)
        link = "https://www.google.com/maps/search/?api=1&query=#{place}"
        s_link = %x(ruby bin/bitly.rb '#{link}').chomp
        # input_duration = Time.now - Store.order(id: :desc).find_by(info: user_id).created_at
        # not_ddos = (input_duration > 10)
        not_ddos = Store.last.info != user_id
        if m.end_with?(*suffixes) && (name != '') && (name.bytesize < 40)
          actions_a = [
            {
              type: 'uri',
              label: '📍 詳情',
              uri: s_link
            },
            {
              type: 'uri',
              label: '👍 推薦',
              uri: "line://nv/recommendOA/@gxs2296l"
            },
            {
              type: 'message',
              label: '🥇 優先',
              text: IO.readlines("data/promote_text").join
            },
          ]

          if m == '麥當勞中港四店有開'
            message_buttons_text = '😃 現在有開'
          else user_id && not_ddos && (!skip_name.map(&:chomp).include? name)
            gmap_key = ENV["GMAP_API_KEY"]
            # weekday = Date.today.strftime('%A')
            url = "https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=#{place}&inputtype=textquery&fields=place_id,name&key=#{gmap_key}"
            doc = JSON.parse(open(url).read, :headers => true)

            begin
              opening_hours = ''
              funny = (m.include? "沒開") ? '啦!~~~~' : ""
              place_id = doc['candidates'][0]['place_id']
              unless place_id.nil?
                place_id_url = "https://maps.googleapis.com/maps/api/place/details/json?placeid=#{place_id}&fields=name,opening_hours&key=#{gmap_key}"
                place_id_doc = JSON.parse(open(place_id_url).read, :headers => true)
                is_open_now = place_id_doc['result']['opening_hours']['open_now']
                if is_open_now
                  opening_hours = "😃 現在有開#{funny}"
                  # place_id_url = "https://maps.googleapis.com/maps/api/place/details/json?placeid=#{place_id}&fields=formatted_phone_number&key=#{gmap_key}"
                  # place_id_doc = JSON.parse(open(place_id_url).read, :headers => true)
                  # formatted_phone_number = "#{place_id_doc['result']['formatted_phone_number'].gsub(" ","")}" unless place_id_doc['result']['formatted_phone_number'].nil?
                else
                  opening_hours = "🔴 現在沒開"
                end
              end
              message_buttons_text = opening_hours
              Store.create(name: name, info: user_id, group_id: group_id)
            rescue
              message_buttons_text = '⏰ 請見詳情'
            end
          end

          message_buttons = {
            type: 'template',
            altText: '...',
            template: {
              type: 'buttons',
              title: name,
              text: message_buttons_text,
              actions: actions_a,
            }
          }
          client.reply_message(event['replyToken'], message_buttons )
        end
        if (m == '不再落空') && user_id && group_id
          Vip.create(user_id: user_id, group_id: group_id)
          message = {
            type: 'text',
            text: "感謝您讓群組成員不再落空，系統確認後將優先為大家查詢「有開嗎」。歡迎拉我進其他群組，也可提升優先權哦！"
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

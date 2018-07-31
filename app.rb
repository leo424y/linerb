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
        profile = JSON.parse(client.get_profile(user_id).read_body)['displayName']
        suffixes = %w(有沒有開 有開沒開 開了沒 沒開 有開 開了)
        skip_name = IO.readlines("data/top200_731a")

        name = m.chomp('有沒有開').chomp('開了沒').chomp('沒開').chomp('有開').chomp('開了')
        place = URI.escape(name)
        link = "https://www.google.com/maps/search/?api=1&query=#{place}"
        s_link = %x(ruby bin/bitly.rb '#{link}').chomp
# .order(id: :desc).limit(3).where(sub_category_id: 1).last[:created_at]
        not_ddos = (Time.now - Store.order(id: :desc).limit(10).find_by(info: user_id)[:created_at] < 10)
        if m.end_with?(*suffixes) && (name != '') && (name.bytesize < 40) && (!skip_name.map(&:chomp).include? name)
          if profile && not_ddos
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
              # actions_phone_h = {
              #   type: 'uri',
              #   label: '📞 通話',
              #   uri: "tel:#{formatted_phone_number}"
              # }
              # (actions_phone_h if formatted_phone_number),
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
                  label: '👏 鼓勵',
                  text: '有開嗎？那藏在你心底深處的秘密基地！這是一個獨立開發的服務，所有軟硬體支出皆由一人負責，若你支持這個想法，歡迎「推薦」親友，或由至首頁留下寶貴意見，而您的「贊助」則是讓這個服務持續運作的重要因素，您可以點此：http://j.mp/is_open 自由贊助任意金額，「有開嗎」邀請你一起讓大家的心，不再落空。'
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
              message_buttons = {
                type: 'template',
                altText: '...',
                template: {
                  type: 'buttons',
                  title: name,
                  text: '🤷 有點神秘，請見詳情',
                  actions: [
                    {
                      type: 'uri',
                      label: '📍 詳情',
                      uri: s_link
                    },
                  ]
                }
              }
              # reply = "藏在你心底的【#{name}】有點神秘，直接看地圖結果如何？ \n📍 #{s_link}"
              # message = {
              #   type: 'text',
              #   text: reply
              # }
            end

            Store.create(name: name, info: user_id)
          else
            message_buttons = {
              type: 'template',
              altText: '...',
              template: {
                type: 'buttons',
                title: name,
                text: '🤷 有點神秘，請見詳情',
                actions: [
                  {
                    type: 'uri',
                    label: '📍 詳情',
                    uri: s_link
                  },
                ]
              }
            }
          end
          client.reply_message(event['replyToken'], message_buttons )
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

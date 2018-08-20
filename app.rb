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
require './model.rb'

GG_SEARCH_URL = "https://www.google.com/maps/search/?api=1&query="
GG_FIND_URL = "https://maps.googleapis.com/maps/api/place/findplacefromtext/json"
GG_DETAIL_URL = 'https://maps.googleapis.com/maps/api/place/details/json'
GMAP_KEY = ENV["GMAP_API_KEY"]
L_OPINION_URI = 'line://home/public/post?id=gxs2296l&postId=1153267270308077285'
L_RECOMMEND_URI = "line://nv/recommendOA/@gxs2296l"
L_SPONSOR_URI = 'http://j.mp/open_sponsor'

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

get '/x/:yy' do download_csv end
get '/n/:yy' do display_name end
get '/s/:yy' do render_html end

post '/callback' do
  events = client.parse_events_from(request.body.read)
  events.each { |event|
    user_id = event['source']['userId']
    is_vip = Vip.find_by(user_id: user_id)
    group_id = event['source']['groupId'] || event['source']['roomId']

    case event
    when Line::Bot::Event::Join
      Group.create(group_id: group_id, status: 'join')
      reply_text(event, IO.readlines("data/join").map(&:chomp))

    when Line::Bot::Event::Leave
      Group.find_by(group_id: group_id).update(status: 'leave')

    when Line::Bot::Event::Postback
      data = event['postback']['data']
      if data.end_with? 'nearby'
        place_id = data.chomp('nearby')
        store = Store.find_by(place_id: place_id)
        handle_location(event, user_id, group_id, store.lat, store.lng, store.name_sys)
      elsif data.split('/')[0] == 'book'
        Book.create(user_id: data.split('/')[1], place_id: data.split('/')[2], cost: data.split('/')[4])
        reply_text(event, "已新增你在#{data.split('/')[3]}的消費#{data.split('/')[4]}元")
      else
        reply_text(event, data)
      end

    when Line::Bot::Event::Message
      Group.create(group_id: group_id, status: 'join') unless Group.find_by(group_id: group_id)
      handle_message(event, user_id, is_vip, group_id)
    end
  }
  'OK'
end

def handle_location(event, user_id, group_id, lat, lng, origin_name)
  begin
    results = handle_nearby(lat, lng, origin_name)
    result_message = results.empty? ? "🗽 附近尚無開民蹤影，趕快來當第一吧！" : "🎐 附近開民怕落空的地點有..."
    actions_a = results.map { |r|
      { label: "📍 #{r}" , type: 'message', text: "#{r}有開嗎？" }
    }.compact
    if actions_a.empty?
      reply_text(event, '🗽 附近尚無開民蹤影，趕快來當第一吧！')
    else
      Position.create(user_id: user_id, group_id: group_id, lat: lat, lng: lng)
      reply_content(event, message_buttons_h('開民雷達', result_message, actions_a))
    end
  rescue
    reply_text(event, '🗽 附近尚無開民蹤影，趕快來當第一吧！')
  end
end

def handle_nearby lat, lng, origin_name
  my_lat = lat.to_s[0..4]
  my_lng = lng.to_s[0..5]
  my_store = Store.where("lat like ?", "#{my_lat}%").where("lng like ?", "#{my_lng}%")
  my_store.pluck(:name_sys).uniq[0..2] - [origin_name]
end

def handle_message(event, user_id, is_vip, group_id)
  origin_message = event.message['text']
  Talk.create(user_id: user_id, group_id: group_id, talk: origin_message)

  case event.type
  when Line::Bot::Event::MessageType::Location
    handle_location(event, user_id, group_id, event.message['latitude'], event.message['longitude'], '')

  when Line::Bot::Event::MessageType::Text
    suffixes = IO.readlines("data/keywords").map(&:chomp)
    skip_name = IO.readlines("data/top200_731a").map(&:chomp)

    m = origin_message.downcase.delete(" .。，,!！?？\t\r\n").chomp('嗎')
    name = m.chomp('有沒有開').chomp('開了沒').chomp('有開').chomp('開了').chomp('は開いていますか').chomp('現在')
    place = URI.escape(name)
    link = "#{GG_SEARCH_URL}#{place}"

    if ( m.end_with?('附近') || m.start_with?('附近') && !group_id)
      reply_text(event, '請先查詢要去的地點【有開嗎】？若有營業資訊，則可以點選【🎐 附近】偷瞄開民們的口袋名單囉！')

    elsif (m.to_i > 0) && !group_id
      place = Store.where(info: user_id).last
      place_info = [place.place_id, place.name_sys]
      reply_content(event, number_to_cost_h(user_id, place_info, m)) if place

    elsif ( (origin_message.split("\n").count > 1) && !group_id )
      store_name = origin_message.split("\n")[0]
      Offer.create(user_id: user_id, store_name: store_name, info: origin_message.split("\n")[1..-1].join("\n"))
      reply_text(event, "已將【#{store_name}】情報收錄，感謝提供！")

    elsif (is_tndcsc? m)
      m = '北運'
      message = count_exercise m
      reply_text(event, message)

    elsif (is_cyc? m)
      message = count_exercise m
      reply_text(event, message)

    elsif name.end_with?('口袋有洞')
      pocket = Pocket.where(user_id: user_id).pluck(:place_name).uniq.shuffle[-4..-1]
      if pocket
        actions_a = pocket.map { |p|
          {label: "📍 #{p}", type: 'uri', uri: "#{GG_SEARCH_URL}#{URI.escape(p)}"}
        }
        reply_content( event, message_buttons_h('口袋有洞', '裡頭掉出了...', actions_a) )
      else
        reply_text(event, '口袋裡目前空空，請先問完要去的店有開嗎後，再將想要的結果放口袋~')
      end

    elsif name.end_with?('放口袋~')
      message = if is_vip
        Pocket.create(user_id: user_id, place_name: name.chomp('放口袋~'))
        "👜 已將#{name}"
      else
        '🥇 邀請有開嗎至任一群組，並成功問到一家有開的店，即能啟用放口袋功能'
      end
      reply_text(event, message)

    elsif (name.bytesize > 30 && !group_id)
      Idea.create(user_id: user_id, content: m)
      reply_text(event, '感謝你提供建議，【有開嗎】因你的回饋將變得更好！')

    elsif (m.end_with?(*suffixes) || !group_id) && (name != '')
      in_offer = Offer.where("store_name like ?", "%#{name}%")
      unless in_offer.empty?
        offer_at = in_offer.last.created_at.strftime('%m/%d')
        offer_at = (Date.today.strftime('%m/%d') == offer_at) ? '-今天' : "-#{offer_at}"
        offer_info = "\n💁 #{in_offer.last.info[0..50]}#{offer_at}"
      end
      s_link = %x(ruby bin/bitly.rb '#{link}').chomp

      level_up_button = { label: '👜 放口袋', type: 'message', text: "#{name}放口袋~" }

      random_info = [0, 1, 2].sample
      suggest_button = case random_info
      when 0
        { label: '👍 推薦', type: 'uri', uri: L_RECOMMEND_URI}
      when 1
        { label: '💡 建議', type: 'uri', uri: L_OPINION_URI }
      when 2
        { label: '👼 贊助', type: 'uri', uri: L_SPONSOR_URI }
      end

      if name == '麥當勞中港四店'
        message_buttons_text = '😃 現在有開'
      elsif name == '鬼門'
        message_buttons_text = ( (Date.today < Date.new(2018,8,10)) && (Date.today > Date.new(2018,9,9)) ) ? '👻 現在沒開' : '👻👻👻 現在正開'
      elsif user_id && (!skip_name.include? name)
        nickname = Nickname.find_by(nickname: name)
        if nickname
          place_id = nickname.place_id
        else
          place_url = "#{GG_FIND_URL}?input=#{place}&inputtype=textquery&language=zh-TW&fields=place_id,name&key=#{GMAP_KEY}"
          place_doc = JSON.parse(open(place_url).read, headers: true)
          place_id = place_doc['candidates'][0]['place_id'] if place_doc['candidates'][0]
        end

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

              message_buttons_text = if (is_cyc? name)
                "#{opening_hours}\n#{count_exercise name}"
              elsif is_tndcsc? name
                "#{opening_hours}\n#{count_exercise '北運'}"
              elsif is_tpsc? name
                "#{opening_hours}\n#{p_tp_count name}"
              else
                # {"message":"must not be longer than 60 characters","property":"template/text"}
                in_offer.empty? ? opening_hours : "#{opening_hours}#{offer_info}"
              end

              nearby_button = { label: '🎐 附近', type: 'postback', data: "#{place_id}nearby" }

              if user_id && group_id && !is_vip
                message = [
                  "【#{name}】#{opening_hours}",
                  add_vip(event, user_id, group_id, opening_hours),
                ]
                reply_text(event, message)
              end
            else
              message_buttons_text = '😬 請見詳情'
            end

            Nickname.create(
              place_id: place_id,
              place_name: name_sys,
              nickname: name
            ) unless nickname

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
            place_name_glink = %x(ruby bin/bitly.rb '#{GG_SEARCH_URL}#{URI.escape(name_sys)}').chomp
            place = Place.find_by(place_id: place_id)
            if place
              place.update(
                place_id: place_id,
                place_name: name_sys,
                address_components: address_components,
                formatted_address: formatted_address,
                lat: lat,
                lng: lng,
                place_types: place_types,
                weekday_text: weekday_text,
                periods: periods,
                place_name_glink: place_name_glink
              )
            else
              Place.create(
                place_id: place_id,
                place_name: name_sys,
                address_components: address_components,
                formatted_address: formatted_address,
                lat: lat,
                lng: lng,
                place_types: place_types,
                weekday_text: weekday_text,
                periods: periods,
                place_name_glink: place_name_glink
              )
            end
          else
            message_buttons_text = "⏰ 請見詳情#{offer_info}"
          end
        rescue
          message_buttons_text = "😂 請見詳情#{offer_info}"
        end
      else
        message_buttons_text = "🤔 請見詳情#{offer_info}"
      end

      actions_a = [
        { label: '📍 詳情', type: 'uri', uri: s_link },
        nearby_button,
        suggest_button,
        level_up_button,
      ].compact

      reply_content(event, message_buttons_h(name, message_buttons_text, actions_a))
    elsif !group_id
      reply_text(event, IO.readlines("data/intro").map(&:chomp))

    end
  end
end

def message_buttons_h title, text, actions
  {
    type: 'template',
    thumbnailImageUrl: '',
    altText: '...',
    template: {
      type: 'buttons',
      title: title,
      text: text,
      actions: actions,
    }
  }
end

def add_vip(event, user_id, group_id, opening_hours)
  Vip.create(user_id: user_id, group_id: (group_id || 'sponsor'))
  "#{user_name user_id}#{IO.readlines("data/promote_check").join}"
end

def user_name id
  JSON.parse(client.get_profile(id).read_body)['displayName']
end

def count_exercise m
  if ['福賴好運', '台中運'].include? m
    "【北區】#{p_tndcsc_count}     【朝馬】#{p_tndcsc_count['swim'][0]}/#{p_tndcsc_count['swim'][1]} 🏊 #{p_tndcsc_count['gym'][0]}/#{p_tndcsc_count['gym'][1]} 💪 快來減脂增肌！"
  elsif m == '北運'
    "#{p_tndcsc_count} 快來減脂增肌！"
  else
    ice=''
    j = case m
    when '朝運', '朝馬運動中心', '朝馬國民運動中心'
      cyc_j '朝運'
    when '桃運', '桃園運動中心', '桃園國民運動中心'
      cyc_j '桃運'
    when '永運', '永和運動中心', '永和國民運動中心'
      cyc_j '永運'
    when '蘆運', '蘆洲運動中心', '蘆洲國民運動中心'
      cyc_j '蘆運'
    when '土運', '土城運動中心', '土城國民運動中心'
      i = cyc_j '土運'
      ice = " 🍧 #{i['ice'][0]}/#{i['ice'][1]}"
      i
    when '汐運', '汐止運動中心', '汐止國民運動中心'
      cyc_j '汐運'
    end
    "🏊 #{j['swim'][0]}/#{j['swim'][1]}\n💪 #{j['gym'][0]}/#{j['gym'][1]}#{ice}"
  end
end

def p_tndcsc_count
  tndcsc_count = ''
  tndcsc_url = 'http://tndcsc.com.tw/'
  tndcsc_doc = Nokogiri::HTML(open(tndcsc_url))
  tndcsc_doc.css('.w3_agile_logo p').each_with_index do |l, index|
    tndcsc_count += (" #{l.content}".split.map{|x| x[/\d+/]}[0] + (index==0 ? '/350 🏊 ' : '/130 💪'))
  end
  tndcsc_count
end

def cyc_j m
  case m
  when '桃運'
    cyc_domain = 'tycsc'
  when '朝運'
    cyc_domain = 'cmcsc'
  when '永運'
    cyc_domain = 'yhcsc'
  when '蘆運'
    cyc_domain = 'lzcsc'
  when '土運'
    cyc_domain = 'tccsc'
  when '汐運'
    cyc_domain = 'xzcsc'
  end
  JSON.parse(open("https://#{cyc_domain}.cyc.org.tw/api").read, headers: true)
end

class String
  def string_between_markers marker1, marker2
    self[/#{Regexp.escape(marker1)}(.*?)#{Regexp.escape(marker2)}/m, 1]
  end
end

def render_html
  yy = to_model params['yy']
  @datas = yy.last(100).reverse

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
                <td><%= v if (v.to_s.length < 20) %></td>
              <% end %>
            </tr>
          <% end %>
        </tbody>
      </table>
    </body>
  </html>
  EOF
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

def download_csv
  content_type 'application/octet-stream'
  CSV.generate do |csv|
    yy = to_model params['yy']
    csv << yy.attribute_names
    yy.all.each do |user|
      csv << user.attributes.values
    end
  end
end

def is_tndcsc? name
  ['北運', '北區運動中心', '北區國民運動中心', '台中市北區國民運動中心'].include? name
end

def is_cyc? name
  ['朝運', '朝馬運動中心', '朝馬國民運動中心', '台中市朝馬國民運動中心', '桃運', '桃園運動中心', '桃園國民運動中心','永運', '永和運動中心', '永和國民運動中心','蘆運', '蘆洲運動中心', '蘆洲國民運動中心','土運', '土城運動中心', '土城國民運動中心','汐運', '汐止運動中心', '汐止國民運動中心'].include? name
end

def is_tpsc? name
  ['北投運動中心', '大安運動中心', '大同運動中心', '中正運動中心', '南港運動中心', '內湖運動中心', '士林運動中心', '文山運動中心', '信義運動中心', '中山運動中心'].include? name
end

def number_to_cost_h user_id, place_info, cost
  {
    type: 'template',
    altText: 'Confirm alt text',
    template: {
      type: 'confirm',
      text: "確認在#{place_info[1]}花了#{cost}元？",
      actions: [
        { label: '是的', type: 'postback', data: "book/#{user_id}/#{place_info[0]}/#{place_info[1]}/#{cost}"},
        { label: '沒有', type: 'postback', data: '沒有' },
      ],
    }
  }
end

def p_tp_count name
  a = %x(curl 'http://booking.tpsc.sporetrofit.com/Home/loadLocationPeopleNum' -XPOST -H 'Host: booking.tpsc.sporetrofit.com' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.13; rv:61.0) Gecko/20100101 Firefox/61.0' -H 'Accept: */*' -H 'Accept-Language: en-US,en;q=0.5' -H 'Accept-Encoding: gzip, deflate' -H 'Referer: http://booking.tpsc.sporetrofit.com/Home/LocationPeopleNum' -H 'X-Requested-With: XMLHttpRequest' -H 'Cookie: _culture=zh-TW' -H 'Connection: keep-alive' -H 'Content-Length: 0')
  b = JSON.parse(a)['locationPeopleNums']
  c = b.select {|h1| h1['lidName']=="#{name}"}.first
  "🏊 #{c['swPeopleNum']} / #{c['swMaxPeopleNum']} \n💪 #{c['gymPeopleNum']} / #{c['gymMaxPeopleNum']} "
end

def to_model yy
  [Book, Group, Idea, Nickname, Place, Pocket, Position, Offer, Store, Talk, Vip].find { |c| c.to_s == yy }
end

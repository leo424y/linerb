def handle_text_basic event, user_id, group_id, m, name, name_uri, link, origin_message
  skip_name = IO.readlines("data/top200_731a").map(&:chomp)
  s_link = %x(ruby bin/bitly.rb '#{link}').chomp
  point = (group_id ? 4 : 1)
  offer_info = offer_info_s name

  if name == '麥當勞中港四店'
    message_buttons_text = '😃 現在有開'
  elsif name == '鬼門'
    message_buttons_text = ( (Date.today < Date.new(2018,8,10)) && (Date.today > Date.new(2018,9,9)) ) ? '👻 現在沒開' : '👻👻👻 現在正開'
  elsif user_id && (!skip_name.include? name)
    nickname = Nickname.find_by(nickname: name)
    place_id = handle_place_id name, name_uri, nickname
    handle_review place_id

    begin
      unless place_id.nil?
        place = Place.find_by(place_id: place_id)

        place_id_url = "#{GG_DETAIL}?placeid=#{place_id}&language=zh-TW&fields=name,type,address_component,geometry,opening_hours,formatted_address&key=#{GMAP_KEY}"
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
          point = point + 1 if is_open_now
          opening_hours = is_open_now ? "😃 現在有開" : "🔴 現在沒開"

          message_buttons_text = if_message_buttons_text name, opening_hours, offer_info
          reply_join_vip_info(name, opening_hours) if user_id && group_id && !(is_vip user_id)
        else
          message_buttons_text = '😬 無營業時間資訊，請見詳情'
        end

        Nickname.create(place_id: place_id, place_name: name_sys, nickname: name) unless nickname

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
        control_place user_id, group_id, place, place_id, name_sys, address_components, formatted_address, lat, lng, place_types, weekday_text, periods
      else
        message_buttons_text = "⏰ 有多個結果或查無，請附上分店地區#{offer_info}"
      end
    rescue => exception
      p exception.backtrace
      message_buttons_text = "😂 請見詳情#{offer_info}"
    end
  else
    message_buttons_text = "🤔 有多個結果，請附上分店地區#{offer_info}"
  end

  add_point user_id, group_id, point
  reply_content event, message_buttons_h(name, message_buttons_text, (handle_button place_id, name, s_link, group_id))
end

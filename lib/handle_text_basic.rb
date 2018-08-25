def handle_text_basic event, user_id, group_id, suffixes, skip_name, m, name, name_uri, link, origin_message
  point = 0
  in_offer = Offer.where("store_name like ?", "%#{name}%")
  s_link = %x(ruby bin/bitly.rb '#{link}').chomp

  unless in_offer.empty?
    offer_at = in_offer.last.created_at.strftime('%m/%d')
    offer_at = (Date.today.strftime('%m/%d') == offer_at) ? '-今天' : "-#{offer_at}"
    offer_info = "\n💁 #{in_offer.last.info[0..50]}#{offer_at}"
  end

  if name == '麥當勞中港四店'
    message_buttons_text = '😃 現在有開'
  elsif name == '鬼門'
    message_buttons_text = ( (Date.today < Date.new(2018,8,10)) && (Date.today > Date.new(2018,9,9)) ) ? '👻 現在沒開' : '👻👻👻 現在正開'
  elsif user_id && (!skip_name.include? name)
    point = (group_id ? 3 : 1)

    nickname = Nickname.find_by(nickname: name)
    place_id = handle_place_id name, name_uri, nickname
    handle_review place_id

    begin
      unless place_id.nil?
        place = Place.find_by(place_id: place_id)

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
          if is_open_now
            add_point user_id, group_id, (point+1)
            opening_hours = "😃 現在有開"
          else
            opening_hours = "🔴 現在沒開"
          end
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

          if user_id && group_id && !(is_vip user_id)
            message = [
              "【#{name}】#{opening_hours}",
              add_vip(event, user_id, group_id, opening_hours),
            ]
            reply_text event, message
          end
        else
          message_buttons_text = '😬 請見詳情'
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
        control_place place, place_id, name_sys, address_components, formatted_address, lat, lng, place_types, weekday_text, periods
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

  reply_content event, message_buttons_h(name, message_buttons_text, (handle_button place_id, name, s_link))
end

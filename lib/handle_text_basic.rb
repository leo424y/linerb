def handle_text_basic event, user_id, group_id, suffixes, skip_name, m, name, name_uri, link, origin_message
  in_offer = Offer.where("store_name like ?", "%#{name}%")
  unless in_offer.empty?
    offer_at = in_offer.last.created_at.strftime('%m/%d')
    offer_at = (Date.today.strftime('%m/%d') == offer_at) ? '-今天' : "-#{offer_at}"
    offer_info = "\n💁 #{in_offer.last.info[0..50]}#{offer_at}"
  end
  s_link = %x(ruby bin/bitly.rb '#{link}').chomp

  level_up_button = { label: '👜 放口袋', type: 'message', text: "#{name}放口袋~" }

  if name == '麥當勞中港四店'
    message_buttons_text = '😃 現在有開'
  elsif name == '鬼門'
    message_buttons_text = ( (Date.today < Date.new(2018,8,10)) && (Date.today > Date.new(2018,9,9)) ) ? '👻 現在沒開' : '👻👻👻 現在正開'
  elsif user_id && (!skip_name.include? name)
    place_id = handle_place_id name, name_uri
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
        create_place place, place_id, name_sys, address_components, formatted_address, lat, lng, place_types, weekday_text, periods
      else
        message_buttons_text = "⏰ 有多個結果或查無，請見詳情#{offer_info}"
      end
    rescue => exception
      p exception.backtrace
      message_buttons_text = "😂 請見詳情#{offer_info}"
    end
  else
    message_buttons_text = "🤔 請見詳情#{offer_info}"
  end

  random_info = [0, 1, 2].sample
  suggest_button = case random_info
  when 0
    { label: '👍 推薦', type: 'uri', uri: L_RECOMMEND_URI}
  when 1
    { label: '💡 建議', type: 'uri', uri: L_OPINION_URI }
  when 2
    { label: '👼 贊助', type: 'uri', uri: L_SPONSOR_URI }
  end

  actions_a = [
    { label: '📍 詳情', type: 'uri', uri: s_link },
    nearby_button,
    suggest_button,
    level_up_button,
  ].compact

  reply_content event, message_buttons_h(name, message_buttons_text, actions_a)
end

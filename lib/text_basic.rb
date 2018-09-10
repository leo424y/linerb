def handle_text_basic event, user_id, group_id, name, origin_message
  skip_name = IO.readlines("data/top200_731a").map(&:chomp)
  name_uri = URI.escape(name)
  s_link = %x(ruby bin/bitly.rb "#{GG_SEARCH}#{name_uri}").chomp
  point = (group_id ? 4 : 1)
  offer_info = offer_info_s name

  if name == '麥當勞中港四店'
    message_buttons_text = '😃 現在有開'
  elsif name == '鬼門'
    message_buttons_text = ( (Date.today < Date.new(2018,8,10)) && (Date.today > Date.new(2018,9,9)) ) ? '👻 現在沒開' : '👻👻👻 現在正開'
  elsif user_id && (!skip_name.include? name)
    nickname = Nickname.find_by(nickname: name)
    place_id = handle_place_id name, name_uri, nickname

    begin
      unless place_id.nil?
        r = google_place_by place_id
        control_place user_id, group_id, place_id, r

        if !(/(運動中心)/.match? name) && (r[:open_now] && (r[:open_now].to_s == 'true' || r[:open_now].to_s == 'false'))
          point = point + 1 if r[:open_now].to_s == 'true'
          opening_hour_info = (r[:open_now].to_s == 'true') ? "😃 現在有開" : "🔴 現在沒開"

          message_buttons_text = if_message_buttons_text name, opening_hour_info, offer_info
          reply_join_vip_info(name, opening_hour_info) if user_id && group_id && !(is_vip user_id)

          handle_review place_id
        else
          message_buttons_text = '😬 請見詳情'
        end

        Nickname.create(place_id: place_id, place_name: r[:name_sys], nickname: name) unless nickname

        Store.create(
          name: name,
          info: user_id,
          group_id: group_id,
          place_id: place_id,
          s_link: s_link,
          opening_hours: (r[:open_now].to_s == 'true' || r[:open_now].to_s == 'false') ? r[:open_now].to_s : 'no',
          name_sys: r[:name_sys],
          address_components: r[:address_components],
          formatted_address: r[:formatted_address],
          lat: r[:lat],
          lng: r[:lng],
          place_types: r[:place_types],
          weekday_text: r[:weekday_text],
          periods: r[:periods],
        )
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
  reply_content event, message_buttons_h(name, message_buttons_text, (handle_button place_id, name, s_link, group_id, user_id))
end

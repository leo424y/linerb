def handle_text_end_with event, user_id, group_id, origin_message, name
  case origin_message.delete(name)
  when '附近'
    nickname = Nickname.find_by(nickname: origin_message.chomp('附近'))
    my_place = Place.find_by(place_id: nickname.place_id) if nickname
    if my_place
      handle_location(event, user_id, group_id, my_place.lat, my_place.lng, my_place.place_name)
    else
      reply_text event, "請先搜尋想去的地點+有開嗎，即可取得附近的好去處！"
    end

  when '推薦有開嗎'
    if !group_id
      user_display_name = origin_message.chomp('推薦有開嗎')
      boom_user = User.find_by(display_name: user_display_name)
      boom = Boom.find_by(user_id: user_id, boom_user_id: boom_user.user_id) if boom_user
      if boom
        reply_text event, "已推薦過"
      else
        add_boom_point boom_user.user_id, group_id, 10
        Boom.create(user_id: user_id, boom_user_id: boom_user.user_id)
        reply_text event, "#{origin_message}成功！歡迎來查查你心目中的好店"
      end
    end
  when '放口袋'
    # reply_text(event, (handle_pocket user_id, name))
    reply_content(event, message_buttons_h('放口袋', (handle_pocket user_id, name), [{ label: '📍 詳情', type: 'uri', uri: URI.escape(%x(ruby bin/bitly.rb "#{GG_SEARCH}#{name}").chomp) }]))
  when '里長'
    fathers = Father.where("name like ?", "%#{name}里")
    fathers.each do |father|
      text << "🏠 #{father.name}\n☎️ 04#{father.phone}\n📍 #{%x(ruby bin/bitly.rb "#{GG_SEARCH}#{father.address}").chomp}"
    end
    reply_text(event, text)
  when '？！'
    text = wiki_content event, name
    reply_text(event, text) if text

  end
end

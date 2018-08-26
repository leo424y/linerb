def handle_text event, user_id, group_id, m, name, name_uri, link, origin_message
  suffixes = IO.readlines("data/keywords").map(&:chomp)

  if m.end_with?('附近')
    nickname = Nickname.find_by(nickname: m.chomp('附近'))
    store = Store.find_by(place_id: nickname.place_id) if nickname
    handle_location(event, user_id, group_id, store.lat, store.lng, store.name_sys) if store

  elsif origin_message.end_with?('推薦有開嗎') && !group_id
    user_display_name = origin_message.chomp('推薦有開嗎')
    boom_user = User.find_by(display_name: user_display_name)
    boom = Boom.find_by(user_id: user_id, boom_user_id: boom_user.user_id) if boom_user
    if boom
      reply_text event, "已推薦過"
    else
      add_boom_point boom_user.user_id, group_id, 10
      Boom.create(user_id: user_id, boom_user_id: boom_user.user_id)
      reply_text event, "#{origin_message}推薦你成功！歡迎來查查你心目中的好店"
    end

  elsif m.is_number? && !group_id
    place = Store.where(info: user_id).last
    place_info = [place.place_id, place.name_sys]
    reply_content(event, number_to_cost_h(user_id, place_info, m)) if place

  elsif ( (origin_message.split("\n").count > 1) && !group_id )
    store_name = origin_message.split("\n")[0]
    Offer.create(user_id: user_id, store_name: store_name, info: origin_message.split("\n")[1..-1].join("\n"))
    reply_text event, "已將【#{store_name}】情報收錄，感謝提供！"

  elsif (is_tndcsc? m)
    reply_text event, (count_exercise '北運')

  elsif (is_cyc? m)
    reply_text event, (count_exercise m)

  elsif name.end_with? '放口袋'
    reply_text(event, (handle_pocket user_id, name))

  elsif name == '口袋有洞'
    open_pocket event, user_id

  elsif name == '開王榜'
    reply_text event, list_king_user_names

  elsif (name.bytesize > 40 && !group_id)
    Idea.create(user_id: user_id, content: m)
    reply_text event, '感謝你提供建議，【有開嗎】因你的回饋將變得更好！'

  elsif (m.end_with?(*suffixes) || !group_id) && (name != '')
    handle_text_basic event, user_id, group_id, m, name, name_uri, link, origin_message

  elsif (origin_message == '有開嗎' || origin_message == '有開嗎指令') || !group_id
    reply_text event, IO.readlines("data/intro").map(&:chomp)

  end
end

def handle_text event, user_id, group_id, suffixes, skip_name, m, name, name_uri, link, origin_message
  if ( m.end_with?('附近') || m.start_with?('附近') && !group_id)
    reply_text(event, '請先查詢要去的地點【有開嗎】？若有營業資訊，則可以點選【🎐 附近】偷瞄開民們的口袋名單囉！')

  elsif (m.to_i > 0) && !group_id
    place = Store.where(info: user_id).last
    place_info = [place.place_id, place.name_sys]
    reply_content(event, number_to_cost_h(user_id, place_info, m)) if place

  elsif ( (origin_message.split("\n").count > 1) && !group_id )
    store_name = origin_message.split("\n")[0]
    Offer.create(user_id: user_id, store_name: store_name, info: origin_message.split("\n")[1..-1].join("\n"))
    reply_text event, "已將【#{store_name}】情報收錄，感謝提供！"

  elsif (is_tndcsc? m)
    reply_text(event, (count_exercise '北運'))

  elsif (is_cyc? m)
    reply_text(event, (count_exercise m))

  elsif name.end_with? '口袋有洞'
    open_pocket user_id

  elsif name.end_with? '放口袋~'
    reply_text(event, (handle_pocket user_id, name))

  elsif (name.bytesize > 30 && !group_id)
    Idea.create(user_id: user_id, content: m)
    reply_text event, '感謝你提供建議，【有開嗎】因你的回饋將變得更好！'

  elsif (m.end_with?(*suffixes) || !group_id) && (name != '')
    handle_text_basic event, user_id, group_id, suffixes, skip_name, m, name, name_uri, link, origin_message

  elsif !group_id
    reply_text event, IO.readlines("data/intro").map(&:chomp)

  end
end

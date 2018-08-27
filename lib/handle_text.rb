def handle_text event, user_id, group_id, origin_message
  suffixes = IO.readlines("data/keywords").map(&:chomp)
  clean_message = origin_message.downcase.delete(" .。，,?？\t\r\n")
  name = clean_message.chomp('嗎').chomp('有沒有開').chomp('開了沒').chomp('有開').chomp('開了').chomp('は開いていますか').chomp('現在')

  if ['附近','推薦有開嗎','放口袋'].include? origin_message.delete(name)
    handle_text_end_with event, user_id, group_id, origin_message, name

  elsif origin_message.is_number? && !group_id
    place = Store.where(info: user_id).last
    place_info = [place.place_id, place.name_sys]
    reply_content(event, number_to_cost_h(user_id, place_info, origin_message)) if place

  elsif ( (origin_message.split("\n").count > 1) && !group_id )
    store_name = origin_message.split("\n")[0]
    Offer.create(user_id: user_id, store_name: store_name, info: origin_message.split("\n")[1..-1].join("\n"))
    reply_text event, "已將【#{store_name}】情報收錄，感謝提供！"

  elsif (is_tndcsc? origin_message)
    reply_text event, (count_exercise '北運')

  elsif (is_cyc? origin_message)
    reply_text event, (count_exercise origin_message)

  elsif origin_message == '口袋有洞'
    open_pocket event, user_id

  elsif origin_message == '開王榜'
    reply_text event, list_king_user_names

  elsif (name.bytesize > 40 && !group_id)
    Idea.create(user_id: user_id, content: origin_message)
    reply_text event, '感謝你提供建議，【有開嗎】因你的回饋將變得更好！'

  elsif (clean_message.end_with?(*suffixes) || !group_id) && (name != '')
    handle_text_basic event, user_id, group_id, name, origin_message

  elsif (origin_message == '有開嗎' || origin_message == '有開嗎指令') || !group_id
    reply_text event, IO.readlines("data/intro").map(&:chomp)

  end
end

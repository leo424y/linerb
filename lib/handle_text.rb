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
    m = '北運'
    message = count_exercise m
    reply_text(event, message)

  elsif (is_cyc? m)
    message = count_exercise m
    reply_text(event, message)

  elsif name.end_with? '口袋有洞'
    pocket = Pocket.where(user_id: user_id).pluck(:place_name).uniq.shuffle[-4..-1]
    if pocket
      actions_a = pocket.map { |p|
        {label: "📍 #{p}", type: 'uri', uri: "#{GG_SEARCH_URL}#{URI.escape(p)}"}
      }
      reply_content( event, message_buttons_h('口袋有洞', '裡頭掉出了...', actions_a) )
    else
      reply_text(event, '口袋裡目前空空，請先問完要去的店有開嗎後，再將想要的結果放口袋~')
    end

  elsif name.end_with? '放口袋~'
    message = if (is_vip user_id)
      Pocket.create(user_id: user_id, place_name: name.chomp('放口袋~'))
      "👜 已將#{name}"
    else
      '🥇 試著在任何含【有開嗎】的群組內成功問到一家有開的店，即能啟用放口袋功能'
    end
    reply_text(event, message)

  elsif (name.bytesize > 30 && !group_id)
    Idea.create(user_id: user_id, content: m)
    reply_text event, '感謝你提供建議，【有開嗎】因你的回饋將變得更好！'

  elsif (m.end_with?(*suffixes) || !group_id) && (name != '')
    handle_text_basic event, user_id, group_id, suffixes, skip_name, m, name, name_uri, link, origin_message

  elsif !group_id
    reply_text event, IO.readlines("data/intro").map(&:chomp)

  end
end

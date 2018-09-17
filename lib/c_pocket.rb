def handle_pocket user_id, name
  # if (is_vip user_id)
  Pocket.create(user_id: user_id, place_name: name)
  "👜 已將#{name}放口袋"
  # else
  #   '🥇 請試著邀請【有開嗎】進入任何群組，並成功問到一家有開的店，即能啟用放口袋功能'
  # end
end

def open_pocket event, user_id
  pocket = Pocket.where(user_id: user_id).pluck(:place_name).uniq.shuffle[-4..-1]
  if pocket
    actions_a = pocket.map { |p|
      {label: "📍 #{p}", type: 'uri', uri: "#{GG_SEARCH}#{URI.escape(p)}"}
    }
    reply_content(event, message_buttons_h('口袋有洞', '裡頭掉出了...', actions_a) )
  else
    reply_text(event, '口袋裡目前空空，請先問完要去的店有開嗎後，再將想要的結果放口袋')
  end
end

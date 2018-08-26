def handle_button place_id, name, s_link
  random_info = [0, 1, 2, 3, 4].sample
  suggest_button = case random_info
  when 0
    { label: '👍 推薦', type: 'uri', uri: L_RECOMMEND_URI}
  when 1
    { label: '💡 建議', type: 'uri', uri: L_OPINION_URI }
  when 2
    { label: '👼 贊助', type: 'uri', uri: L_SPONSOR_URI }
  when 3, 4
    { label: "👑 開王：#{name_king_user}", type: 'message', text: "開王榜" }
  end

  nearby_button = if place_id
    { label: "💁 #{name}附近", type: 'message', text: "#{name}附近" }
  else
    { label: '💁 我附近', type: 'uri', uri: "#{L_LOCATION_URI}" }
  end
  level_up_button = { label: "👜 #{name}放口袋", type: 'message', text: "#{name}放口袋" }

  [
    { label: '📍 詳情', type: 'uri', uri: s_link },
    nearby_button,
    suggest_button,
    level_up_button,
  ].compact
end

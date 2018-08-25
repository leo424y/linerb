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
    king_users = User.order(points: :desc).pluck(:user_id)[1..21]
    king_user_names = king_users.map do |n|
      king_user_name = "#{user_name n}"
      king_user_name unless king_user_name.empty?
    end.compact[0..9].map.with_index{|k,i| i==0 ? "#{k} 👑": "#{k}"}.join("\n")
    { label: "👑 開王：#{king_user_names.split(' ')[0]}", type: 'postback', data: "【開王榜】\n\n#{king_user_names}\n\n趕緊來發揮你的專家雷達，查詢少人知道的好店！" }
  end

  nearby_button = if place_id
    { label: "💁 #{name}附近", type: 'postback', data: "#{place_id}nearby" }
  else
    { label: '💁 我附近', type: 'uri', data: "#{L_LOCATION_URI}" }
  end
  level_up_button = { label: '👜 放口袋', type: 'message', text: "#{name}放口袋~" }

  [
    { label: '📍 詳情', type: 'uri', uri: s_link },
    nearby_button,
    suggest_button,
    level_up_button,
  ].compact
end

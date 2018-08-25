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
    king_users = User.order(points: :desc).pluck(:user_id)[1..15]
    king_user_name = king_users.map do |n|
      name = "#{user_info n}"
      name unless name.empty?
    end.compact[0..10].map.with_index{|k,i| i==0 ? "#{k} 👑": "#{k}"}.join("\n")
    { label: "👑 開王：#{king_user_name.split(' ')[0]}", type: 'postback', data: "【開王榜】\n\n#{king_user_name}\n\n趕緊來發揮你的專家雷達，查詢少人知道的好店！" }
  end

  nearby_button = { label: '🎐 附近', type: 'postback', data: "#{place_id}nearby" } if place_id
  level_up_button = { label: '👜 放口袋', type: 'message', text: "#{name}放口袋~" }

  [
    { label: '📍 詳情', type: 'uri', uri: s_link },
    nearby_button,
    suggest_button,
    level_up_button,
  ].compact
end

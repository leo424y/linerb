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
    king_users = User.order(points: :desc).pluck(:user_id)[1..10]
    king_user_name = king_users.map do |n|
      user_name n
    end.compact.map.with_index{|k,i| i==0 ? "👑 #{k}": "#{k}"}.join("\n")
    { label: '👑 名人堂', type: 'postback', data: "#{king_user_name}" }
  end

  nearby_button = { label: '🎐 附近', type: 'postback', data: "#{place_id}nearby" }
  level_up_button = { label: '👜 放口袋', type: 'message', text: "#{name}放口袋~" }

  [
    { label: '📍 詳情', type: 'uri', uri: s_link },
    nearby_button,
    suggest_button,
    level_up_button,
  ].compact
end

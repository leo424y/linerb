def handle_location(event, user_id, group_id, lat, lng, origin_name)
  begin
    results = handle_nearby(lat, lng, origin_name)
    result_message = results.empty? ? "🗽 附近尚無開民蹤影，趕快來當第一吧！" : "🎐 附近開民怕落空的地點有..."
    actions_a = results.map { |r|
      { label: "📍 #{r}" , type: 'message', text: "#{r}有開嗎？" }
    }.compact
    if actions_a.empty?
      reply_text(event, '🗽 附近尚無開民蹤影，趕快來當第一吧！')
    else
      Position.create(user_id: user_id, group_id: group_id, lat: lat, lng: lng)
      reply_content(event, message_buttons_h('開民雷達', result_message, actions_a))
    end
  rescue
    reply_text(event, '🗽 附近尚無開民蹤影，趕快來當第一吧！')
  end
end

def handle_nearby lat, lng, origin_name
  my_lat = lat.to_s[0..4]
  my_lng = lng.to_s[0..5]
  my_store = Store.where("lat like ?", "#{my_lat}%").where("lng like ?", "#{my_lng}%")
  my_store.pluck(:name_sys).uniq[0..2] - [origin_name]
end

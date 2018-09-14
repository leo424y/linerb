def handle_button place_id, name, s_link, group_id, user_id
  random_info = [0, 1].sample
  # share_info_url = "#{L_DM}#{name_user user_id}推薦有開嗎"
  share_info_url = "#{L_DM}麥當勞中港四店有開嗎？"

  suggest_button = case random_info
  when 0
    { label: '👍 推薦', type: 'uri', uri: "#{L_MSG_TEXT}加有開嗎好友，查詢店家營業時間不落空。#{share_info_url}"}

    # if group_id
    #   { label: '👍 推薦', type: 'uri', uri: "#{L_MSG_TEXT}加【有開嗎】好友，查詢店家營業時間不落空。#{share_info_url}"}
    # else
    #   { label: '📖 指令', type: 'uri', uri: L_DM_DEMO}
    # end
  when 1
    if group_id
      { label: '💡 建議', type: 'uri', uri: L_OPINION }
    else
      { label: '👼 贊助', type: 'uri', uri: L_SPONSOR }
    end
  # when 2
  #   { label: "👑 開王：#{name_king_user}", type: 'message', text: "開王榜" }
  end

  nearby_button = if place_id
    { label: "💁 #{name}附近", type: 'message', text: "#{name}附近" }
  else
    { label: '💁 我附近', type: 'uri', uri: L_LOCATION }
  end

  level_up_button = if group_id
    { label: '⭐ 使用有開嗎', type: 'uri', uri: "#{share_info_url}"}
  else
    { label: "👜 #{name}放口袋", type: 'message', text: "#{name}放口袋" }
  end

  [
    { label: '📍 詳情', type: 'uri', uri: s_link },
    nearby_button,
    suggest_button,
    level_up_button,
  ].compact
end

def message_buttons_h title, text, actions
  # imageAspectRatio: rectangle / square
  # thumbnailImageUrl: "#{to_thumbnail_url title}",
  # imageAspectRatio: 'square',

  my_hash = {
    type: 'template',
    altText: '...',
    template: {
      type: 'buttons',
      title: title,
      text: text,
      actions: actions,
    }
  }
end

def to_thumbnail_url title
  case title
  when '口袋有洞'
    "#{MY_DOMAIN}/img/kai.png"
  else
    ''
  end
end

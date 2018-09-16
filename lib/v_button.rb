def handle_button place_id, name, s_link, group_id, user_id
  random_info = [0, 1].sample
  # share_info_url = "#{L_DM}#{name_user user_id}推薦有開嗎"
  share_info_url = "#{L_DM}#{name}有開嗎？"

  suggest_button = case random_info
  when 0
    { label: "👨‍👩‍👧‍👦 轉傳#{name}" , type: 'uri', uri: URI.escape(
"#{L_MSG_TEXT}加有開嗎好友，查詢店家營業時間不落空。#{share_info_url}")}

    # if group_id
    #   { label: '👍 推薦', type: 'uri', uri: "#{L_MSG_TEXT}加【有開嗎】好友，查詢店家營業時間不落空。#{share_info_url}"}
    # else
    #   { label: '📖 指令', type: 'uri', uri: L_DM_DEMO}
    # end
  when 1
    if group_id
      { label: '💡 建議', type: 'uri', uri: URI.escape(L_OPINION) }
    else
      { label: '👼 贊助', type: 'uri', uri: URI.escape(L_SPONSOR) }
    end
  # when 2
  #   { label: "👑 開王：#{name_king_user}", type: 'message', text: "開王榜" }
  end

  nearby_button = if place_id
    { label: "💁 探索#{name}附近", type: 'message', text: "#{name}附近" }
  else
    { label: '💁 我附近', type: 'uri', uri: URI.escape(L_LOCATION) }
  end

  level_up_button = if group_id
    { label: '⭐ 使用有開嗎', type: 'uri', uri: URI.escape("#{share_info_url}")}
  else
    { label: "👜 收藏#{name}", type: 'message', text: "#{name}放口袋" }
  end

  [
    { label: '📍 詳情', type: 'uri', uri: URI.escape(s_link) },
    nearby_button,
    suggest_button,
    level_up_button,
  ].compact
end

def message_buttons_h title, text, actions, open_close = '0'
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
  add_thumbnail_url title, my_hash, open_close
end

def add_thumbnail_url title, my_hash, open_close
  image_url = case title
  when '口袋有洞'
    "#{MY_DOMAIN}/img/meow007.png"
  when '開民雷達'
    "#{MY_DOMAIN}/img/meow008.png"
  else
    [
      "#{MY_DOMAIN}/img/meow001.png",
      "#{MY_DOMAIN}/img/meow002.png"
    ].sample(1)[0]
  end

  if open_close.match?(/現在有開/)
    "#{MY_DOMAIN}/img/meow003.png"
  elsif open_close.match?(/現在沒開/)
    "#{MY_DOMAIN}/img/meow004.png"
  elsif open_close.match?(/請見詳情/)
    "#{MY_DOMAIN}/img/meow005.png"
  end

  # if ['口袋有洞'].include? title
  my_hash[:template][:thumbnailImageUrl] = image_url
  my_hash[:template][:imageAspectRatio] = 'rectangle'
  # end

  my_hash
end

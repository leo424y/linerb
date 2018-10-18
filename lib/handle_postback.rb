def handle_postback event, user_id, group_id
  data = event['postback']['data']
  if data.split('/')[0] == 'book'
    Book.create(user_id: data.split('/')[1], place_id: data.split('/')[2], cost: data.split('/')[4])
    reply_text(event, "已新增你在#{data.split('/')[3]}的消費#{data.split('/')[4]}元")
  # elsif data[0] == 'game'
  #   Game.find_by(id: data[1]).update(
  #     info: data[3]
  #   )
  #   reply_content(event, message_buttons_h(
  #     "#{place_name}團", '來加一吧！',
  #     [
  #       { label: '☝️ 加一', type: 'message', text: "#{data[2]}+1" },
  #     ]))
  else
    reply_text(event, data)
  end
end

def handle_text_start_with event, user_id, group_id, origin_message, name
  case origin_message.gsub(name, "")
  when '揪'
    nickname = Nickname.find_by(nickname: origin_message[1..-1])
    my_place = Place.find_by(place_id: nickname.place_id) if nickname
    if my_place
      new_game(event, user_id, group_id, my_place.place_name)
    else
      reply_text event, "請先搜尋想去的地點+有開嗎！"
    end
  end
end

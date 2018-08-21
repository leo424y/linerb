def handle_message(event, user_id, group_id)
  origin_message = event.message['text']
  Talk.create(user_id: user_id, group_id: group_id, talk: origin_message)

  case event.type
  when Line::Bot::Event::MessageType::Location
    handle_location(event, user_id, group_id, event.message['latitude'], event.message['longitude'], '')

  when Line::Bot::Event::MessageType::Text
    suffixes = IO.readlines("data/keywords").map(&:chomp)
    skip_name = IO.readlines("data/top200_731a").map(&:chomp)

    m = origin_message.downcase.delete(" .。，,!！?？\t\r\n").chomp('嗎')
    name = m.chomp('有沒有開').chomp('開了沒').chomp('有開').chomp('開了').chomp('は開いていますか').chomp('現在')
    name_uri = URI.escape(name)
    link = "#{GG_SEARCH_URL}#{name_uri}"

    handle_text suffixes, skip_name, m, name, name_uri, link
  end
end

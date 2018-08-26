def handle_message event, user_id, group_id
  origin_message = event.message['text']
  Talk.create(user_id: user_id, group_id: group_id, talk: origin_message)

  case event.type
  when Line::Bot::Event::MessageType::Sticker
    # handle_sticker(event) unless group_id

  when Line::Bot::Event::MessageType::Location
    handle_location(event, user_id, group_id, event.message['latitude'], event.message['longitude'], '')

  when Line::Bot::Event::MessageType::Text
    m = origin_message.downcase.delete(" .。，,?？\t\r\n").chomp('嗎')
    name = m.chomp('有沒有開').chomp('開了沒').chomp('有開').chomp('開了').chomp('は開いていますか').chomp('現在')
    name_uri = URI.escape(name)
    link = "#{GG_SEARCH_URL}#{name_uri}"

    handle_text event, user_id, group_id, m, name, name_uri, link, origin_message
  end
end

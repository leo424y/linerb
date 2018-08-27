def handle_message event, user_id, group_id
  origin_message = event.message['text']
  Talk.create(user_id: user_id, group_id: group_id, talk: origin_message)

  case event.type
  when Line::Bot::Event::MessageType::Sticker
    # handle_sticker(event) unless group_id

  when Line::Bot::Event::MessageType::Location
    handle_location(event, user_id, group_id, event.message['latitude'], event.message['longitude'], '')

  when Line::Bot::Event::MessageType::Text
    handle_text event, user_id, group_id, origin_message
  end
end

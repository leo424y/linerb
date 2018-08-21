def handle_event event, user_id, group_id
  group = Group.find_by(group_id: group_id)
  
  case event
  when Line::Bot::Event::Join
    Group.create(group_id: group_id, status: 'join')
    reply_text(event, IO.readlines("data/join").map(&:chomp))

  when Line::Bot::Event::Leave
    group.update(status: 'leave')

  when Line::Bot::Event::Postback
    handle_postback event['postback']['data']

  when Line::Bot::Event::Message
    Group.create(group_id: group_id, status: 'join') unless group
    handle_message event, user_id, group_id
  end
end

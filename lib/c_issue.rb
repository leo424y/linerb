def open_issue event, user_id, group_id, origin_message
  tag = origin_message.end_with?('意見') ? 'idea' : 'issue'
  issue = Issue.where(user_id: user_id, group_id: group_id, tag: tag).last(3).pluck(:title, :user_id)
  p issue
  if issue
    msgs = []
    issue.each do |p|
      msgs << "🙋 #{name_user p[1]}: #{p[0]}"
    end
    # actions_a = issue.map { |p|
    #   {label: "🙋 #{p[0][0..12]}...", type: 'uri', uri: "http://#{(p[1])}"}
    # }
    # reply_content(event, message_buttons_h(origin_message, '裡頭最新三則為', actions_a) )
    reply_text(event, msgs)
  else
    reply_text(event, '😶 居民尚無回應')
  end
end

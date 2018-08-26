def handle_sticker(event)
  # Message API available stickers
  # https://developers.line.me/media/messaging-api/sticker_list.pdf
  msgapi_available = event.message['packageId'].to_i <= 4
  messages = [{
    type: 'text',
    text: "[STICKER]\npackageId: #{event.message['packageId']}\nstickerId: #{event.message['stickerId']}"
  }]
  if msgapi_available
    messages.push(
      type: 'sticker',
      packageId: event.message['packageId'],
      stickerId: event.message['stickerId']
    )
  end
  reply_content(event, messages)
end

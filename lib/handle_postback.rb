def handle_postback event, user_id, group_id
  data = event['postback']['data']
  if data.end_with? 'nearby'
    place_id = data.chomp('nearby')
    store = Store.find_by(place_id: place_id)
    handle_location(event, user_id, group_id, store.lat, store.lng, store.name_sys)
  elsif data.split('/')[0] == 'book'
    Book.create(user_id: data.split('/')[1], place_id: data.split('/')[2], cost: data.split('/')[4])
    reply_text(event, "已新增你在#{data.split('/')[3]}的消費#{data.split('/')[4]}元")
  else
    reply_text(event, data)
  end
end

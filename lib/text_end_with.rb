def handle_text_end_with event, user_id, group_id, origin_message, name
  case origin_message.delete(name)
  when '附近'
    nickname = Nickname.find_by(nickname: origin_message.chomp('附近'))
    store = Store.find_by(place_id: nickname.place_id) if nickname
    if store
      handle_location(event, user_id, group_id, store.lat, store.lng, store.name_sys)
    else
      reply_text event, "請先搜尋想去的地點+有開嗎，即可取得附近的好去處！"
    end

  when '推薦有開嗎'
    if !group_id
      user_display_name = origin_message.chomp('推薦有開嗎')
      boom_user = User.find_by(display_name: user_display_name)
      boom = Boom.find_by(user_id: user_id, boom_user_id: boom_user.user_id) if boom_user
      if boom
        reply_text event, "已推薦過"
      else
        add_boom_point boom_user.user_id, group_id, 10
        Boom.create(user_id: user_id, boom_user_id: boom_user.user_id)
        reply_text event, "#{origin_message}成功！歡迎來查查你心目中的好店"
      end
    end
  when '放口袋'
    reply_text(event, (handle_pocket user_id, name))

  when '？！'
    wiki_data = wikir(name, 'zh')
    if wiki_data.text
      text = wiki_data.text.truncate(200) + %x(ruby bin/bitly.rb "#{wiki_data.fullurl}").chomp
      reply_text(event, text)
    end

  end
end

def wikir title, lang
  Wikipedia.configure {
    domain "#{lang}.wikipedia.org"
    path   'w/api.php'
  }
  Wikipedia.find(title)
end

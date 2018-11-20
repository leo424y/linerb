def handle_text_end_with event, user_id, group_id, origin_message, name
  case origin_message.gsub(name, "")
  when '附近'
    nickname = Nickname.find_by(nickname: origin_message.chomp('附近'))
    my_place = Place.find_by(place_id: nickname.place_id) if nickname
    if my_place
      handle_location(event, user_id, group_id, my_place.lat, my_place.lng, my_place.place_name)
    # else
    #   reply_text event, "請先搜尋想去的地點+有開嗎，即可取得附近的好去處！"
    end

  when '揪揪團'
    input = origin_message.chomp('揪揪團')
    new_game(event, user_id, group_id, input)

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
    # reply_text(event, (handle_pocket user_id, name))
    reply_content(event, message_buttons_h('放口袋', (handle_pocket user_id, name), [{ label: '📍 詳情', type: 'uri', uri: URI.escape(%x(ruby bin/bitly.rb "#{GG_SEARCH}#{name}").chomp) }]))
  when '里長'
    text = []
    fathers = Father.where("name like ?", "%#{name}里")
    fathers.each do |father|
      text << "🏠 #{father.name}\n☎️ 04#{father.phone}\n📍 #{%x(ruby bin/bitly.rb "#{GG_SEARCH}#{father.address}").chomp}"
    end
    reply_text(event, text)
  when '？！'
    text = wiki_content event, name
    reply_text(event, text) if text

  when '加加一'
    input = origin_message.chomp('加加一')

    game = Game.find_by(group_id: group_id, place_name: input)
    unless GameMember.find_by(game_id: game.id, user_id: user_id)
      GameMember.create(game_id: game.id, user_id: user_id)

      gamers = show_gamers user_id, group_id, game.id
      gamer_names = []
      gamers.each_with_index {|x, index| gamer_names << "#{name_user(x)}"}

      reply_game event, input, "\n+#{gamer_names.count}👫#{gamer_names.join(" ")} "
    end
    
  when 'ggl'
    input = origin_message.chomp('ggl')
    url = "http://www.google.com/search?q=#{URI.escape(input)}&btnI"
    text = %x(ruby bin/bitly.rb "#{url}").chomp
    reply_text(event, "Google [#{input}]\n#{text}") if text
  end
end

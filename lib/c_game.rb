def new_game event, user_id, group_id, place_name
  Game.create(
    user_id: user_id,
    group_id: group_id,
    place_name: place_name
  )
  reply_content(event, message_buttons_h(
    "#{place_name.truncate(10)}開團", '來加加一吧！',
    [
      { label: '☝️ ++1', type: 'message', text: "#{place_name}++1" },
      { label: '📍 位置', type: 'uri', uri: URI.escape("#{GG_SEARCH}#{place_name}") }
    ]))
end

def update_game user_id, group_id, place_name
  game = Game.find_by(group_id: group_id, place_name: place_name)
  GameMember.find_or_create_by(game_id: game.id, user_id: user_id)

  GameMember.where(game_id: game.id).pluck(:user_id)
end

def new_game event, user_id, group_id, place_name
  Game.create(
    user_id: user_id,
    group_id: group_id,
    place_name: place_name
  )
  reply_game event, place_name, ''
end

def update_game user_id, group_id, place_name
  game = Game.find_by(group_id: group_id, place_name: place_name)
  GameMember.find_or_create_by(game_id: game.id, user_id: user_id)

  GameMember.where(game_id: game.id).pluck(:user_id)
end

def reply_game event, place_name, more
  reply_content(event, {
    type: "flex",
    altText: "this is a flex message",
    contents: {
      "type": "bubble",
      "body": {
        "type": "box",
        "layout": "vertical",
        "spacing": "md",
        "contents":
          [
            {
              "type": "text",
              "text": "#{place_name}團#{more}",
              "wrap": false
            },
            {
              "type": "button",
              "style": "primary",
              "action": {
                "type": 'message',
                "label": '☝️ ++1',
                "text": "#{place_name}++1"
              }
            },
            {
              "type": "button",
              "style": "secondary",
              "action": {
                "type": "uri",
                "label": "📍 位置",
                "uri": URI.escape("#{GG_SEARCH}#{place_name}")
              }
            }
          ]
        }
      }
    }
  )
end

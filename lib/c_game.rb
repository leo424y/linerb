def new_game event, user_id, group_id, place_name
  game = Game.create(
    user_id: user_id,
    group_id: group_id,
    place_name: place_name
  )
  GameMember.create(game_id: game.id, user_id: user_id)

  reply_game event, place_name, "📣#{name_user user_id}"
end

def show_gamers user_id, group_id, game_id
  GameMember.where(game_id: game_id).pluck(:user_id)
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
              "text": "#{place_name}團",
              "wrap": true
            },
            {
              "type": "text",
              "text": "#{more}",
              "wrap": true
            },
            {
              "type": "button",
              "style": "primary",
              "action": {
                "type": 'message',
                "label": '☝️ 加加一',
                "text": "#{place_name}加加一"
              }
            }
          ]
        }
      }
    }
  )
end

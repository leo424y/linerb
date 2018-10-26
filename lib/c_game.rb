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
  # info_link = URI.extract(place_name)
  # place_name = place_name.gsub(info_link[0], '') if info_link[0]
  reply_content(event, {
    type: "flex",
    altText: "this is a flex message",
    contents: {
      "type": "bubble",
      "body": {
        "type": "box",
        "layout": "horizontal",
        "spacing": "xs",
        "contents":
          [
            {
              "type": "button",
              "style": "secondary",
              "margin": "xxl",
              "height": "sm",
              "gravity": "top",
              "action": {
                "type": 'message',
                "label": '+1',
                "text": "#{place_name}加加一"
              },
              "flex": 1
            },
            {
              "type": "text",
              "margin": "xxl",
              "text": "#{place_name}團 #{more}",
              "wrap": true,
              "action": {
                "type":"uri",
                "label":".",
                "uri": URI.escape("#{GG_SEARCH}#{place_name}")
              },
              "flex": 4
            }
          ]
        }
      }
    }
  )
end

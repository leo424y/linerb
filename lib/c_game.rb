def new_game event, user_id, group_id, place_name
  Game.create(
    user_id: user_id,
    group_id: group_id,
    place_name: place_name
  )

  reply_content(event, {
    type: "flex",
    altText: "this is a flex message",
    contents: {
      type: "bubble",
      header: {
        type: "box",
        layout: "vertical",
        contents: [
          {
            type: "text",
            text: "揪揪團！來++1"
          }
        ]
      },
      hero: {
        type: "image",
        url: HORIZONTAL_THUMBNAIL_URL,
        size: "full",
        aspectRatio: "4:3"
      },
      body: {
        type: "box",
        layout: "vertical",
        contents: [
          {
            type: "text",
            text: "#{place_name}",
          }
        ]
      },
      footer: {
        type: "box",
        layout: "vertical",
        contents: [
          { label: '☝️ ++1', type: 'message', text: "++1" },
          { label: '📍 位置', type: 'uri', uri: URI.escape("#{GG_SEARCH}#{place_name}") }
        ]
      }
    }
  })
end

def update_game user_id, group_id, place_name
  game = Game.find_by(group_id: group_id, place_name: place_name)
  GameMember.find_or_create_by(game_id: game.id, user_id: user_id)

  GameMember.where(game_id: game.id).pluck(:user_id)
end

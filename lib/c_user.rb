def list_king_user_names
  king_users = User.order(points: :desc).pluck(:user_id)[0..15]
  king_user_names = king_users.map do |n|
    king_user_name = "#{user_name n}"
    king_user_name unless king_user_name.empty?
  end.compact[0..9].map.with_index{|k,i| i==0 ? "#{k} 👑": "#{k}"}.join("\n")
  "【開王榜】\n\n#{king_user_names}\n\n趕緊來發揮你的專家雷達，查詢少人知道的好店"
end

def name_king_user
  king_user_points = User.maximum(:points)
  king_user_id = User.where(points: king_user_points).first.user_id
  user_name king_user_id
end


def user_name id
  user = User.find_by(user_id: id)
  display_name = user.display_name
  unless display_name
    i = JSON.parse(client.get_profile(id).read_body)
    user.update(display_name: i['displayName'], status_message: i['statusMessage'])
    "#{i['displayName']}"
  else
    "#{display_name}"
  end
end

def user_info id
  user = User.find_by(user_id: id)
  display_name = user.display_name
  status_message = user.status_message
  unless display_name
    i = JSON.parse(client.get_profile(id).read_body)
    user.update(display_name: i['displayName'], status_message: i['statusMessage'])
    "#{i['displayName']} #{i['statusMessage']}".rstrip
  else
    "#{display_name} #{status_message}"
  end
end

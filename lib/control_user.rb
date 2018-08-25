def list_king_user_names
  king_users = User.order(points: :desc).pluck(:user_id)[1..21]
  king_user_names = king_users.map do |n|
    king_user_name = "#{user_name n}"
    king_user_name unless king_user_name.empty?
  end.compact[0..9].map.with_index{|k,i| i==0 ? "#{k} 👑": "#{k}"}.join("\n")
  "【開王榜】\n\n#{king_user_names}\n\n趕緊來發揮你的專家雷達，查詢少人知道的好店"
end

def name_king_user
  User.find_by(user_id: 'Ubee12276c9fb5bbb3989329e80587244').update(points: 0)
  king_user_points = User.maximum(:points)
  king_user_id = User.where(points: king_user_points).first.user_id
  user_name king_user_id
end

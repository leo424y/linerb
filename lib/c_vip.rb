def is_vip user_id
  Vip.find_by(user_id: user_id)
end

def add_vip(event, user_id, group_id, opening_hours)
  Vip.create(user_id: user_id, group_id: (group_id || 'sponsor'))
  "#{user_name user_id}#{IO.readlines("data/promote_check").join}"
end

def add_point user_id, group_id, points
  Point.create(user_id: user_id, group_id: group_id, points: points)
  user = User.find_by(user_id: user_id)
  user.update(points: user.points + point) if user
  group = Group.find_by(group_id: group_id)
  group.update(points: group.points + point) if group
end

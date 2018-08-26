def add_point user_id, group_id, points
  today_point = Point.where(created_at: Date.today.beginning_of_day..Date.today.end_of_day)
  user_today_point = today_point.where(user_id: user_id)
  
  todays_point_count = user_today_point.where.not(points: 3).count
  Point.create(user_id: user_id, group_id: group_id, points: points)
  if todays_point_count < 6
    user = User.find_or_create_by(user_id: user_id)
    user.update(points: user.points + points)
    group = Group.find_by(group_id: group_id)
    group.update(points: group.points + points) if group
  end
end

def add_boom_point user_id, group_id, points
  today_point = Point.where(created_at: Date.today.beginning_of_day..Date.today.end_of_day)
  user_today_point = today_point.where(user_id: user_id)

  todays_boom_count = user_today_point.where(points: 10).count
  Point.create(user_id: user_id, group_id: group_id, points: points)
  if todays_boom_count < 11
    user = User.find_or_create_by(user_id: user_id)
    user.update(points: user.points + points)
    group = Group.find_by(group_id: group_id)
    group.update(points: group.points + points) if group
  end
end

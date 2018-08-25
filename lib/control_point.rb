def add_point user_id, group_id, points
  todays_point_count = Point.where(created_at: Time.zone.now.beginning_of_day..Time.zone.now.end_of_day).where(user_id: user_id).count
  if todays_point_count > 6
    Point.create(user_id: user_id, group_id: group_id, points: points)
    user = User.find_or_create_by(user_id: user_id)
    user.update(points: user.points + points)
    group = Group.find_by(group_id: group_id)
    group.update(points: group.points + points) if group
  end
end

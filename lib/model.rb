class Book < ActiveRecord::Base; end
class Boom < ActiveRecord::Base; end
class Father < ActiveRecord::Base; end
class Group < ActiveRecord::Base; end
class Idea < ActiveRecord::Base; end
class Log < ActiveRecord::Base; end
class Nickname < ActiveRecord::Base; end
class Offer < ActiveRecord::Base; end
class Place < ActiveRecord::Base; end
class Pocket < ActiveRecord::Base; end
class Point < ActiveRecord::Base; end
class Position < ActiveRecord::Base; end
class Review < ActiveRecord::Base; end
class Store < ActiveRecord::Base; end
class User < ActiveRecord::Base; end
class Talk < ActiveRecord::Base; end
class Vip < ActiveRecord::Base; end

def to_model yy
  [
    Book,
    Boom,
    Father,
    Group,
    Idea,
    Nickname,
    Offer,
    Place,
    Pocket,
    Point,
    Position,
    Review,
    Store,
    Talk,
    User,
    Vip,
  ].find { |c| c.to_s == yy }
end

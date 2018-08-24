def handle_review place_id
  review = Review.find_by(place_id: place_id)
  unless review && !place_id
    place_id_url = "#{GG_DETAIL_URL}?placeid=#{place_id}&language=zh-TW&fields=name,review&key=#{GMAP_KEY}"
    place_id_doc = JSON.parse(open(place_id_url).read, headers: true)
    res = place_id_doc['result']['reviews'] if place_id_doc['result']
    res.each do |r|
      Review.create(
        place_id: place_id,
        author_name: r['author_name'],
        author_url: r['author_url'],
        profile_photo_url: r['profile_photo_url'],
        rating: r['rating'],
        text: r['text'],
      )
    end if res
  end
end

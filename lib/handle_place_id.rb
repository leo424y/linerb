def handle_place_id name, name_uri, nickname
  if nickname
    nickname.place_id
  else
    place_url = "#{GG_FIND_URL}?input=#{name_uri}&inputtype=textquery&language=zh-TW&fields=place_id,name&key=#{GMAP_KEY}"
    place_doc = JSON.parse(open(place_url).read, headers: true)
    place_doc['candidates'][0]['place_id'] if place_doc['candidates'][0]
  end
end

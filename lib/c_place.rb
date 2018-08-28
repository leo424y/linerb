def control_place user_id, group_id, place_id, r
  place_name_glink = %x(ruby bin/bitly.rb '#{GG_SEARCH}#{URI.escape(r[:name_sys])}').chomp
  place = Place.find_by(place_id: place_id)

  if place
    place.update(
      place_id: place_id,
      place_name: r[:name_sys],
      address_components: r[:address_components],
      formatted_address: r[:formatted_address],
      lat: r[:lat],
      lng: r[:lng],
      place_types: r[:place_types],
      weekday_text: r[:weekday_text],
      periods: r[:periods],
      place_name_glink: place_name_glink
    )
  else
    add_point user_id, group_id, 3

    Place.create(
      place_id: place_id,
      place_name: r[:name_sys],
      address_components: r[:address_components],
      formatted_address: r[:formatted_address],
      lat: r[:lat],
      lng: r[:lng],
      place_types: r[:place_types],
      weekday_text: r[:weekday_text],
      periods: r[:periods],
      place_name_glink: place_name_glink
    )
  end
end

def handle_place_id name, name_uri, nickname
  if nickname
    nickname.place_id
  else
    place_url = "#{GG_FIND}?input=#{name_uri}&inputtype=textquery&language=zh-TW&fields=place_id,name&key=#{GMAP_KEY}"
    place_doc = JSON.parse(open(place_url).read, headers: true)
    place_doc['candidates'][0]['place_id'] if place_doc['candidates'][0]
  end
end

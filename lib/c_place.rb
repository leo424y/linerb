def control_place user_id, group_id, place, place_id, name_sys, address_components, formatted_address, lat, lng, place_types, weekday_text, periods
  place_name_glink = %x(ruby bin/bitly.rb '#{GG_SEARCH_URL}#{URI.escape(name_sys)}').chomp

  if place
    place.update(
      place_id: place_id,
      place_name: name_sys,
      address_components: address_components,
      formatted_address: formatted_address,
      lat: lat,
      lng: lng,
      place_types: place_types,
      weekday_text: weekday_text,
      periods: periods,
      place_name_glink: place_name_glink
    )
  else
    add_point user_id, group_id, 3

    Place.create(
      place_id: place_id,
      place_name: name_sys,
      address_components: address_components,
      formatted_address: formatted_address,
      lat: lat,
      lng: lng,
      place_types: place_types,
      weekday_text: weekday_text,
      periods: periods,
      place_name_glink: place_name_glink
    )
  end
end

def handle_place_id name, name_uri, nickname
  if nickname
    nickname.place_id
  else
    place_url = "#{GG_FIND_URL}?input=#{name_uri}&inputtype=textquery&language=zh-TW&fields=place_id,name&key=#{GMAP_KEY}"
    place_doc = JSON.parse(open(place_url).read, headers: true)
    place_doc['candidates'][0]['place_id'] if place_doc['candidates'][0]
  end
end

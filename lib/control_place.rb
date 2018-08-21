def create_place place, place_id, name_sys, address_components, formatted_address, lat, lng, place_types, weekday_text, periods
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

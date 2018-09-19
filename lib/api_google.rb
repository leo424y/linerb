def google_place_by place_id, name
  fields = if name.include? '水電'
    'name,type,address_component,geometry,opening_hours,formatted_address,formatted_phone_number'
  else
    'name,type,address_component,geometry,opening_hours,formatted_address'
  end
  place_id_url = "#{GG_DETAIL}?placeid=#{place_id}&language=zh-TW&fields=#{fields}&key=#{GMAP_KEY}"
  place_id_doc = JSON.parse(open(place_id_url).read, headers: true)
  r = place_id_doc['result']

  if r['formatted_phone_number']
    r['formatted_phone_number'] = r['formatted_phone_number'].gsub(" ","")
  end

  if r['opening_hours'].to_s.empty?
    {
      formatted_address: r['formatted_address'],
      formatted_phone_number: r['formatted_phone_number'],
      address_components: r['address_components'],
      name_sys: r['name'],
      lat: r['geometry']['location']['lat'],
      lng: r['geometry']['location']['lng'],
      place_types: r['types'],
    }
  else
    {
      formatted_address: r['formatted_address'],
      formatted_phone_number: r['formatted_phone_number'],
      address_components: r['address_components'],
      name_sys: r['name'],
      lat: r['geometry']['location']['lat'],
      lng: r['geometry']['location']['lng'],
      opening_hours: r['opening_hours'],
      place_types: r['types'],
      open_now: r['opening_hours']['open_now'],
      periods: r['opening_hours']['periods'],
      weekday_text: r['opening_hours']['weekday_text'],
    }
  end
end

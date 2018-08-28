def google_place_by place_id
  place_id_url = "#{GG_DETAIL}?placeid=#{place_id}&language=zh-TW&fields=name,type,address_component,geometry,opening_hours,formatted_address&key=#{GMAP_KEY}"
  place_id_doc = JSON.parse(open(place_id_url).read, headers: true)
  r = place_id_doc['result']

  {
    formatted_address: r['formatted_address'],
    address_components: r['address_components'],
    name_sys: r['name'],
    lat: r['geometry']['location']['lat'],
    lng: r['geometry']['location']['lng'],
    opening_hours: r['opening_hours'],
    place_types: r['types'],
    open_now: r['opening_hours']['open_now'].to_s,
    periods: r['opening_hours']['periods'],
    weekday_text: r['opening_hours']['weekday_text'],
  }
end

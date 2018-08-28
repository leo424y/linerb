def google_place_by place_id
  place_id_url = "#{GG_DETAIL}?placeid=#{place_id}&language=zh-TW&fields=name,type,address_component,geometry,opening_hours,formatted_address&key=#{GMAP_KEY}"
  place_id_doc = JSON.parse(open(place_id_url).read, headers: true)

  place_id_doc['result']
end

def offer_info_s
  in_offer = Offer.where("store_name like ?", "%#{name}%")

  unless in_offer.empty?
    offer_at = in_offer.last.created_at.strftime('%m/%d')
    offer_at = (Date.today.strftime('%m/%d') == offer_at) ? '-今天' : "-#{offer_at}"
     "\n💁 #{in_offer.last.info[0..50]}#{offer_at}"
  else
     ''
  end
end

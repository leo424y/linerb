def handle_text event, user_id, group_id, suffixes, skip_name, m, name, name_uri, link, origin_message
  if ( m.end_with?('附近') || m.start_with?('附近') && !group_id)
    reply_text(event, '請先查詢要去的地點【有開嗎】？若有營業資訊，則可以點選【🎐 附近】偷瞄開民們的口袋名單囉！')

  elsif (m.to_i > 0) && !group_id
    place = Store.where(info: user_id).last
    place_info = [place.place_id, place.name_sys]
    reply_content(event, number_to_cost_h(user_id, place_info, m)) if place

  elsif ( (origin_message.split("\n").count > 1) && !group_id )
    store_name = origin_message.split("\n")[0]
    Offer.create(user_id: user_id, store_name: store_name, info: origin_message.split("\n")[1..-1].join("\n"))
    reply_text event, "已將【#{store_name}】情報收錄，感謝提供！"

  elsif (is_tndcsc? m)
    m = '北運'
    message = count_exercise m
    reply_text(event, message)

  elsif (is_cyc? m)
    message = count_exercise m
    reply_text(event, message)

  elsif name.end_with? '口袋有洞'
    pocket = Pocket.where(user_id: user_id).pluck(:place_name).uniq.shuffle[-4..-1]
    if pocket
      actions_a = pocket.map { |p|
        {label: "📍 #{p}", type: 'uri', uri: "#{GG_SEARCH_URL}#{URI.escape(p)}"}
      }
      reply_content( event, message_buttons_h('口袋有洞', '裡頭掉出了...', actions_a) )
    else
      reply_text(event, '口袋裡目前空空，請先問完要去的店有開嗎後，再將想要的結果放口袋~')
    end

  elsif name.end_with? '放口袋~'
    message = if (is_vip user_id)
      Pocket.create(user_id: user_id, place_name: name.chomp('放口袋~'))
      "👜 已將#{name}"
    else
      '🥇 邀請有開嗎至任一群組，並成功問到一家有開的店，即能啟用放口袋功能'
    end
    reply_text(event, message)

  elsif (name.bytesize > 30 && !group_id)
    Idea.create(user_id: user_id, content: m)
    reply_text event, '感謝你提供建議，【有開嗎】因你的回饋將變得更好！'

  elsif (m.end_with?(*suffixes) || !group_id) && (name != '')
    in_offer = Offer.where("store_name like ?", "%#{name}%")
    unless in_offer.empty?
      offer_at = in_offer.last.created_at.strftime('%m/%d')
      offer_at = (Date.today.strftime('%m/%d') == offer_at) ? '-今天' : "-#{offer_at}"
      offer_info = "\n💁 #{in_offer.last.info[0..50]}#{offer_at}"
    end
    s_link = %x(ruby bin/bitly.rb '#{link}').chomp

    level_up_button = { label: '👜 放口袋', type: 'message', text: "#{name}放口袋~" }

    if name == '麥當勞中港四店'
      message_buttons_text = '😃 現在有開'
    elsif name == '鬼門'
      message_buttons_text = ( (Date.today < Date.new(2018,8,10)) && (Date.today > Date.new(2018,9,9)) ) ? '👻 現在沒開' : '👻👻👻 現在正開'
    elsif user_id && (!skip_name.include? name)
      nickname = Nickname.find_by(nickname: name)
      if nickname
        place_id = nickname.place_id
      else
        place_url = "#{GG_FIND_URL}?input=#{name_uri}&inputtype=textquery&language=zh-TW&fields=place_id,name&key=#{GMAP_KEY}"
        place_doc = JSON.parse(open(place_url).read, headers: true)
        place_id = place_doc['candidates'][0]['place_id'] if place_doc['candidates'][0]
      end

      begin
        unless place_id.nil?
          place = Place.find_by(place_id: place_id)

          place_id_url = "#{GG_DETAIL_URL}?placeid=#{place_id}&language=zh-TW&fields=name,type,address_component,geometry,opening_hours,formatted_address&key=#{GMAP_KEY}"
          place_id_doc = JSON.parse(open(place_id_url).read, :headers => true)
          res = place_id_doc['result']
          formatted_address = res['formatted_address']
          address_components = res['address_components']
          name_sys = res['name']
          lat = res['geometry']['location']['lat']
          lng = res['geometry']['location']['lng']
          if res['opening_hours']
            place_types = res['types']
            is_open_now = res['opening_hours']['open_now']
            periods = res['opening_hours']['periods']
            weekday_text = res['opening_hours']['weekday_text']
            opening_hours = is_open_now ? "😃 現在有開" : "🔴 現在沒開"

            message_buttons_text = if (is_cyc? name)
              "#{opening_hours}\n#{count_exercise name}"
            elsif is_tndcsc? name
              "#{opening_hours}\n#{count_exercise '北運'}"
            elsif is_tpsc? name
              "#{opening_hours}\n#{p_tp_count name}"
            else
              # {"message":"must not be longer than 60 characters","property":"template/text"}
              in_offer.empty? ? opening_hours : "#{opening_hours}#{offer_info}"
            end

            nearby_button = { label: '🎐 附近', type: 'postback', data: "#{place_id}nearby" }

            if user_id && group_id && !(is_vip user_id)
              message = [
                "【#{name}】#{opening_hours}",
                add_vip(event, user_id, group_id, opening_hours),
              ]
              reply_text event, message
            end
          else
            message_buttons_text = '😬 請見詳情'
          end

          Nickname.create(
            place_id: place_id,
            place_name: name_sys,
            nickname: name
          ) unless nickname

          Store.create(
            name: name,
            name_sys: name_sys,
            address_components: address_components,
            formatted_address: formatted_address,
            lat: lat,
            lng: lng,
            place_types: place_types,
            info: user_id,
            group_id: group_id,
            place_id: place_id,
            opening_hours: res['opening_hours'] ? is_open_now.to_s : 'no',
            weekday_text: weekday_text,
            periods: periods,
            s_link: s_link
          )
          create_place place, place_id, name_sys, address_components, formatted_address, lat, lng, place_types, weekday_text, periods
        else
          message_buttons_text = "⏰ 請見詳情#{offer_info}"
        end
      rescue
        message_buttons_text = "😂 請見詳情#{offer_info}"
      end
    else
      message_buttons_text = "🤔 請見詳情#{offer_info}"
    end

    review = Review.find_by(place_id: place_id)
    unless review
      place_id_url = "#{GG_DETAIL_URL}?placeid=#{place_id}&language=zh-TW&fields=name,review&key=#{GMAP_KEY}"
      place_id_doc = JSON.parse(open(place_id_url).read, :headers => true)
      res = place_id_doc['result']['reviews']
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

    # if is_vip
    #   Review.order("RANDOM()").find_by(place_id: place_id).text
    #   { label: '⭐ 評論', type: 'postback', data: place_review }
    # end

    random_info = [0, 1, 2].sample
    suggest_button = case random_info
    when 0
      { label: '👍 推薦', type: 'uri', uri: L_RECOMMEND_URI}
    when 1
      { label: '💡 建議', type: 'uri', uri: L_OPINION_URI }
    when 2
      { label: '👼 贊助', type: 'uri', uri: L_SPONSOR_URI }
    end

    actions_a = [
      { label: '📍 詳情', type: 'uri', uri: s_link },
      nearby_button,
      suggest_button,
      level_up_button,
    ].compact

    reply_content event, message_buttons_h(name, message_buttons_text, actions_a)
  elsif !group_id
    reply_text event, IO.readlines("data/intro").map(&:chomp)

  end
end

def message_buttons_h title, text, actions
  {
    type: 'template',
    thumbnailImageUrl: '',
    altText: '...',
    template: {
      type: 'buttons',
      title: title,
      text: text,
      actions: actions,
    }
  }
end

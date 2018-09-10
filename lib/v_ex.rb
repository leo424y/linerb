def count_exercise m
  if /\A(北運|北區運動中心|北區國民運動中心|台中市北區國民運動中心)\z/.match m
    p_count 'http://tndcsc.com.tw/', '.w3_agile_logo p', 350, 130
  elsif /\A(淡運|淡水運動中心|淡水國民運動中心)\z/.match? m
    p_count 'http://www.tssc.tw/', '.number-current', 400, 70
  elsif /\A(板運|板橋運動中心|板橋國民運動中心)\z/.match? m
    p_count 'http://www.bqsports.com.tw/zh-TW/onsitenum?wmode=opaque', '.flow_number', 400, 80
  elsif is_tpsc? name
    p_tp_count name
  else
    ice=''
    j = case m
    when '朝運', '朝馬運動中心', '朝馬國民運動中心'
      cyc_j '朝運'
    when '桃運', '桃園運動中心', '桃園國民運動中心'
      cyc_j '桃運'
    when '壢運', '中壢運動中心', '中壢國民運動中心'
      cyc_j '壢運'
    when '永運', '永和運動中心', '永和國民運動中心'
      cyc_j '永運'
    when '蘆運', '蘆洲運動中心', '蘆洲國民運動中心'
      cyc_j '蘆運'
    when '土運', '土城運動中心', '土城國民運動中心'
      i = cyc_j '土運'
      ice = " 🍧 #{i['ice'][0]}/#{i['ice'][1]}"
      i
    when '汐運', '汐止運動中心', '汐止國民運動中心'
      cyc_j '汐運'
    end
    "🏊 #{j['swim'][0]}/#{j['swim'][1]}\n💪 #{j['gym'][0]}/#{j['gym'][1]}#{ice}"
  end
end

def p_count url, selector, pool, gym
  count = ''
  url = url
  doc = Nokogiri::HTML(open(url))
  if selector == '.flow_number'
    doc.css(selector).each_with_index do |l, index|
      if index < 2
        count += ("#{l.content}".split.map{|x| x[/\d+/]}[0] + (index==1 ? "/#{pool} 🏊\n" : "/#{gym} 💪"))
      end
    end
  else
    doc.css(selector).each_with_index do |l, index|
      count += ("#{l.content}".split.map{|x| x[/\d+/]}[0] + (index==0 ? "/#{pool} 🏊\n" : "/#{gym} 💪"))
    end
  end
  count
end

def cyc_j m
  case m
  when '桃運'
    cyc_domain = 'tycsc'
  when '壢運'
    cyc_domain = 'zlcsc'
  when '朝運'
    cyc_domain = 'cmcsc'
  when '永運'
    cyc_domain = 'yhcsc'
  when '蘆運'
    cyc_domain = 'lzcsc'
  when '土運'
    cyc_domain = 'tccsc'
  when '汐運'
    cyc_domain = 'xzcsc'
  end
  JSON.parse(open("https://#{cyc_domain}.cyc.org.tw/api").read, headers: true)
end

def is_tndcsc? name
  [
    '北運', '北區運動中心', '北區國民運動中心', '台中市北區國民運動中心',
    '淡運', '淡水運動中心', '淡水國民運動中心',
    '板運', '板橋運動中心', '板橋國民運動中心',
  ].include? name
end

def is_cyc? name
  [
    '朝運', '朝馬運動中心', '朝馬國民運動中心', '台中市朝馬國民運動中心',
    '桃運', '桃園運動中心', '桃園國民運動中心',
    '壢運', '中壢運動中心', '中壢國民運動中心',
    '永運', '永和運動中心', '永和國民運動中心',
    '蘆運', '蘆洲運動中心', '蘆洲國民運動中心',
    '土運', '土城運動中心', '土城國民運動中心',
    '汐運', '汐止運動中心', '汐止國民運動中心'
  ].include? name
end

def is_tpsc? name
  [
    '北投運動中心',
    '大安運動中心',
    '大同運動中心',
    '中正運動中心',
    '南港運動中心',
    '內湖運動中心',
    '士林運動中心',
    '文山運動中心',
    '信義運動中心',
    '中山運動中心',
  ].include? name
end

def p_tp_count name
  a = %x(curl 'http://booking.tpsc.sporetrofit.com/Home/loadLocationPeopleNum' -XPOST -H 'Host: booking.tpsc.sporetrofit.com' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.13; rv:61.0) Gecko/20100101 Firefox/61.0' -H 'Accept: */*' -H 'Accept-Language: en-US,en;q=0.5' -H 'Accept-Encoding: gzip, deflate' -H 'Referer: http://booking.tpsc.sporetrofit.com/Home/LocationPeopleNum' -H 'X-Requested-With: XMLHttpRequest' -H 'Cookie: _culture=zh-TW' -H 'Connection: keep-alive' -H 'Content-Length: 0')
  b = JSON.parse(a)['locationPeopleNums']
  c = b.select {|h1| h1['lidName']=="#{name}"}.first
  "🏊 #{c['swPeopleNum']} / #{c['swMaxPeopleNum']} \n💪 #{c['gymPeopleNum']} / #{c['gymMaxPeopleNum']} "
end

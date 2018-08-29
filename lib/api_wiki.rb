def wiki_content event, name
  wiki_data = wikir(name, 'zh')
  if wiki_data.text
    "#{wiki_data.text.truncate(200)} " + %x(ruby bin/bitly.rb "#{wiki_data.fullurl}").chomp
  else
    nil
  end
end

def wikir title, lang
  Wikipedia.configure {
    domain "#{lang}.wikipedia.org"
    path   'w/api.php'
  }
  Wikipedia.find(title)
end

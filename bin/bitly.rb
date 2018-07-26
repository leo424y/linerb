require 'bitly'
NAME='leo424yy'
API_KEY='R_c545a03a3cbf4034b390fa5c4c153cb2'
Bitly.use_api_version_3

Bitly.configure do |config|
  config.api_version = 3
  config.access_token = API_KEY
end

bitly = Bitly.new(NAME,API_KEY )
u=bitly.shorten(ARGV[0], :history => 1)
puts u.jmp_url

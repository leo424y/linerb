require 'bitly'

# NAME='leo424yy'
# API_KEY='R_c545a03a3cbf4034b390fa5c4c153cb2'

# NAME='o_4c2nbk4m7q'
# API_KEY='R_9def63bcade34721826109d5dcd98fb1'

# fendon666
NAME='o_1grrs284e7'
API_KEY='R_31c388a19eb1495895f28d3a50f34db2'

Bitly.use_api_version_3

Bitly.configure do |config|
  config.api_version = 3
  config.access_token = API_KEY
end

bitly = Bitly.new(NAME,API_KEY )
u=bitly.shorten(ARGV[0], :history => 1)
puts u.jmp_url

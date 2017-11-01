require 'sinatra'   # gem 'sinatra'
require 'line/bot'  # gem 'line-bot-api'

def client
  @client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
  }
end

post '/callback' do
  body = request.body.read
  # signature = request.env['HTTP_X_LINE_SIGNATURE']
  # unless client.validate_signature(body, signature)
  #   error 400 do 'Bad Request' end
  # end
  events = client.parse_events_from(body)

  events.each { |event|
    case event
    when Line::Bot::Event::Message
      case event.type
      when Line::Bot::Event::MessageType::Text
        m = event.message['text'].split(' ')
        message = {
          type: 'text',
          text: "你提供的資訊是：在#{m[0]}跑了#{m[1]}單。謝謝你，我收到囉！明早向你報告統計結果啦"
        }
        client.reply_message(event['replyToken'], message)
      end
    end
  }

  "OK"
end

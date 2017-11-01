current_dir = Dir.pwd
Dir["#{current_dir}/models/*.rb"].each { |file| require file }

get '/logs' do

  @logs = Log.all

end


get '/logs/:id' do

  @log = Log.find(params[:id])

end

post '/logs' do

  @log = Log.create(params[:log])

end

put '/logs/:id/publish' do

  @log = Log.find(params[:id])
  @log.publish!

end

delete '/logs/:id' do

  Log.destroy(params[:id])

end

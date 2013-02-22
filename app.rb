require 'sinatra'

require 'sinatra/respond_with'

require 'sinatra/flash'

require 'multi_json'

#require 'omniauth'
#require 'omniauth-openid'
#require 'omniauth-steam'

require 'steam-condenser'
require 'retriable'

env_variables_file = File.join(settings.root, 'env_variables.rb')
load(env_variables_file) if File.exists? env_variables_file

set :database, ENV['DATABASE_URL']

WebApi.api_key = ENV['STEAM_API_KEY']

#enable :sessions

# Steam OAuth stuff - currently disabled

#use OmniAuth::Builder do
#  provider :steam, ENV['STEAM_API_KEY']
#end

# Support both GET and POST for callbacks
#%w(get post).each do |method|
#  send(method, '/auth/:provider/callback') do
#    session[:user] = env['omniauth.auth'][:extra][:raw_info]
#    redirect '/'
#  end
#end
#
#get '/auth/failure' do
#  flash[:notice] = params[:message]
#  redirect '/'
#end

# web stuff

#before do
#  @current_user = session[:user]
#end

get '/' do
  erb :layout
end

#get '/signout' do
#  session[:user] = nil
#  redirect '/'
#end


# API stuff

get '/api/friends/:steamid', provides: :json do
  begin
    friends = WebApi.get(:json, 'ISteamUser', 'GetFriendList', '0001', steamid: params[:steamid])
    friends = MultiJson.load(friends)['friendslist']['friends'].map { |friend| friend['steamid'] }
    friends.to_json
  rescue Exception => e
    raise e if settings.development?
    status 404
    { error: true }.to_json
  end
end

get '/api/profiles', provides: :json do
  begin
    steamids = params[:steamids].split(',')

    if steamids.all? { |i| i.to_i.to_s == i }
      users = []
      # Steam has a limit of 100 IDs per request
      steamids.each_slice(100).with_index { |ids, i|
        retriable tries: 3, interval: 2 do
          puts "Fetching API for index #{i}"
          api_users = WebApi.get(:json, 'ISteamUser', 'GetPlayerSummaries', '0002', steamids: ids.join(','))
          users << MultiJson.load(api_users)['response']['players'].map do |user|
            {
              _id: user['steamid'],
              username: user['personaname'],
              avatar: user['avatar'].split('.')[0..-2].join('.').split('/')[-2..-1].join('/')
            }
          end
        end
      }

      users.flatten!

      status 404 if users == []

      users.to_json
    else
      { error: 'All Steam IDs must be numbers.' }.to_json
    end
  rescue Exception => e
    raise e if settings.development?
    status 404
    { error: true }.to_json
  end
end

get '/api/id/:customurl', provides: :json do
  begin
    { steamid: SteamId.resolve_vanity_url(params[:customurl]).to_s }.to_json
  rescue Exception => e
    raise e if settings.development?
    status 404
     { error: true }.to_json
  end
end
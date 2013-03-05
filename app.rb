require 'sinatra'
require 'sinatra/respond_with'
require 'sinatra/flash'

require 'net/http'

require 'mongo'

require 'multi_json'

#require 'omniauth'
#require 'omniauth-openid'
#require 'omniauth-steam'

require 'steam-condenser'
require 'retriable'

env_variables_file = File.join(settings.root, 'env_variables.rb')
load(env_variables_file) if File.exists? env_variables_file

include Mongo

db = MongoClient.from_uri(ENV['DATABASE_URL']).db(ENV['DATABASE_NAME'])

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

    steamids.uniq!

    if steamids.count > 300 # Steam friends limit is 300 (250+50 for connecting FB), don't bother with more requests
      raise
    end

    if steamids.all? { |i| i.to_i.to_s == i }
      users = []

      # Steam has a limit of 100 IDs per request
      steamids.each_slice(100) do |ids|
        retriable tries: 3, interval: 2 do
          api_users = WebApi.get(:json, 'ISteamUser', 'GetPlayerSummaries', '0002', steamids: ids.join(','))
          users << MultiJson.load(api_users)['response']['players'].map do |user|
            {
              _id: user['steamid'],
              username: user['personaname'],
              avatar: user['avatar'].split('.')[0..-2].join('.').split('/')[-2..-1].join('/'),
              public: (user['communityvisibilitystate'] == 3 ? true : false)
            }
          end
        end
      end

      users.flatten!

      status 404 if users == []

      users.to_json
    else
      raise # all Steam IDs must be numbers
    end
  rescue Exception => e
    raise e if settings.development?
    status 404
    MultiJson.dump({ error: true })
  end
end

get '/api/id/:customurl', provides: :json do
  begin
    { steamid: SteamId.resolve_vanity_url(params[:customurl]).to_s }.to_json
  rescue Exception => e
    raise e if settings.development?
    status 404
    MultiJson.dump({ error: true })
  end
end

get %r{/api/(?<type>(gid|groups))/(?<groupid>.*)}, provides: :json do |type, groupid|
  begin
    response = Net::HTTP.get_response(URI.parse("http://steamcommunity.com/#{type}/#{groupid}/memberslistxml/?xml=1"))

    response = MultiXml.parse(response.body).to_hash

    output = {
      gid: response['memberList']['groupID64'],
      name: response['memberList']['groupDetails']['groupName'],
      avatar: response['memberList']['groupDetails']['avatarIcon'][67..-5],
      memberCount: response['memberList']['memberCount'],
      members: response['memberList']['members']['steamID64'].map { |member| member } # TODO get all members, not just the first page
    }

    MultiJson.dump(output)
  rescue Exception => e
    raise e if settings.development?
    status 404
    MultiJson.dump({ error: true })
  end
end

# database wrapper

get %r{/api/db/(?<collection>(leaderboard|users|settings))$}, provides: :json do |collection|
  find_options = {}

  if params[:s]
    find_options[:sort] = MultiJson.load params[:s]
  end
  if params[:l]
    find_options[:limit] = params[:l].to_i
  end
  if params[:sk]
    find_options[:skip] = params[:sk].to_i
  end
  if params[:f]
    find_options[:fields] = MultiJson.load params[:f]
  end

  query = db.collection(collection).find(MultiJson.load(params[:q]), find_options)

  if params[:c] then
    query.count(true).to_json
  else
    query.to_a.to_json
  end
end
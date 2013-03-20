require 'sinatra'
require 'sinatra/respond_with'
require 'sinatra/flash'

require 'better_errors' if settings.development?

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

configure :development do
  use BetterErrors::Middleware
end

set :db, MongoClient.from_uri(ENV['DATABASE_URL']).db(ENV['DATABASE_NAME'])

WebApi.api_key = ENV['STEAM_API_KEY']

helpers do
  # @param [String] type Type of the request ('gid' or 'groups')
  # @param [String, Fixnum] groupid ID of the group
  # @param [Array] fields Which fields to return
  # @param [Fixnum] fetch_pages How many pages to fetch. Default -1 (all pages)
  # @return [String] JSON with the group info and members or error.
  def get_steam_group(type, groupid, fields = [:gid, :name, :avatar, :memberCount, :members], fetch_pages = -1)
    current_page = 1
    total_pages = 1

    all_members = []

    output = {}

    groupid = groupid.gsub('[', '%5B').gsub(']', '%5D')

    begin
      url = "http://steamcommunity.com/#{type}/#{groupid}/memberslistxml/?xml=1&p=#{current_page}"
      response = Net::HTTP.get_response(URI(url))

      response = MultiXml.parse(response.body).to_hash

      if current_page == 1
        if fetch_pages == -1
          total_pages = response['memberList']['totalPages'].to_i
        else
          total_pages = fetch_pages
        end

        total_pages = 9 if total_pages >= 10 # check 10k members, not more - it would be too slow

        output[:gid] = response['memberList']['groupID64'] if fields.include? :gid
        output[:name] = response['memberList']['groupDetails']['groupName'] if fields.include? :name
        output[:avatar] = response['memberList']['groupDetails']['avatarIcon'][67..-5] if fields.include? :avatar
        output[:memberCount] = response['memberList']['memberCount'].to_i if fields.include? :memberCount
      end

      all_members.push response['memberList']['members']['steamID64'] if fields.include? :members

      current_page += 1
    end while current_page <= total_pages

    if fields.include? :members
      all_members.flatten!
      output[:membersWithEntries] = settings.db.collection('users').find({ :_id => { '$in' => all_members } }, { fields: [:_id] }).to_a.map { |user| user['_id'] }
    end

    output # call MultiJson.dump on the returned hash
  end
end


#

get '/' do
  erb :layout
end


# API stuff

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
  rescue => e
    raise e if settings.development?
    status 404
    MultiJson.dump({ error: true })
  end
end

get '/api/id/:customurl', provides: :json do
  begin
    { steamid: SteamId.resolve_vanity_url(params[:customurl]).to_s }.to_json
  rescue => e
    raise e if settings.development?
    status 404
    MultiJson.dump({ error: true })
  end
end

get '/api/friends/:steamid', provides: :json do
  begin
    friends = WebApi.get(:json, 'ISteamUser', 'GetFriendList', '0001', steamid: params[:steamid])
    friends = MultiJson.load(friends)['friendslist']['friends'].map { |friend| friend['steamid'] }
    friends.to_json
  rescue => e
    raise e if settings.development?
    status 404
    { error: true }.to_json
  end
end

get '/api/usergroups/:steamid', provides: :json do
  begin
    groups = WebApi.get(:json, 'ISteamUser', 'GetUserGroupList', '0001', steamid: params[:steamid])
    groups = MultiJson.load(groups)['response']['groups'].map { |gid| gid['gid'] }

    groups_result = {
      groupCount: groups.count,
      groups: []
    }

    # return empty groups if user is a member of more than 1000 groups - hi, http://steamcommunity.com/id/hyins
    if groups.count <= 1000
      threads = []

      groups.each_slice(5) do |groups_slice|
        threads << Thread.new(groups_slice) do |slice|
          slice.map do |groupid|
            # groupid is in a weird format, it needs to be [g:0:groupid] to fetch it (thanks iveinsomnia)
            gid = "[g:0:#{groupid}]"
            begin
              group = get_steam_group('gid', gid, [:gid, :name, :avatar, :memberCount], 1)
              groups_result[:groups].push group
            rescue => e
              puts "Exception while loading group ID #{gid}" if settings.development?
              # silently fail if it's a private group or if Steam API is derping
              next
            end
          end
        end
      end

      threads.each { |t| t.join }
    end

    groups_result.to_json
  rescue => e
    raise e if settings.development?
    status 404
    MultiJson.dump({ error: true })
  end
end

get %r{/api/(?<type>(gid|groups))/(?<groupid>.*)}, provides: :json do |type, groupid|
  begin
    MultiJson.dump get_steam_group(type, groupid)
  rescue => e
    raise e if settings.development?
    status 404
    MultiJson.dump({ error: true })
  end
end

get '/api/latestcommits', provides: :json do
  begin
    http = Net::HTTP.new('api.github.com', 443)
    http.use_ssl = true
    response = http.get("/repos/TomasDuda/super-hexagon-stats/commits?per_page=5&client_id=#{ENV['GITHUB_OAUTH_CLIENT_ID']}&client_secret=#{ENV['GITHUB_OAUTH_CLIENT_SECRET']}")
    response.body
  rescue => e
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

  query = settings.db.collection(collection).find(MultiJson.load(params[:q]), find_options)

  if params[:c] then
    query.count(true).to_json
  else
    query.to_a.to_json
  end
end
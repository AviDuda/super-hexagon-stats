require 'sinatra'
require 'mongo'
require 'retriable'
require 'coffee-script'
require 'steam-condenser/community'
require 'multi_json'

env_variables_file = File.join(settings.root, 'env_variables.rb')
load(env_variables_file) if File.exists? env_variables_file

include Mongo

set :database, ENV['DATABASE_URL']

WebApi.api_key = ENV['STEAM_API_KEY']

desc 'Updates the Super Hexagon data in the database.'
task 'hex:update_data' do
  time_start = Time.now

  puts "(#{(Time.now - time_start).to_i} seconds) Connecting to the database."

  connection = MongoClient.from_uri(ENV['DATABASE_URL'])

  db = connection.db(ENV['DATABASE_NAME'])

  puts "(#{(Time.now - time_start).to_i} seconds) Removing leaderboard_update collection and creating indexes."

  c = db.collection('leaderboard_update')
  c.drop
  c.create_index 'difficulty'
  c.create_index 'steamid', drop_dups: true
  c.create_index [['time', Mongo::ASCENDING], ['time', Mongo::DESCENDING]]

  puts "(#{(Time.now - time_start).to_i} seconds) Fetching leaderboards."

  # get the leaderboard data

  per_request = 5000 # Steam API limit

  leaderboard_entries_count = 0

  steamids = []

  leaderboards = GameLeaderboard.leaderboards('SuperHexagon').compact

  leaderboards.each do |leaderboard|
    # change leaderboard name from LEADERBOARD_HEXAGON to Hexagon etc.
    difficulty = leaderboard.name[12..-1]
    if difficulty[0..4] == 'HYPER'
      difficulty = 'Hyper H' + difficulty[6..-1].downcase
    else
      difficulty = 'H' + difficulty[1..-1].downcase
    end

    puts "(#{(Time.now - time_start).to_i} seconds) Leaderboard #{difficulty} has #{leaderboard.entry_count} entries."

    leaderboard_entries_count += leaderboard.entry_count

    request_start = 1

    while request_start < leaderboard.entry_count
      leaderboard_entries = []

      puts "(#{(Time.now - time_start).to_i} seconds) #{difficulty}: Loading #{request_start}-#{request_start + per_request} / #{leaderboard.entry_count}"
      retriable tries: 3, interval: 5 do
        leaderboard.entry_range(request_start, request_start + per_request).compact.each do |entry|
          leaderboard_entries << {
            difficulty: difficulty,
            steamid: entry.steam_id.steam_id64.to_s,
            time: entry.score / 60 + (entry.score % 60 / 100.00),
            rank: entry.rank
          }
          steamids << entry.steam_id.steam_id64.to_s
        end
      end


      puts "(#{(Time.now - time_start).to_i} seconds) #{difficulty}: Saving #{request_start}-#{request_start + per_request} to the database"

      c.insert leaderboard_entries

      puts "(#{(Time.now - time_start).to_i} seconds) #{difficulty}: Done #{request_start}-#{request_start + per_request}"

      request_start += per_request + 1
    end
  end

  puts "(#{(Time.now - time_start).to_i} seconds) Removing users_update collection."

  c = db.collection('users_update')
  c.drop

  puts "(#{(Time.now - time_start).to_i} seconds) Fetching Steam usernames and friends."

  steamids.uniq!

  puts "(#{(Time.now - time_start).to_i} seconds) Found #{steamids.count} unique Steam IDs."

  thread_count = 40
  threads = []
  per_thread = (steamids.count / thread_count).ceil
  request_start = 0

  users = []

  # create thread_count threads for requests so it's faster
  thread_count.times do |i|
    threads << Thread.new(request_start) do |start|

      print "(#{(Time.now - time_start).to_i} seconds) Making thread # #{i+1} for user requests #{start}-#{start+per_thread}.\n"

      # Steam has a limit of 100 IDs per request
      steamids[start..start+per_thread].each_slice(100).with_index { |ids, slice|
        retriable tries: 3, interval: 2 do
          print "(#{(Time.now - time_start).to_i} seconds) Thread #{i+1}: Fetching API for #{start}-#{start+per_thread}, slice #{slice+1}/#{steamids[start..start+per_thread].count / 100 + 1}\n"
          api_users = WebApi.get(:json, 'ISteamUser', 'GetPlayerSummaries', '0002', steamids: ids.join(','))
          MultiJson.load(api_users)['response']['players'].each do |player|
            # avatar URLs: http://media.steampowered.com/steamcommunity/public/images/avatars/{{avatar}}{{"" (small) || "_medium" || "_full"}}.jpg
            users << {
              _id: player['steamid'].to_s,
              username: player['personaname'],
              avatar: player['avatar'][67..-5], # get just folder and file without extension (e.g. "te/test" for "http://media.steampowered.com/steamcommunity/public/images/avatars/te/test.jpg")
              public: (player['communityvisibilitystate'] == 3 ? true : false)
            }
          end
        end
      }

      print "(#{(Time.now - time_start).to_i} seconds) Thread #{i+1} for user requests #{start}-#{start+per_thread} done.\n"
    end
    request_start += per_thread + 1
  end

  threads.each { |t| t.join }

  users.uniq!

  print "(#{(Time.now - time_start).to_i} seconds) Adding user entries to the database.\n"

  users.each_slice(10000).with_index do |users_slice, i|
    puts "(#{(Time.now - time_start).to_i} seconds) Adding user slice #{i+1}/#{users.count / 10000 + 1} to the database."
    c.insert users_slice
  end

  puts "(#{(Time.now - time_start).to_i} seconds) Setting maintenance mode on."

  # maintenance should be short when dropping and renaming collections, but it's still a good idea to set it
  db.collection('settings').update({ key: 'maintenance' }, { key: 'maintenance', value: true }, { upsert: true })

  puts "(#{(Time.now - time_start).to_i} seconds) Dropping the current collections."

  db.drop_collection 'leaderboard'
  db.drop_collection 'users'

  puts "(#{(Time.now - time_start).to_i} seconds) Renaming the update collections to current collections."

  db.rename_collection 'leaderboard_update', 'leaderboard'
  db.rename_collection 'users_update', 'users'

  puts "(#{(Time.now - time_start).to_i} seconds) Setting maintenance mode off."

  db.collection('settings').update({ key: 'maintenance' }, { key: 'maintenance', value: false }, { upsert: true })
  db.collection('settings').update({ key: 'lastUpdate' }, { key: 'lastUpdate', value: Time.now.utc.to_s }, { upsert: true })

  puts "(#{(Time.now - time_start).to_i} seconds) Repairing database."

  db.command({ repairDatabase: 1 })

  puts "(#{(Time.now - time_start).to_i} seconds) Done! #{leaderboard_entries_count} leaderboard entries and #{steamids.count} users added to the database."
end

namespace :js do
  desc 'Compile CoffeeScript from ./coffeescripts to ./public/javascripts/app.js'
  task :compile do
    require 'find'

    files_to_compile = []

    Dir.chdir File.join(settings.root, 'coffeescripts') do
      Find.find(Dir.pwd) do |path|
        if FileTest.directory? path
          if File.basename(path)[0] == ?.
            Find.prune
          else
            next
          end
        elsif path =~ /\.coffee$/
          files_to_compile << path
        end
      end

      File.open File.join(settings.root, 'public', 'javascripts', 'app.js'), 'w' do |js|
        js.write `coffee -pjl #{files_to_compile.join(' ')}`
      end
    end
  end
end
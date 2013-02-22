require 'sinatra'
require 'mongo'
require 'retriable'
require 'coffee-script'
require 'steam-condenser'
require 'multi_json'

env_variables_file = File.join(settings.root, 'env_variables.rb')
load(env_variables_file) if File.exists? env_variables_file

include Mongo

set :database, ENV['DATABASE_URL']

WebApi.api_key = ENV['STEAM_API_KEY']

desc 'Updates the Super Hexagon data in the database.'
task 'hex:update_data' do
  time_start = Time.now

  puts "(#{(Time.now - time_start).to_i} seconds) Connecting to database."

  db = MongoClient.from_uri(ENV['MONGOLAB_URL']).db(ENV['MONGOLAB_DB'])

  puts "(#{(Time.now - time_start).to_i} seconds) Setting maintenance mode on."

  # better to warn few minutes before DB update happens

  db.collection('settings').update({}, { key: 'maintenance', value: true }, { upsert: true })

  puts "(#{(Time.now - time_start).to_i} seconds) Fetching leaderboards."

  # get the leaderboard data

  per_request = 5000 # Steam API limit

  leaderboard_entries = []
  steamids = []

  threads = []
  running_threads = 0

  leaderboards = GameLeaderboard.leaderboards('SuperHexagon').compact

  leaderboards.each do |leaderboard|
    # change leaderboard name from LEADERBOARD_HEXAGON to Hexagon etc.
    difficulty = leaderboard.name[12..-1]
    if difficulty[0..4] == 'HYPER'
      difficulty = 'Hyper H' + difficulty[6..-1].downcase
    else
      difficulty = 'H' + difficulty[1..-1].downcase
    end

    print "(#{(Time.now - time_start).to_i} seconds) Leaderboard #{difficulty} has #{leaderboard.entry_count} entries.\n"

    request_start = 1

    while request_start < leaderboard.entry_count
      # create a thread for each entry range request
      threads << Thread.new(request_start) do |start|
        running_threads += 1
        thread_num = running_threads
        thread_num.freeze

        print "(#{(Time.now - time_start).to_i} seconds) Making thread # #{thread_num} for #{difficulty} and entry range #{start}-#{start + per_request}\n"

        print "(#{(Time.now - time_start).to_i} seconds) #{difficulty}: Loading #{start}-#{start + per_request}\n"
        retriable tries: 3, interval: 10 do
          leaderboard.entry_range(start, start + per_request).compact.each do |entry|
            score = ('%.2f' % (entry.score / 60.00))
            leaderboard_entries << {
              difficulty: difficulty,
              steamid: entry.steam_id.steam_id64.to_s,
              time: score.to_f,
              rank: entry.rank
            }
            steamids << entry.steam_id.steam_id64.to_s
          end
        end

        print "(#{(Time.now - time_start).to_i} seconds) #{difficulty}: Done #{start}-#{start + per_request}\n"
      end
      request_start += per_request
    end
  end
  threads.each { |t| t.join }
  threads = []

  puts "(#{(Time.now - time_start).to_i} seconds) Fetching Steam usernames and friends."

  steamids.uniq!

  puts "(#{(Time.now - time_start).to_i} seconds) Found #{steamids.count} unique Steam IDs (#{steamids.count / 100} requests to Steam API)."

  users = []

  thread_count = 40 # change this if it's too slow
  per_thread = steamids.count / (thread_count - 1)
  request_start = 0

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
              avatar: player['avatar'][67..-5] # get just folder and file without extension (e.g. "te/test" for "http://media.steampowered.com/steamcommunity/public/images/avatars/te/test.jpg")
            }
          end
        end
      }
    end
    request_start += per_thread
  end
  threads.each { |t| t.join }

  users.uniq!

  puts "(#{(Time.now - time_start).to_i} seconds) Removing leaderboard collection and creating indexes."

  c = db.collection('leaderboard')
  c.drop
  c.create_index 'difficulty'
  c.create_index 'steamid'
  c.create_index [['time', Mongo::ASCENDING], ['time', Mongo::DESCENDING]]

  puts "(#{(Time.now - time_start).to_i} seconds) Adding leaderboard entries to database."

  db_per_slice = 50000

  leaderboard_entries.each_slice(db_per_slice).with_index do |entries, slice|
    puts "(#{(Time.now - time_start).to_i} seconds) Saving leaderboard slice #{db_per_slice * slice}-#{db_per_slice * (slice + 1)}."
    c.insert entries
  end

  puts "(#{(Time.now - time_start).to_i} seconds) Removing users collection."

  c = db.collection('users')
  c.drop

  puts "(#{(Time.now - time_start).to_i} seconds) Adding user entries to database."

  users.each_slice(db_per_slice).with_index do |entries, slice|
    puts "(#{(Time.now - time_start).to_i} seconds) Saving users slice #{db_per_slice * slice}-#{db_per_slice * (slice + 1)}."
    c.insert entries
  end

  puts "(#{(Time.now - time_start).to_i} seconds) Setting maintenance mode off."

  db.collection('settings').update({}, { key: 'maintenance', value: false }, { upsert: true })

  puts "(#{(Time.now - time_start).to_i} seconds) Done! #{leaderboard_entries.count} leaderboard entries and #{users.count} users added to database."
end

namespace :js do
  desc 'Compile CoffeeScript from ./coffeescripts to ./public/javascripts'
  task :compile do
    source = "#{File.dirname(__FILE__)}/coffeescripts/"
    javascripts = "#{File.dirname(__FILE__)}/public/javascripts/"

    Dir.foreach(source) do |cf|
      unless cf == '.' || cf == '..'
        js = CoffeeScript.compile File.read("#{source}#{cf}")
        open "#{javascripts}#{cf.gsub('.coffee', '.js')}", 'w' do |f|
          f.puts js
        end
      end
    end
  end
end
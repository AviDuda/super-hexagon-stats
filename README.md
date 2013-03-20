# Super Hexagon stats

Cool stats for [Terry Cavanagh](http://distractionware.com)'s game [Super Hexagon](http://store.steampowered.com/app/221640).
I love this game and you should love it too.
[Try the Flash version](http://www.kongregate.com/games/TerryCavanagh_B/hexagon) so you know how awesome it is (Super Hexagon is even better).

Website is live on [superhexagonstats.herokuapp.com](http://superhexagonstats.herokuapp.com/). If you have any ideas for new features, just [create a new issue](https://github.com/TomasDuda/super-hexagon-stats/issues/new).

## FAQ

### Would it be possible to do something like this for another Steam game (or all other Steam games) with a leaderboard?

Yes, but I don't want to simply because Valve now knows that e.g. group leaderboards are useful (thanks, [greuben](http://steamcommunity.com/id/greuben) :)) so I hope they will implement it as a native Steam feature.
Or it may be available on awesome [sAPI](http://sapi.techieanalyst.net/) in the future, I don't know.

### Does it work in IE or similar ancient browsers?

I have no idea. If there are any problems, create a new issue or make a pull request with a fix.

### I have more questions!

[Tweet me](https://twitter.com/tomasduda) or [add me on Steam](http://steamcommunity.com/id/TimmyCZ).

Oh, also buy our game [Faerie Solitaire](http://store.steampowered.com/app/38600/). It's required to use Super Hexagon stats... Ok, just kidding. But try it.

## Technical stuff

This site was built with [AngularJS](http://angularjs.org/). It's my first project in it, so it may be ugly.
I'm using [Ruby](http://www.ruby-lang.org/) for server stuff (specifically [Sinatra](http://www.sinatrarb.com/)),
[MongoDB](http://www.mongodb.org/) ([MongoLab](https://mongolab.com/)) for the database,
[CoffeeScript](http://coffeescript.org/),
and [Twitter Bootstrap](http://twitter.github.com/bootstrap/) because you wouldn't want to look at the website if it was designed by me.

### I want to try it on my machine!

1. You definitely want to get [RVM](https://rvm.io/) (Ruby Version Manager). Life would be hard without this awesome tool.
Or try [pik](https://github.com/vertiginous/pik/) if you are on Windows, but I haven't tried that so it's possible that it doesn't work.
2. Go to the directory and run `bundle install` in the terminal.
3. Open file `env_variables.rb.example`, rename it to `env_variables.rb` and change it to your needs (used in development, use e.g. Heroku config in production).
4. Run `rake hex:update_data` to update leaderboard and users. It will take a while, Steam API is slow.
5. Install [Node.js](http://nodejs.org) and then `sudo npm install -g coffee-script` to install CoffeeScript compiler.
6. Run `rake js:compile` to compile CoffeeScript files in the `coffescripts` directory. It's a good idea to put it in a shell script before launching the server
(or if you use [RubyMine](http://www.jetbrains.com/ruby/), just set *Run Rake task js:compile* in the *Before launch* option).
7. Run Super Hexagon stats with `thin start`, `rackup` or however you want!

Enjoy!
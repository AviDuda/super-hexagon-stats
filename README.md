# Super Hexagon stats

Cool stats for [Terry Cavanagh](http://distractionware.com)'s game [Super Hexagon](http://store.steampowered.com/app/221640).
I love this game and you should love it too.
[Try the Flash version](http://www.kongregate.com/games/TerryCavanagh_B/hexagon) so you know how awesome it is (Super Hexagon is even better).

It's a beta, more features coming soon!

## FAQ

### IT DOESN'T WORK!

It's just a beta. Nope, I don't want to have a headache from ugly IE hacks. Download a better browser.

### You will steal my data if I disable NoScript for this site!

Sure. Move along.

### I have more questions!

[Tweet me](https://twitter.com/tomasduda) or [add me on Steam](http://steamcommunity.com/id/TimmyCZ).

Oh, also buy our game [Faerie Solitaire](http://store.steampowered.com/app/38600/). It's required to use Super Hexagon stats... Ok, just kidding. But try it.

## Technical stuff

This site was built with [AngularJS](http://angularjs.org/). It's my first project in it, so it may be ugly.
I'm using [Ruby](http://www.ruby-lang.org/) for server stuff (specifically [Sinatra](http://www.sinatrarb.com/)),
[CoffeeScript](http://coffeescript.org/) because pure Javascript sucks,
and [Twitter Bootstrap](http://twitter.github.com/bootstrap/) because you wouldn't want to look at the website if it was designed by me.

I'm using [MongoLab](https://mongolab.com/) for the database.
**WARNING:** API keys aren't read only, so use throwaway accounts on MongoLab.
I'll probably change it to server-side requests, because everyone can grab the API key and do whatever they want.
[It will probably take a while until MongoLab implements read-only API keys](https://support.mongolab.com/entries/20269612-REST-api-permissions-and-security-best-practice)
()

### I want to try it on my machine!

1. You definitely want to get [RVM](https://rvm.io/) (Ruby Version Manager). Life would be hard without this awesome tool.
Or try [pik](https://github.com/vertiginous/pik/) if you are on Windows, but I haven't tried that so it's possible that it doesn't work.
2. Go to the directory and run `bundle install` in the terminal.
3. Open file `env_variables.rb.example`, rename it to `env_variables.rb` and change it to your needs (used in development, use e.g. Heroku config in production).
4. Run `rake update_data` to update leaderboard and users. It will take a while.
5. Run `rake js:compile` to compile `coffescripts/app.coffee`. It's a good idea to put it in a shell script before launching the server
(or if you use [RubyMine](http://www.jetbrains.com/ruby/), just set *Run Rake task js:compile* in the *Before launch* option).
6. Run Super Hexagon stats with `thin start`, `rackup` or however you want!

Enjoy!
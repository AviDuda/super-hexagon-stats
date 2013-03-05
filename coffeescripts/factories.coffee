app.factory 'Leaderboard', ['$dbResourceHttp', ($dbResourceHttp) ->
  $dbResourceHttp 'leaderboard'
]

app.factory 'User', ['$dbResourceHttp', ($dbResourceHttp) ->
  $dbResourceHttp 'users'
]

app.factory 'Settings', ['$dbResourceHttp', ($dbResourceHttp) ->
  $dbResourceHttp 'settings'
]

app.factory 'TableSort', ->
  TableSort =
    column: ''
    descending: false
    icons:
      ascending: 'icon-chevron-up',
      descending: 'icon-chevron-down'
    sortClass: (column) ->
      if column == @column
        if @descending
          @icons.descending
        else
          @icons.ascending
    changeSorting: (column) ->
      if column == @column
        @descending = !@descending
      else
        @column = column
        @descending = false
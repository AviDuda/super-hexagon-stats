"use strict"

app = angular.module 'hexagonStats', ['ui', 'ui.bootstrap', 'dbResourceHttp']
app.config ['$routeProvider', ($routeProvider) ->
  $routeProvider
    .when('/', {templateUrl: 'partials/home.html', controller: 'HomeCtrl'})
    .when('/leaderboard/:leaderboard', {templateUrl: 'partials/leaderboard.html', controller: 'LeaderboardCtrl'})
    .when('/leaderboard', {templateUrl: 'partials/leaderboard.html', controller: 'LeaderboardCtrl'})
    .when('/profiles/:steamid64', {templateUrl: 'partials/profile.html', controller: 'ProfileCtrl'})
    .when('/id/:customurl', {templateUrl: 'partials/custom_url.html', controller: 'CustomUrlCtrl'})
    .otherwise({ redirectTo: '/' })
]

app.constant 'DB_CONFIG', { BASE_URL: '/api/db/' }

app.run ['$rootScope', '$location', '$window', 'Settings', ($rootScope, $location, $window, Settings) ->
  $rootScope.difficulties = ['Hexagon', 'Hexagoner', 'Hexagonest', 'Hyper Hexagon', 'Hyper Hexagoner', 'Hyper Hexagonest']

  $rootScope.$on '$routeChangeStart', ->
    $rootScope.isViewLoading = true

    Settings.all(
      (data) ->
        $rootScope.settings = {}
        for setting in data
          $rootScope.settings[setting.key] = setting.value
    )
  $rootScope.$on '$routeChangeSuccess', ->
    $rootScope.isViewLoading = false
    if $window._gaq?
      $window._gaq.push(['_trackPageview', $location.path()]);

  $rootScope.getAvatar = (url, size = '') ->
    # size is null (small), medium, full
    if size != ''
      size = '_' + size
    'http://media.steampowered.com/steamcommunity/public/images/avatars/' + url + size + '.jpg'

  $rootScope.searchCustomUrl = ->
    $location.path "/id/#{$rootScope.customUrlSearch}"
]

# factories

app.factory 'Leaderboard', ['$dbResourceHttp', ($dbResourceHttp) ->
  $dbResourceHttp 'leaderboard'
]

app.factory 'User', ['$dbResourceHttp', ($dbResourceHttp) ->
  $dbResourceHttp 'users'
]

app.factory 'Settings', ['$dbResourceHttp', ($dbResourceHttp) ->
  $dbResourceHttp 'settings'
]

# directives

app.directive 'activelink', ['$location', ($location) ->
  {
  restrict: 'A',
  link: (scope, element, attrs) ->
    scope.$location = $location
    scope.$watch '$location.path()', (locationPath) ->
      # if the tag has an attribute noactivelinkindex, don't search just for indexOf, locations must be the same (useful for dropdowns in menu etc.)
      if attrs.noactivelinkindex?
        isCorrectLocation = attrs.activelink.substring(1) == locationPath
      else
        isCorrectLocation = locationPath.indexOf(attrs.activelink.substring(1)) > -1

      if attrs.activelink.length > 0 and isCorrectLocation
        element.addClass('active')
      else
        element.removeClass('active')
  }
]

# factories

app.factory 'TableSort', ->
  TableSort =
    column: ''
    descending: false
    icons:
      ascending: 'icon-chevron-up',
      descending: 'icon-chevron-down'
    sortClass: (column) ->
      if column == this.column
        if this.descending
          this.icons.descending
        else
          this.icons.ascending
    changeSorting: (column) ->
      if column == this.column
        this.descending = !this.descending
      else
        this.column = column
        this.descending = false

# controllers

app.controller 'HomeCtrl', [ '$scope', '$rootScope', 'Leaderboard', 'User', ($scope, $rootScope, Leaderboard, User) ->
  $rootScope.title = 'Home'

  $scope.difficultyRows = [['Hexagon', 'Hexagoner', 'Hexagonest'], ['Hyper Hexagon', 'Hyper Hexagoner', 'Hyper Hexagonest']]

  $scope.top10 = {}
  $scope.top10Loading = {}
  $scope.top10Users = {}

  getLeaderboard = (difficulty) ->
    Leaderboard.query(
      { difficulty: difficulty },
      { sort: { time: -1 }, limit: 10, fields: { _id: 0 } },
      (data) ->
        $scope.top10[difficulty] = data

        user_ids = data.map (entry) -> entry.steamid

        if user_ids.length > 0
          User.query(
            { _id: { $in: user_ids } },
            (data) ->
              for user in data
                $scope.top10Users[user._id] = user

              $scope.top10Loading[difficulty] = false
          )
        else
          $scope.top10Loading[difficulty] = false

      (data, status) ->
        $scope.top10Loading[difficulty] = false
    )


  for difficulty in $rootScope.difficulties
    $scope.top10Loading[difficulty] = true
    getLeaderboard difficulty
]


app.controller 'ProfileCtrl', ['$scope', '$rootScope', '$routeParams', '$http', 'User', ($scope, $rootScope, $routeParams, $http, User) ->
  $rootScope.title = 'Profile'

  $scope.userLoading = true

  User.query(
    { _id: $routeParams.steamid64 },
    (data) ->
      if data[0]?
        # user has some etries in the leaderboard, we have all required info
        $scope.user = data[0]
        $rootScope.title = "#{$scope.user.username}'s profile"
        $scope.userLoading = false
      else
        # fetch user data from Steam API
        $http.get('/api/profiles?steamids=' + $routeParams.steamid64)
          .success (data) ->
            $scope.user = data[0]
            $scope.userLoading = false
          .error (data, status) ->
            $scope.userLoading = false
  )
]

app.controller 'ProfileLeaderboardCtrl', ['$scope', '$rootScope', '$filter', 'Leaderboard', 'TableSort', ($scope, $rootScope, $filter, Leaderboard, TableSort) ->
  $scope.leaderboardLoading = true

  Leaderboard.query(
    { steamid: $scope.user._id },
    { sort: { difficulty: 1 }, fields: { _id: 0 } }
    (data) ->
      $scope.leaderboard = data
      $scope.leaderboardLoading = false
    (data, status) ->
      $scope.leaderboardLoading = false
  )

  $scope.sort = {}
  angular.extend $scope.sort, TableSort
  $scope.sort.column = 'difficulty'

  $scope.setFilters = () ->
    $scope.leaderboard = $filter('orderBy')($scope.leaderboard, $scope.sort.column, $scope.sort.descending)

  $scope.setFilters()

  # change filters after sorting
  $scope.oldChangeSorting = $scope.sort.changeSorting
  $scope.sort.changeSorting = () ->
    $scope.oldChangeSorting.apply this, arguments
    $scope.setFilters()
]

app.controller 'ProfileFriendsCtrl', ['$scope', '$rootScope', '$http', '$filter', 'Leaderboard', 'User', 'TableSort', ($scope, $rootScope, $http, $filter, Leaderboard, User, TableSort) ->
  $scope.loadingAllFriends = true

  $http.get("/api/friends/#{$scope.user._id}")
    .success (data) ->
      $scope.allFriends = data
      $scope.loadingAllFriends = false
      $scope.switchDifficultyView('all') # view all difficulties
    .error (data, status) ->
      $scope.loadingAllFriends = false

  $scope.viewDifficulties = {}

  $scope.switchDifficultyView = (difficulty) ->
    $scope.viewDifficulties[difficulty] = !$scope.viewDifficulties[difficulty]
    if difficulty == 'all'
      for diff in $rootScope.difficulties
        $scope.viewDifficulties[diff] = $scope.viewDifficulties[difficulty]
    $scope.getLeaderboard()

  $scope.getLeaderboard = ->
    if $scope.viewDifficulties['all']
      query_difficulties = $rootScope.difficulties
    else
      query_difficulties = []
      for difficulty in $rootScope.difficulties
        if $scope.viewDifficulties[difficulty]
          query_difficulties.push difficulty

    $scope.leaderboardLoading = true

    Leaderboard.query(
      { difficulty: { $in: query_difficulties }, steamid: { $in: $scope.allFriends } },
      { fields: { _id: 0 } },
      (data) ->
        $scope.leaderboard = data

        users = (entry.steamid for entry in data)
        users = $filter('unique')(users)

        $scope.uniqueUsersCount = users.length

        User.query(
          { _id: { $in: users } },
          (data) ->
            users = {}
            for user in data
              users[user._id] = user

            # push user info to leaderboard so we can sort by friend name
            for entry in $scope.leaderboard
              angular.extend entry, users[entry.steamid]

            $scope.setFilters()

            $scope.leaderboardLoading = false
          (data, status) ->
            $scope.leaderboardLoading = false
        )

      (data) ->
        $scope.leaderboardLoading = false
    )

  $scope.sort = {}
  angular.extend $scope.sort, TableSort
  $scope.sort.column = 'username'

  $scope.setFilters = () ->
    $scope.leaderboard = $filter('orderBy')($scope.leaderboard, $scope.sort.column, $scope.sort.descending)

  # change filters after sorting
  $scope.oldChangeSorting = $scope.sort.changeSorting
  $scope.sort.changeSorting = () ->
    $scope.oldChangeSorting.apply this, arguments
    $scope.setFilters()
]

app.controller 'CustomUrlCtrl', ['$scope', '$routeParams', '$http', '$location', ($scope, $routeParams, $http, $location) ->
  $scope.loading = true
  $scope.customUrl = $routeParams.customurl

  $http.get('/api/id/' + $routeParams.customurl)
    .success (data) ->
      $scope.loading = false
      if data.steamid? and data.steamid != ''
        $scope.steamid = data.steamid
        $scope.redirecting = true
        $location.path('/profiles/' + $scope.steamid)
      else
        $scope.error = true
    .error (data, status) ->
      $scope.loading = false
      $scope.error = true
]

app.controller 'LeaderboardCtrl', ['$rootScope', ($rootScope) ->
  $rootScope.title = 'Leaderboard'
]
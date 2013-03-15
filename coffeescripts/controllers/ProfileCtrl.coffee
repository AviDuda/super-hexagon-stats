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


  $scope.achievements =
    'Hexagon':
      name: 'Point'
      description: 'Complete the Hexagon stage'
      locked: 'http://media.steampowered.com/steamcommunity/public/images/apps/221640/712eaa3b5a85249fc122a2db3aa323b6a12023d5.jpg'
      unlocked: 'http://media.steampowered.com/steamcommunity/public/images/apps/221640/7b6f8d9d17c6d05d99a037191be6b60678493a0e.jpg'
    'Hexagoner':
      name: 'Line'
      description: 'Complete the Hexagoner stage'
      locked: 'http://media.steampowered.com/steamcommunity/public/images/apps/221640/721a93744602b9b7e079f47bed66d9077669f27c.jpg'
      unlocked: 'http://media.steampowered.com/steamcommunity/public/images/apps/221640/31441aba2aa29375cd2e1c9e2390f95dc9e268c0.jpg'
    'Hexagonest':
      name: 'Triangle'
      description: 'Complete the Hexagonest stage'
      locked: 'http://media.steampowered.com/steamcommunity/public/images/apps/221640/cbedaecd552c882f5718f562fa23f0ee4cf05433.jpg'
      unlocked: 'http://media.steampowered.com/steamcommunity/public/images/apps/221640/d320ccbf78d931c8a5f250b31d2c5f6b7d0338a7.jpg'
    'Hyper Hexagon':
      name: 'Square'
      description: 'Complete the Hyper Hexagon stage'
      locked: 'http://media.steampowered.com/steamcommunity/public/images/apps/221640/9eed0c36085ea1f6ac731037a4ccec2a205d621d.jpg'
      unlocked: 'http://media.steampowered.com/steamcommunity/public/images/apps/221640/f7f5e10ae41f516b9b823fff6973822d3c608c19.jpg'
    'Hyper Hexagoner':
      name: 'Pentagon'
      description: 'Complete the Hyper Hexagoner stage'
      locked: 'http://media.steampowered.com/steamcommunity/public/images/apps/221640/4d48c4b0155970d2b6b7d6e32dcccf9c9e3ef0fe.jpg'
      unlocked: 'http://media.steampowered.com/steamcommunity/public/images/apps/221640/4a7aa0bfb5b4025b18f0ef5e098c36a7a2e1d4d0.jpg'
    'Hyper Hexagonest':
      name: 'Hexagon'
      description: 'Complete the Hyper Hexagonest stage, and witness the end'
      locked: 'http://media.steampowered.com/steamcommunity/public/images/apps/221640/2e2de0af6b0f5732cbbad3ca8c13f99f8941d21e.jpg'
      unlocked: 'http://media.steampowered.com/steamcommunity/public/images/apps/221640/3381965e9b2b07819d53ad5c634ba37158c5f9c1.jpg'

  $scope.getAchievementForTime = (time, difficulty) ->
    if time >= 60
      $scope.achievements[difficulty].unlocked
    else
      $scope.achievements[difficulty].locked
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

app.controller 'ProfileUserGroupsCtrl', ['$scope', '$http', 'TableSort', ($scope, $http, TableSort) ->
  $scope.userGroupsLoading = true

  $http.get("/api/usergroups/#{$scope.user._id}")
    .success (data) ->
      $scope.userGroups = data

      $scope.pagination =
        currentPage: 1
        perPage: 10
        numPages: ->
          Math.ceil($scope.userGroups.groups.length / @perPage)

      $scope.sort = {}
      angular.extend $scope.sort, TableSort
      $scope.sort.column = 'name'

      $scope.userGroupsLoading = false
    .error (data, status) ->
      $scope.userGroupsLoading = false
]
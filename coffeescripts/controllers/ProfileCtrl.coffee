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
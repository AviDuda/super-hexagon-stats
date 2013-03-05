app.controller 'CompareCtrl', ['$scope', '$rootScope', 'Leaderboard', ($scope, $rootScope, Leaderboard) ->
  $rootScope.title = 'Compare Users'

  $rootScope.$watch 'comparison', ->
    if $rootScope.comparison.length > 0
      users_array = (entry.steamid for entry in $rootScope.comparison)

      $scope.leaderboardLoading = true

      Leaderboard.query(
        { steamid: { $in: users_array } },
        { sort: { steamid: 1, difficulty: 1 } },
      (data) ->
        $scope.users = {}

        for entry in $rootScope.comparison
          $scope.users[entry.steamid] = { username: entry.username, avatar: entry.avatar, leaderboard: {} }

        for entry in data
          $scope.users[entry.steamid].leaderboard[entry.difficulty] = entry

        $scope.leaderboardLoading = false
        (data, status) ->
          $scope.leaderboardLoading = false
      )
]
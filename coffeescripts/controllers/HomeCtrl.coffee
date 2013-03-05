app.controller 'HomeCtrl', [ '$scope', '$rootScope', '$http', 'Leaderboard', 'User', ($scope, $rootScope, $http, Leaderboard, User) ->
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

  $http.get('/api/latestcommits')
    .success (data) ->
      $scope.latestCommits = data
]
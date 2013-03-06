app.controller 'StatsCtrl', ['$scope', '$rootScope', 'Leaderboard', 'User', ($scope, $rootScope, Leaderboard, User) ->
  $rootScope.title = 'Stats'

  $scope.stats = []

  $scope.statsBeforeHumbleBundle =
    'Users': 48609
    'Leaderboard entries': 174575
    'Hexagon entries': 48437
    'Hexagoner entries': 38094
    'Hexagonest entries': 38764
    'Hyper Hexagon entries': 26139
    'Hyper Hexagoner entries': 14223
    'Hyper Hexagonest entries': 8918

  User.count {}, (data) -> $scope.stats.push { name: 'Users', value: data }

  Leaderboard.count {}, (data) -> $scope.stats.push { name: 'Leaderboard entries', value: data }

  $scope.getDifficultyEntries = (diff) ->
    Leaderboard.count { difficulty: diff }, (data) -> $scope.stats.push { name: "#{diff} entries", value: data }

  for difficulty in $rootScope.difficulties
    $scope.getDifficultyEntries difficulty
]
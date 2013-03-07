app.controller 'StatsCtrl', ['$scope', '$rootScope', 'Leaderboard', 'User', ($scope, $rootScope, Leaderboard, User) ->
  $rootScope.title = 'Stats'

  $scope.stats = []

  $scope.statsNames = [
    'Users'
    'Leaderboard entries'
    'Hexagon entries'
    'Hexagoner entries'
    'Hexagonest entries'
    'Hyper Hexagon entries'
    'Hyper Hexagoner entries'
    'Hyper Hexagonest entries'
  ]

  $scope.statsBeforeHumbleBundle =
    'Users': 48609
    'Leaderboard entries': 174575
    'Hexagon entries': 48437
    'Hexagoner entries': 38094
    'Hexagonest entries': 38764
    'Hyper Hexagon entries': 26139
    'Hyper Hexagoner entries': 14223
    'Hyper Hexagonest entries': 8918

  User.count {}, (data) -> $scope.stats['Users'] = data

  Leaderboard.count {}, (data) -> $scope.stats['Leaderboard entries'] = data

  $scope.getDifficultyEntries = (diff) ->
    Leaderboard.count { difficulty: diff }, (data) -> $scope.stats["#{diff} entries"] = data

  for difficulty in $rootScope.difficulties
    $scope.getDifficultyEntries difficulty
]
app.controller 'LeaderboardCtrl', ['$scope', '$rootScope', '$routeParams', 'Leaderboard', 'User', ($scope, $rootScope, $routeParams, Leaderboard, User) ->
  $scope.leaderboardName = $routeParams.leaderboard.replace('_', ' ')

  $rootScope.title = "Leaderboard #{$scope.leaderboardName}"

  $scope.rankSort = 1

  $scope.leaderboardLoading = true

  $scope.pagination =
    currentPage: 1
    perPage: 20

  Leaderboard.count(
    { difficulty: $scope.leaderboardName },
  (data) ->
    $scope.leaderboardCount = parseInt(data)

    $scope.pagination.numPages = ->
      Math.ceil($scope.leaderboardCount / @perPage)

    $scope.changePage()
    (data, status) ->
      $scope.leaderboardLoading = false
  )

  $scope.$watch 'pagination.currentPage', ->
    $scope.changePage()

  $scope.changePage = ->
    $scope.leaderboardLoading = true

    Leaderboard.query(
      { difficulty: $scope.leaderboardName },
      {
        sort: { rank: $scope.rankSort },
        limit: $scope.pagination.perPage,
        skip: ($scope.pagination.currentPage * $scope.pagination.perPage - $scope.pagination.perPage)
      },
    (data) ->
      $scope.leaderboard = data

      # get users

      users = (entry.steamid for entry in data)

      User.query(
        { _id: { $in: users } },
      (data) ->
        users = {}
        for user in data
          users[user._id] = user

        # push user info to leaderboard
        for entry in $scope.leaderboard
          angular.extend entry, users[entry.steamid]

        $scope.leaderboardLoading = false
        (data, status) ->
          $scope.leaderboardLoading = false
      )
      (data, status) ->
        $scope.leaderboardLoading = false
    )

  # we don't use TableSort here, we're getting data from DB
  $scope.changeSorting = ->
    if $scope.rankSort == 1
      $scope.rankSort = -1
    else
      $scope.rankSort = 1
    $scope.changePage()

  $scope.sortClass = (reverse = false) ->
    if $scope.rankSort == 1
      if reverse
        'icon-chevron-down'
      else
        'icon-chevron-up'
    else
      if reverse
        'icon-chevron-up'
      else
        'icon-chevron-down'
]
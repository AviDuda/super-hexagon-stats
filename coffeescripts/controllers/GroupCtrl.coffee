app.controller 'GroupCtrl', ['$scope', '$rootScope', '$routeParams', '$location', '$http', '$filter', 'TableSort', 'Leaderboard', 'User', ($scope, $rootScope, $routeParams, $location, $http, $filter, TableSort, Leaderboard, User) ->
  $rootScope.title = 'Group'

  url_type = 'gid'
  unless $location.$$path[0..3] == '/gid'
    url_type = 'groups'

  $scope.groupLoading = true

  $scope.pagination =
    currentPage: 1
    perPage: 20

  $http.get("/api/#{url_type}/#{$routeParams.groupid}")
    .success (data) ->
      $scope.group = data
      $rootScope.title = "Group #{$scope.group.name}"
      $scope.groupLoading = false
      $scope.switchDifficultyView('all')
    .error (data, status) ->
      $scope.groupLoading = false

  $scope.viewDifficulties = {}

  $scope.switchDifficultyView = (difficulty) ->
    $scope.leaderboardLoading = true

    $scope.viewDifficulties[difficulty] = !$scope.viewDifficulties[difficulty]
    if difficulty == 'all'
      for diff in $rootScope.difficulties
        $scope.viewDifficulties[diff] = $scope.viewDifficulties[difficulty]

    $scope.query_difficulties = []

    if $scope.viewDifficulties['all']
      $scope.query_difficulties = $rootScope.difficulties
    else
      for difficulty in $rootScope.difficulties
        if $scope.viewDifficulties[difficulty]
          $scope.query_difficulties.push difficulty

    $scope.pagination.currentPage = 1

    Leaderboard.count(
      { difficulty: { $in: $scope.query_difficulties }, steamid: { $in: $scope.group.membersWithEntries } },
      (data) ->
        $scope.pagination.numPages = ->
          Math.ceil(data / @perPage)
      (data, status) ->
        $scope.leaderboardLoading = false
    )

    $scope.getLeaderboard()

  $scope.getLeaderboard = ->
    $scope.leaderboardLoading = true

    sortBy = {}
    sortBy[$scope.sort.column] = 1

    if $scope.sort.descending
      sortBy[$scope.sort.column] = -1

    Leaderboard.query(
      { difficulty: { $in: $scope.query_difficulties }, steamid: { $in: $scope.group.membersWithEntries } }
      {
        sort: sortBy,
        limit: $scope.pagination.perPage,
        skip: ($scope.pagination.currentPage * $scope.pagination.perPage - $scope.pagination.perPage),
        fields: { _id: 0 }
      },
      (data) ->
        $scope.leaderboard = data

        users = (entry.steamid for entry in data)
        users = $filter('unique')(users)

        User.query(
          { _id: { $in: users } },
          (data) ->
            users = {}
            for user in data
              users[user._id] = user

            # push user info to leaderboard so we can sort by username
            for entry in $scope.leaderboard
              angular.extend entry, users[entry.steamid]

            $scope.leaderboardLoading = false
          (data, status) ->
            $scope.leaderboardLoading = false
        )
      (data) ->
        $scope.leaderboardLoading = false
    )

  $scope.sort = {}
  angular.extend $scope.sort, TableSort

  $scope.sort.column = 'rank'

  $scope.oldChangeSorting = $scope.sort.changeSorting
  $scope.sort.changeSorting = (column) ->
    $scope.oldChangeSorting.apply this, arguments
    $scope.getLeaderboard()

  $scope.$watch 'pagination.currentPage', ->
    if $scope.group?
      $scope.getLeaderboard()
]
app.controller 'GroupCtrl', ['$scope', '$rootScope', '$routeParams', '$location', '$http', '$filter', 'Leaderboard', 'User', ($scope, $rootScope, $routeParams, $location, $http, $filter, Leaderboard, User) ->
  $rootScope.title = 'Group'

  url_type = 'gid'
  unless $location.$$path[0..3] == '/gid'
    url_type = 'groups'

  $scope.groupLoading = true

  $http.get("/api/#{url_type}/#{$routeParams.groupid}")
    .success (data) ->
      $scope.group = data

      # TODO Mongo doesn't want to load too many values in $in
      User.query(
        { _id: { $in: data.members } },
        (data) ->
          $scope.users = {}
          $scope.unique_users = []

          for entry in data
            $scope.users[entry._id] = { username: entry.username, avatar: entry.avatar, leaderboard: { } }
            $scope.unique_users.push entry._id

          # TODO Mongo doesn't want to load too many values in $in
          Leaderboard.query(
            { steamid: { $in: $scope.unique_users } },
            (data) ->
              for entry in data
                $scope.users[entry.steamid].leaderboard[entry.difficulty] = entry
              $scope.groupLoading = false
            (data, status) ->
              $scope.groupLoading = false
          )


        (data, status) ->
          $scope.groupLoading = false
      )
    .error (data, status) ->
      $scope.groupLoading = false
]
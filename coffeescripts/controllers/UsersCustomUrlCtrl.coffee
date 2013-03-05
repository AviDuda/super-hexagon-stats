app.controller 'UsersCustomUrlCtrl', ['$scope', '$routeParams', '$http', '$location', ($scope, $routeParams, $http, $location) ->
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
app.controller 'SearchNicknameCtrl', ['$scope', '$rootScope', '$routeParams', '$location', 'User', ($scope, $rootScope, $routeParams, $location, User) ->
  $rootScope.title = 'Search Results'
  $scope.nickname = $routeParams.nickname

  $scope.pagination =
    currentPage: 1
    perPage: 20

  User.count(
    { username: { $regex: ".*#{$scope.nickname}.*", $options: 'i' } },
  (data) ->
    $scope.usersCount = parseInt(data)

    $scope.pagination.numPages = ->
      Math.ceil($scope.usersCount / @perPage)

    $scope.changePage()
  )

  $scope.$watch 'pagination.currentPage', ->
    $scope.changePage()

  $scope.changePage = ->
    $scope.usersLoading = true

    User.query(
      { username: { $regex: ".*#{$scope.nickname}.*", $options: 'i' } },
      {
      sort: { username: 1 },
      limit: $scope.pagination.perPage,
      skip: ($scope.pagination.currentPage * $scope.pagination.perPage - $scope.pagination.perPage)
      },
    (data) ->
      $scope.users = data
      $scope.usersLoading = false

      if data.length == 1
        $scope.redirecting = true
        $location.path "/profiles/#{data[0]._id}"
      (data, status) ->
        $scope.usersLoading = false
    )
]
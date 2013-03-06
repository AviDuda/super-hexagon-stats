"use strict"

app = angular.module 'hexagonStats', ['ui', 'ui.bootstrap', 'dbResourceHttp']
app.config ['$routeProvider', ($routeProvider) ->
  $routeProvider
    .when('/', {templateUrl: 'partials/home.html', controller: 'HomeCtrl'})
    .when('/leaderboard/:leaderboard', {templateUrl: 'partials/leaderboard.html', controller: 'LeaderboardCtrl'})
    .when('/leaderboard', {templateUrl: 'partials/leaderboard.html', controller: 'LeaderboardCtrl'})
    .when('/profiles/:steamid64', {templateUrl: 'partials/profile.html', controller: 'ProfileCtrl'})
    .when('/id/:customurl', {templateUrl: 'partials/users_custom_url.html', controller: 'UsersCustomUrlCtrl'})
    .when('/gid/:groupid', {templateUrl: 'partials/group.html', controller: 'GroupCtrl'})
    .when('/groups/:groupid', {templateUrl: 'partials/group.html', controller: 'GroupCtrl'})
    .when('/search/nickname/:nickname', {templateUrl: 'partials/search_nickname.html', controller: 'SearchNicknameCtrl'})
    .when('/compare', {templateUrl: 'partials/compare.html', controller: 'CompareCtrl'})
    .when('/stats', {templateUrl: 'partials/stats.html', controller: 'StatsCtrl'})
    .otherwise({ redirectTo: '/' })
]

app.constant 'DB_CONFIG', { BASE_URL: '/api/db/' }

app.run ['$rootScope', '$location', '$window', 'Settings', ($rootScope, $location, $window, Settings) ->
  $rootScope.difficulties = ['Hexagon', 'Hexagoner', 'Hexagonest', 'Hyper Hexagon', 'Hyper Hexagoner', 'Hyper Hexagonest']

  $rootScope.$on '$routeChangeStart', ->
    $rootScope.isViewLoading = true

    Settings.all(
      (data) ->
        $rootScope.settings = {}
        for setting in data
          $rootScope.settings[setting.key] = setting.value
    )
  $rootScope.$on '$routeChangeSuccess', ->
    $rootScope.isViewLoading = false
    if $window._gaq?
      $window._gaq.push(['_trackPageview', $location.path()]);

  $rootScope.getAvatar = (url, size = '') ->
    # size is null (small), medium, full
    if size != ''
      size = '_' + size
    'http://media.steampowered.com/steamcommunity/public/images/avatars/' + url + size + '.jpg'

  $rootScope.search =
    options:
      usersCustomUrl:
        group: 'Users'
        label: 'Custom profile URL'
      usersSteamId:
        group: 'Users'
        label: 'Steam ID'
        placeholder: 'Profile number'
      usersNickname:
        group: 'Users'
        label: 'Nickname search'
        placeholder: 'Search Steam nicknames'
      groupsId:
        group: 'Groups'
        label: 'Group ID'
        placeholder: 'Group number'
      groupsCustomUrl:
        group: 'Groups'
        label: 'Custom group URL'
    type: 'usersNickname'
    text: ''
    doSearch: ->
      if !!@text
        switch @type
          when 'usersCustomUrl'
            $location.path "/id/#{$rootScope.search.text}"
          when 'usersSteamId'
            $location.path "/profiles/#{$rootScope.search.text}"
          when 'usersNickname'
            $location.path("/search/nickname/#{$rootScope.search.text}")
          when 'groupsCustomUrl'
            $location.path "/groups/#{$rootScope.search.text}"
          when 'groupsId'
            $location.path "/gid/#{$rootScope.search.text}"

  # comparison

  unless localStorage.getItem('comparison')
    localStorage.setItem('comparison', '[]')

  $rootScope.comparison = JSON.parse localStorage.getItem('comparison')

  $rootScope.comparisonRemove = (steamid) ->
    new_comparison = []
    for entry in $rootScope.comparison
      new_comparison.push entry unless entry.steamid == steamid
    $rootScope.comparison = new_comparison
    localStorage.setItem 'comparison', angular.toJson($rootScope.comparison)

  $rootScope.comparisonRemoveAll = ->
    localStorage.setItem 'comparison', '[]'
    $rootScope.comparison = []
]
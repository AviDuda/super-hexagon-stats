(function() {
  "use strict";

  var app;

  app = angular.module('hexagonStats', ['ui', 'ui.bootstrap', 'dbResourceHttp']);

  app.config([
    '$routeProvider', function($routeProvider) {
      return $routeProvider.when('/', {
        templateUrl: 'partials/home.html',
        controller: 'HomeCtrl'
      }).when('/leaderboard/:leaderboard', {
        templateUrl: 'partials/leaderboard.html',
        controller: 'LeaderboardCtrl'
      }).when('/leaderboard', {
        templateUrl: 'partials/leaderboard.html',
        controller: 'LeaderboardCtrl'
      }).when('/profiles/:steamid64', {
        templateUrl: 'partials/profile.html',
        controller: 'ProfileCtrl'
      }).when('/id/:customurl', {
        templateUrl: 'partials/custom_url.html',
        controller: 'CustomUrlCtrl'
      }).otherwise({
        redirectTo: '/'
      });
    }
  ]);

  app.constant('DB_CONFIG', {
    BASE_URL: '/api/db/'
  });

  app.run([
    '$rootScope', '$location', '$window', 'Settings', function($rootScope, $location, $window, Settings) {
      $rootScope.difficulties = ['Hexagon', 'Hexagoner', 'Hexagonest', 'Hyper Hexagon', 'Hyper Hexagoner', 'Hyper Hexagonest'];
      $rootScope.$on('$routeChangeStart', function() {
        $rootScope.isViewLoading = true;
        return Settings.all(function(data) {
          var setting, _i, _len, _results;
          $rootScope.settings = {};
          _results = [];
          for (_i = 0, _len = data.length; _i < _len; _i++) {
            setting = data[_i];
            _results.push($rootScope.settings[setting.key] = setting.value);
          }
          return _results;
        });
      });
      $rootScope.$on('$routeChangeSuccess', function() {
        $rootScope.isViewLoading = false;
        if ($window._gaq != null) {
          return $window._gaq.push(['_trackPageview', $location.path()]);
        }
      });
      $rootScope.getAvatar = function(url, size) {
        if (size == null) {
          size = '';
        }
        if (size !== '') {
          size = '_' + size;
        }
        return 'http://media.steampowered.com/steamcommunity/public/images/avatars/' + url + size + '.jpg';
      };
      $rootScope.searchCustomUrl = function() {
        return $location.path("/id/" + $rootScope.customUrlSearch);
      };
      return $rootScope.parseTime = function(time) {};
    }
  ]);

  app.factory('Leaderboard', [
    '$dbResourceHttp', function($dbResourceHttp) {
      return $dbResourceHttp('leaderboard');
    }
  ]);

  app.factory('User', [
    '$dbResourceHttp', function($dbResourceHttp) {
      return $dbResourceHttp('users');
    }
  ]);

  app.factory('Settings', [
    '$dbResourceHttp', function($dbResourceHttp) {
      return $dbResourceHttp('settings');
    }
  ]);

  app.directive('activelink', [
    '$location', function($location) {
      return {
        restrict: 'A',
        link: function(scope, element, attrs) {
          scope.$location = $location;
          return scope.$watch('$location.path()', function(locationPath) {
            var isCorrectLocation;
            if (attrs.noactivelinkindex != null) {
              isCorrectLocation = attrs.activelink.substring(1) === locationPath;
            } else {
              isCorrectLocation = locationPath.indexOf(attrs.activelink.substring(1)) > -1;
            }
            if (attrs.activelink.length > 0 && isCorrectLocation) {
              return element.addClass('active');
            } else {
              return element.removeClass('active');
            }
          });
        }
      };
    }
  ]);

  app.factory('TableSort', function() {
    var TableSort;
    return TableSort = {
      column: '',
      descending: false,
      icons: {
        ascending: 'icon-chevron-up',
        descending: 'icon-chevron-down'
      },
      sortClass: function(column) {
        if (column === this.column) {
          if (this.descending) {
            return this.icons.descending;
          } else {
            return this.icons.ascending;
          }
        }
      },
      changeSorting: function(column) {
        if (column === this.column) {
          return this.descending = !this.descending;
        } else {
          this.column = column;
          return this.descending = false;
        }
      }
    };
  });

  app.controller('HomeCtrl', [
    '$scope', '$rootScope', 'Leaderboard', 'User', function($scope, $rootScope, Leaderboard, User) {
      var difficulty, getLeaderboard, _i, _len, _ref, _results;
      $rootScope.title = 'Home';
      $scope.difficultyRows = [['Hexagon', 'Hexagoner', 'Hexagonest'], ['Hyper Hexagon', 'Hyper Hexagoner', 'Hyper Hexagonest']];
      $scope.top10 = {};
      $scope.top10Loading = {};
      $scope.top10Users = {};
      getLeaderboard = function(difficulty) {
        return Leaderboard.query({
          difficulty: difficulty
        }, {
          sort: {
            time: -1
          },
          limit: 10,
          fields: {
            _id: 0
          }
        }, function(data) {
          var user_ids;
          $scope.top10[difficulty] = data;
          user_ids = data.map(function(entry) {
            return entry.steamid;
          });
          if (user_ids.length > 0) {
            return User.query({
              _id: {
                $in: user_ids
              }
            }, function(data) {
              var user, _i, _len;
              for (_i = 0, _len = data.length; _i < _len; _i++) {
                user = data[_i];
                $scope.top10Users[user._id] = user;
              }
              return $scope.top10Loading[difficulty] = false;
            });
          } else {
            return $scope.top10Loading[difficulty] = false;
          }
        }, function(data, status) {
          return $scope.top10Loading[difficulty] = false;
        });
      };
      _ref = $rootScope.difficulties;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        difficulty = _ref[_i];
        $scope.top10Loading[difficulty] = true;
        _results.push(getLeaderboard(difficulty));
      }
      return _results;
    }
  ]);

  app.controller('ProfileCtrl', [
    '$scope', '$rootScope', '$routeParams', '$http', 'User', function($scope, $rootScope, $routeParams, $http, User) {
      $rootScope.title = 'Profile';
      $scope.userLoading = true;
      return User.query({
        _id: $routeParams.steamid64
      }, function(data) {
        if (data[0] != null) {
          $scope.user = data[0];
          $rootScope.title = "" + $scope.user.username + "'s profile";
          return $scope.userLoading = false;
        } else {
          return $http.get('/api/profiles?steamids=' + $routeParams.steamid64).success(function(data) {
            $scope.user = data[0];
            return $scope.userLoading = false;
          }).error(function(data, status) {
            return $scope.userLoading = false;
          });
        }
      });
    }
  ]);

  app.controller('ProfileLeaderboardCtrl', [
    '$scope', '$rootScope', '$filter', 'Leaderboard', 'TableSort', function($scope, $rootScope, $filter, Leaderboard, TableSort) {
      $scope.leaderboardLoading = true;
      Leaderboard.query({
        steamid: $scope.user._id
      }, {
        sort: {
          difficulty: 1
        },
        fields: {
          _id: 0
        }
      }, function(data) {
        $scope.leaderboard = data;
        return $scope.leaderboardLoading = false;
      }, function(data, status) {
        return $scope.leaderboardLoading = false;
      });
      $scope.sort = {};
      angular.extend($scope.sort, TableSort);
      $scope.sort.column = 'difficulty';
      $scope.setFilters = function() {
        return $scope.leaderboard = $filter('orderBy')($scope.leaderboard, $scope.sort.column, $scope.sort.descending);
      };
      $scope.setFilters();
      $scope.oldChangeSorting = $scope.sort.changeSorting;
      return $scope.sort.changeSorting = function() {
        $scope.oldChangeSorting.apply(this, arguments);
        return $scope.setFilters();
      };
    }
  ]);

  app.controller('ProfileFriendsCtrl', [
    '$scope', '$rootScope', '$http', '$filter', 'Leaderboard', 'User', 'TableSort', function($scope, $rootScope, $http, $filter, Leaderboard, User, TableSort) {
      $scope.loadingAllFriends = true;
      $http.get("/api/friends/" + $scope.user._id).success(function(data) {
        $scope.allFriends = data;
        $scope.loadingAllFriends = false;
        return $scope.switchDifficultyView('all');
      }).error(function(data, status) {
        return $scope.loadingAllFriends = false;
      });
      $scope.viewDifficulties = {};
      $scope.switchDifficultyView = function(difficulty) {
        var diff, _i, _len, _ref;
        $scope.viewDifficulties[difficulty] = !$scope.viewDifficulties[difficulty];
        if (difficulty === 'all') {
          _ref = $rootScope.difficulties;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            diff = _ref[_i];
            $scope.viewDifficulties[diff] = $scope.viewDifficulties[difficulty];
          }
        }
        return $scope.getLeaderboard();
      };
      $scope.getLeaderboard = function() {
        var difficulty, query_difficulties, _i, _len, _ref;
        if ($scope.viewDifficulties['all']) {
          query_difficulties = $rootScope.difficulties;
        } else {
          query_difficulties = [];
          _ref = $rootScope.difficulties;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            difficulty = _ref[_i];
            if ($scope.viewDifficulties[difficulty]) {
              query_difficulties.push(difficulty);
            }
          }
        }
        $scope.leaderboardLoading = true;
        return Leaderboard.query({
          difficulty: {
            $in: query_difficulties
          },
          steamid: {
            $in: $scope.allFriends
          }
        }, {
          fields: {
            _id: 0
          }
        }, function(data) {
          var entry, users;
          $scope.leaderboard = data;
          users = (function() {
            var _j, _len1, _results;
            _results = [];
            for (_j = 0, _len1 = data.length; _j < _len1; _j++) {
              entry = data[_j];
              _results.push(entry.steamid);
            }
            return _results;
          })();
          users = $filter('unique')(users);
          $scope.uniqueUsersCount = users.length;
          return User.query({
            _id: {
              $in: users
            }
          }, function(data) {
            var user, _j, _k, _len1, _len2, _ref1;
            users = {};
            for (_j = 0, _len1 = data.length; _j < _len1; _j++) {
              user = data[_j];
              users[user._id] = user;
            }
            _ref1 = $scope.leaderboard;
            for (_k = 0, _len2 = _ref1.length; _k < _len2; _k++) {
              entry = _ref1[_k];
              angular.extend(entry, users[entry.steamid]);
            }
            $scope.setFilters();
            return $scope.leaderboardLoading = false;
          }, function(data, status) {
            return $scope.leaderboardLoading = false;
          });
        }, function(data) {
          return $scope.leaderboardLoading = false;
        });
      };
      $scope.sort = {};
      angular.extend($scope.sort, TableSort);
      $scope.sort.column = 'username';
      $scope.setFilters = function() {
        return $scope.leaderboard = $filter('orderBy')($scope.leaderboard, $scope.sort.column, $scope.sort.descending);
      };
      $scope.oldChangeSorting = $scope.sort.changeSorting;
      return $scope.sort.changeSorting = function() {
        $scope.oldChangeSorting.apply(this, arguments);
        return $scope.setFilters();
      };
    }
  ]);

  app.controller('CustomUrlCtrl', [
    '$scope', '$routeParams', '$http', '$location', function($scope, $routeParams, $http, $location) {
      $scope.loading = true;
      $scope.customUrl = $routeParams.customurl;
      return $http.get('/api/id/' + $routeParams.customurl).success(function(data) {
        $scope.loading = false;
        if ((data.steamid != null) && data.steamid !== '') {
          $scope.steamid = data.steamid;
          $scope.redirecting = true;
          return $location.path('/profiles/' + $scope.steamid);
        } else {
          return $scope.error = true;
        }
      }).error(function(data, status) {
        $scope.loading = false;
        return $scope.error = true;
      });
    }
  ]);

  app.controller('LeaderboardCtrl', [
    '$rootScope', function($rootScope) {
      return $rootScope.title = 'Leaderboard';
    }
  ]);

}).call(this);

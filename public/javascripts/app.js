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
        templateUrl: 'partials/users_custom_url.html',
        controller: 'UsersCustomUrlCtrl'
      }).when('/gid/:groupid', {
        templateUrl: 'partials/group.html',
        controller: 'GroupCtrl'
      }).when('/groups/:groupid', {
        templateUrl: 'partials/group.html',
        controller: 'GroupCtrl'
      }).when('/search/nickname/:nickname', {
        templateUrl: 'partials/search_nickname.html',
        controller: 'SearchNicknameCtrl'
      }).when('/compare', {
        templateUrl: 'partials/compare.html',
        controller: 'CompareCtrl'
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
      $rootScope.search = {
        options: {
          usersCustomUrl: {
            group: 'Users',
            label: 'Custom profile URL'
          },
          usersSteamId: {
            group: 'Users',
            label: 'Steam ID',
            placeholder: 'Profile number'
          },
          usersNickname: {
            group: 'Users',
            label: 'Nickname search',
            placeholder: 'Search Steam nicknames'
          },
          groupsId: {
            group: 'Groups',
            label: 'Group ID',
            placeholder: 'Group number'
          },
          groupsCustomUrl: {
            group: 'Groups',
            label: 'Custom group URL'
          }
        },
        type: 'usersNickname',
        text: '',
        doSearch: function() {
          if (!!this.text) {
            switch (this.type) {
              case 'usersCustomUrl':
                return $location.path("/id/" + $rootScope.search.text);
              case 'usersSteamId':
                return $location.path("/profiles/" + $rootScope.search.text);
              case 'usersNickname':
                return $location.path("/search/nickname/" + $rootScope.search.text);
              case 'groupsCustomUrl':
                return $location.path("/groups/" + $rootScope.search.text);
              case 'groupsId':
                return $location.path("/gid/" + $rootScope.search.text);
            }
          }
        }
      };
      if (!localStorage.getItem('comparison')) {
        localStorage.setItem('comparison', '[]');
      }
      $rootScope.comparison = JSON.parse(localStorage.getItem('comparison'));
      $rootScope.comparisonRemove = function(steamid) {
        var entry, new_comparison, _i, _len, _ref;
        new_comparison = [];
        _ref = $rootScope.comparison;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          entry = _ref[_i];
          if (entry.steamid !== steamid) {
            new_comparison.push(entry);
          }
        }
        $rootScope.comparison = new_comparison;
        return localStorage.setItem('comparison', angular.toJson($rootScope.comparison));
      };
      return $rootScope.comparisonRemoveAll = function() {
        localStorage.setItem('comparison', '[]');
        return $rootScope.comparison = [];
      };
    }
  ]);

  app.controller('CompareCtrl', [
    '$scope', '$rootScope', 'Leaderboard', function($scope, $rootScope, Leaderboard) {
      $rootScope.title = 'Compare Users';
      return $rootScope.$watch('comparison', function() {
        var entry, users_array;
        if ($rootScope.comparison.length > 0) {
          users_array = (function() {
            var _i, _len, _ref, _results;
            _ref = $rootScope.comparison;
            _results = [];
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              entry = _ref[_i];
              _results.push(entry.steamid);
            }
            return _results;
          })();
          $scope.leaderboardLoading = true;
          return Leaderboard.query({
            steamid: {
              $in: users_array
            }
          }, {
            sort: {
              steamid: 1,
              difficulty: 1
            }
          }, function(data) {
            var _i, _j, _len, _len1, _ref;
            $scope.users = {};
            _ref = $rootScope.comparison;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              entry = _ref[_i];
              $scope.users[entry.steamid] = {
                username: entry.username,
                avatar: entry.avatar,
                leaderboard: {}
              };
            }
            for (_j = 0, _len1 = data.length; _j < _len1; _j++) {
              entry = data[_j];
              $scope.users[entry.steamid].leaderboard[entry.difficulty] = entry;
            }
            $scope.leaderboardLoading = false;
            return function(data, status) {
              return $scope.leaderboardLoading = false;
            };
          });
        }
      });
    }
  ]);

  app.controller('GroupCtrl', [
    '$scope', '$rootScope', '$routeParams', '$location', '$http', '$filter', 'Leaderboard', 'User', function($scope, $rootScope, $routeParams, $location, $http, $filter, Leaderboard, User) {
      var url_type;
      $rootScope.title = 'Group';
      url_type = 'gid';
      if ($location.$$path.slice(0, 4) !== '/gid') {
        url_type = 'groups';
      }
      $scope.groupLoading = true;
      return $http.get("/api/" + url_type + "/" + $routeParams.groupid).success(function(data) {
        $scope.group = data;
        $rootScope.title = "Group " + $scope.group.name;
        return User.query({
          _id: {
            $in: data.members
          }
        }, function(data) {
          var entry, _i, _len;
          $scope.users = {};
          $scope.unique_users = [];
          for (_i = 0, _len = data.length; _i < _len; _i++) {
            entry = data[_i];
            $scope.users[entry._id] = {
              username: entry.username,
              avatar: entry.avatar,
              leaderboard: {}
            };
            $scope.unique_users.push(entry._id);
          }
          return Leaderboard.query({
            steamid: {
              $in: $scope.unique_users
            }
          }, function(data) {
            var _j, _len1;
            for (_j = 0, _len1 = data.length; _j < _len1; _j++) {
              entry = data[_j];
              $scope.users[entry.steamid].leaderboard[entry.difficulty] = entry;
            }
            return $scope.groupLoading = false;
          }, function(data, status) {
            return $scope.groupLoading = false;
          });
        }, function(data, status) {
          return $scope.groupLoading = false;
        });
      }).error(function(data, status) {
        return $scope.groupLoading = false;
      });
    }
  ]);

  app.controller('HomeCtrl', [
    '$scope', '$rootScope', '$http', 'Leaderboard', 'User', function($scope, $rootScope, $http, Leaderboard, User) {
      var difficulty, getLeaderboard, _i, _len, _ref;
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
            User.query({
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
            $scope.top10Loading[difficulty] = false;
          }
          return function(data, status) {
            return $scope.top10Loading[difficulty] = false;
          };
        });
      };
      _ref = $rootScope.difficulties;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        difficulty = _ref[_i];
        $scope.top10Loading[difficulty] = true;
        getLeaderboard(difficulty);
      }
      return $http.get('/api/latestcommits').success(function(data) {
        return $scope.latestCommits = data;
      });
    }
  ]);

  app.controller('LeaderboardCtrl', [
    '$scope', '$rootScope', '$routeParams', 'Leaderboard', 'User', function($scope, $rootScope, $routeParams, Leaderboard, User) {
      $scope.leaderboardName = $routeParams.leaderboard.replace('_', ' ');
      $rootScope.title = "Leaderboard " + $scope.leaderboardName;
      $scope.rankSort = 1;
      $scope.leaderboardLoading = true;
      $scope.pagination = {
        currentPage: 1,
        perPage: 20
      };
      Leaderboard.count({
        difficulty: $scope.leaderboardName
      }, function(data) {
        $scope.leaderboardCount = parseInt(data);
        $scope.pagination.numPages = function() {
          return Math.ceil($scope.leaderboardCount / this.perPage);
        };
        $scope.changePage();
        return function(data, status) {
          return $scope.leaderboardLoading = false;
        };
      });
      $scope.$watch('pagination.currentPage', function() {
        return $scope.changePage();
      });
      $scope.changePage = function() {
        $scope.leaderboardLoading = true;
        return Leaderboard.query({
          difficulty: $scope.leaderboardName
        }, {
          sort: {
            rank: $scope.rankSort
          },
          limit: $scope.pagination.perPage,
          skip: $scope.pagination.currentPage * $scope.pagination.perPage - $scope.pagination.perPage
        }, function(data) {
          var entry, users;
          $scope.leaderboard = data;
          users = (function() {
            var _i, _len, _results;
            _results = [];
            for (_i = 0, _len = data.length; _i < _len; _i++) {
              entry = data[_i];
              _results.push(entry.steamid);
            }
            return _results;
          })();
          User.query({
            _id: {
              $in: users
            }
          }, function(data) {
            var user, _i, _j, _len, _len1, _ref;
            users = {};
            for (_i = 0, _len = data.length; _i < _len; _i++) {
              user = data[_i];
              users[user._id] = user;
            }
            _ref = $scope.leaderboard;
            for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
              entry = _ref[_j];
              angular.extend(entry, users[entry.steamid]);
            }
            $scope.leaderboardLoading = false;
            return function(data, status) {
              return $scope.leaderboardLoading = false;
            };
          });
          return function(data, status) {
            return $scope.leaderboardLoading = false;
          };
        });
      };
      $scope.changeSorting = function() {
        if ($scope.rankSort === 1) {
          $scope.rankSort = -1;
        } else {
          $scope.rankSort = 1;
        }
        return $scope.changePage();
      };
      return $scope.sortClass = function(reverse) {
        if (reverse == null) {
          reverse = false;
        }
        if ($scope.rankSort === 1) {
          if (reverse) {
            return 'icon-chevron-down';
          } else {
            return 'icon-chevron-up';
          }
        } else {
          if (reverse) {
            return 'icon-chevron-up';
          } else {
            return 'icon-chevron-down';
          }
        }
      };
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
          User.query({
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
            $scope.leaderboardLoading = false;
            return function(data, status) {
              return $scope.leaderboardLoading = false;
            };
          });
          return function(data) {
            return $scope.leaderboardLoading = false;
          };
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

  app.controller('SearchNicknameCtrl', [
    '$scope', '$rootScope', '$routeParams', '$location', 'User', function($scope, $rootScope, $routeParams, $location, User) {
      $rootScope.title = 'Search Results';
      $scope.nickname = $routeParams.nickname;
      $scope.pagination = {
        currentPage: 1,
        perPage: 20
      };
      User.count({
        username: {
          $regex: ".*" + $scope.nickname + ".*",
          $options: 'i'
        }
      }, function(data) {
        $scope.usersCount = parseInt(data);
        $scope.pagination.numPages = function() {
          return Math.ceil($scope.usersCount / this.perPage);
        };
        return $scope.changePage();
      });
      $scope.$watch('pagination.currentPage', function() {
        return $scope.changePage();
      });
      return $scope.changePage = function() {
        $scope.usersLoading = true;
        return User.query({
          username: {
            $regex: ".*" + $scope.nickname + ".*",
            $options: 'i'
          }
        }, {
          sort: {
            username: 1
          },
          limit: $scope.pagination.perPage,
          skip: $scope.pagination.currentPage * $scope.pagination.perPage - $scope.pagination.perPage
        }, function(data) {
          $scope.users = data;
          $scope.usersLoading = false;
          if (data.length === 1) {
            $scope.redirecting = true;
            $location.path("/profiles/" + data[0]._id);
          }
          return function(data, status) {
            return $scope.usersLoading = false;
          };
        });
      };
    }
  ]);

  app.controller('UsersCustomUrlCtrl', [
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

  app.directive('comparison', [
    '$rootScope', '$compile', function($rootScope, $compile) {
      return {
        restrict: 'E',
        replace: true,
        link: function(scope, element, attrs) {
          element.css('margin', '5px');
          if (attrs.donthide == null) {
            element.css('display', 'none');
            element.parent().bind('mouseenter', function() {
              return element.css('display', 'inline');
            });
            element.parent().bind('mouseleave', function() {
              return element.css('display', 'none');
            });
          }
          return scope.addToComparison = function() {
            var comparison, entry, found, _i, _len;
            if ((attrs.steamid != null) && (attrs.username != null) && (attrs.avatar != null)) {
              comparison = JSON.parse(localStorage.getItem('comparison'));
              found = false;
              for (_i = 0, _len = comparison.length; _i < _len; _i++) {
                entry = comparison[_i];
                if (entry.steamid === attrs.steamid) {
                  found = true;
                }
              }
              if (!found) {
                comparison.push({
                  steamid: attrs.steamid,
                  username: attrs.username,
                  avatar: attrs.avatar
                });
                localStorage.setItem('comparison', angular.toJson(comparison));
                return $rootScope.comparison = comparison;
              }
            }
          };
        }
      };
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

}).call(this);

app.directive 'activelink', ['$location', ($location) ->
  restrict: 'A',
  link: (scope, element, attrs) ->
    scope.$location = $location
    scope.$watch '$location.path()', (locationPath) ->
      # if the tag has an attribute noactivelinkindex, don't search just for indexOf, locations must be the same (useful for dropdowns in menu etc.)
      if attrs.noactivelinkindex?
        isCorrectLocation = attrs.activelink.substring(1) == locationPath
      else
        isCorrectLocation = locationPath.indexOf(attrs.activelink.substring(1)) > -1

      if attrs.activelink.length > 0 and isCorrectLocation
        element.addClass('active')
      else
        element.removeClass('active')
]

app.directive 'comparison', ['$rootScope', '$compile', ($rootScope, $compile) ->
  restrict: 'E',
  replace: true,
  link: (scope, element, attrs) ->
    element.css('margin', '5px')

    unless attrs.donthide?
      element.css('display', 'none')
      element.parent().bind 'mouseenter', ->
        element.css('display', 'inline')
      element.parent().bind 'mouseleave', ->
        element.css('display', 'none')
    scope.addToComparison = ->
      if attrs.steamid? and attrs.username? and attrs.avatar?
        comparison = JSON.parse(localStorage.getItem('comparison'))
        found = false
        for entry in comparison
          found = true if entry.steamid == attrs.steamid
        unless found
          comparison.push { steamid: attrs.steamid, username: attrs.username, avatar: attrs.avatar }
          localStorage.setItem('comparison', angular.toJson(comparison))
          $rootScope.comparison = comparison
]
app.filter 'startFrom', ->
  (input, start) ->
    start = +start
    input.slice(start)

app.filter 'newlines', ->
  (text) ->
    text.replace /\n/g, '<br>'
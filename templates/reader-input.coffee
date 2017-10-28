module.exports = (options={}) ->
  input = document.createElement('input')
  input.type = "file"
  input.setAttribute "accept", options.accept

  input.onchange = (e) ->
    options.select? input.files[0]

  return input

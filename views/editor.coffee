module.exports = (client) ->
  {application, system, UI, util} = client
  {FileIO} = util

  ace.require("ace/ext/language_tools")

  {MenuBar, Modal, Observable, Progress, Table, Util:{parseMenu}, Window} = UI

  # system.Achievement.unlock "Notepad.exe"

  element = document.createElement "editor"
  aceElement = document.createElement "section"
  element.appendChild aceElement

  aceEditor = ace.edit aceElement
  aceEditor.$blockScrolling = Infinity
  aceEditor.setOptions
    fontSize: "16px"
    enableBasicAutocompletion: true
    enableLiveAutocompletion: true
    highlightActiveLine: true

  session = aceEditor.getSession()
  session.setUseSoftTabs true
  session.setTabSize 2

  mode = "coffee"
  session.setMode("ace/mode/#{mode}")

  global.aceEditor = aceEditor

  modes =
    cson: "coffee"
    jadelet: "jade"
    js: "javascript"
    md: "markdown"
    styl: "stylus"
    txt: "text"

  mimes =
    html: "text/html"
    js: "application/javascript"
    json: "application/json"
    md: "text/markdown"

  mimeTypeFor = (extension) ->
    type = mimes[extension] or "text/plain"

    "#{type}; charset=utf-8"

  setModeFor = (path) ->
    extension = extensionFor(path)
    mode = modes[extension] or extension

    session.setMode("ace/mode/#{mode}")

  initSession = (file, path) ->
    file.readAsText()
    .then (content) ->
      if path
        handlers.currentPath path

      setModeFor(path or file.name)

      session.setValue(content)
      handlers.saved true

  session.on "change", ->
    handlers.saved false

  handlers = FileIO
    loadFile: initSession
    newFile: ->
      session.setValue ""
      session.setMode("ace/mode/coffee")
    saveData: ->
      mimeTypeFor(extensionFor(handlers.currentPath()))
      .then (type) ->
        new Blob [session.getValue()], type: type
    resize: ->
      aceEditor.resize()

  menuBar = MenuBar
    items: parseMenu """
      [F]ile
        [N]ew
        [O]pen
        [S]ave
        Save [A]s
        -
        E[x]it
      [H]elp
        View [H]elp
        -
        [A]bout
    """
    handlers: handlers

  title = Observable ->
    path = handlers.currentPath()
    if handlers.saved()
      savedIndicator = ""
      application.saved true
    else
      savedIndicator = "*"
      application.saved false

    if path
      path = " - #{path}"

    "Ace#{path}#{savedIndicator}"

  title.observe application.title

  element.insertBefore menuBar.element, element.firstChild

  handlers.element = element

  return handlers

extensionFor = (path) ->
  result = path.match /\.([^.]+)$/

  if result
    result[1]

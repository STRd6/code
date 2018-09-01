module.exports = (client) ->
  {application, system, UI, util} = client
  {FileIO} = util

  {MenuBar, Modal, Observable, Progress, Table, Util:{parseMenu}, Window} = UI

  proxy = URL.createObjectURL(new Blob(["""
    self.MonacoEnvironment = {
      baseUrl: 'https://unpkg.com/monaco-editor@0.8.3/min/'
    };
    importScripts('https://unpkg.com/monaco-editor@0.8.3/min/vs/base/worker/workerMain.js');
  """], { type: 'text/javascript' }));

  window.require.config
    paths:
      vs: 'https://unpkg.com/monaco-editor@0.8.3/min/vs'

  window.MonacoEnvironment =
    getWorkerUrl: -> proxy

  element = document.createElement 'editor'
  monacoElement = document.createElement "section"
  element.appendChild monacoElement
  
  monacoEditor = null

  # Configuration options:
  #   https://microsoft.github.io/monaco-editor/api/interfaces/monaco.editor.ieditoroptions.html

  window.require ["vs/editor/editor.main"], ->
    monacoEditor = monaco.editor.create monacoElement,
      value: """
      	function x() {
      	  console.log("Hello world!");
      	}
      	
      	x();
      """
      fontLigatures: true
      fontSize: 16
      language: 'javascript'
      theme: 'vs-light'

    monacoEditor.addListener 'didType', ->
      handlers.saved false

    window.monacoEditor = monacoEditor

  modes =
    coffee: "coffeescript"
    cson: "coffeescript"
    jadelet: "pug"
    js: "javascript"
    md: "markdown"
    styl: "stylus"
    txt: "text"

  mimeTypeFor = (path) ->
    system.mimeTypeFor(path)
    .then (type) ->
      "#{type}; charset=utf-8"

  setModeFor = (path) ->
    extension = extensionFor(path)

    monaco.editor.setModelLanguage(monacoEditor.getModel(), modes[extension] or extension)

  initSession = (file, path) ->
    file.readAsText()
    .then (content) ->
      if path
        handlers.currentPath path

      setModeFor(path or file.name)

      monacoEditor.setValue(content)
      handlers.saved true

  handlers = FileIO
    loadFile: initSession
    newFile: ->
      monacoEditor.setValue ""
    saveData: ->
      mimeTypeFor(handlers.currentPath())
      .then (type) ->
        new Blob [monacoEditor.getValue()], type: type
    resize: ->
      monacoEditor.layout()

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
    else
      savedIndicator = "*"

    if path
      path = " - #{path}"

    "Monaco#{path}#{savedIndicator}"

  title.observe application.title

  element.insertBefore menuBar.element, element.firstChild

  handlers.element = element

  return handlers

extensionFor = (path) ->
  result = path.match /\.([^.]+)$/

  if result
    result[1]

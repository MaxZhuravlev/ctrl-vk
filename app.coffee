APP_NAME = 'ctrl-vk'
CLIENT_ID = 3427457
AUTHORIZATION_URI = 'https://api.vkontakte.ru/oauth/authorize'
REDIRECT_URI = 'http://api.vk.com/blank.html' # redirect uri for vk.com
API_URI = 'https://api.vk.com' # api uri for vk.com
storage = chrome.storage.local

dev = yes

unless dev
  console.log = console.error = ->

window.onload = () ->
  window.app = new App

  if app.isAuth()
    unless app.getSettings 'album_id'
      do app.saveAlbumId

    window.vk = new Vk
      client_id: CLIENT_ID
      authorization_uri: AUTHORIZATION_URI
      redirect_uri: REDIRECT_URI
      api_url: API_URI
      access_token: app.getSettings 'access_token'
      album_id: app.getSettings 'album_id'

    document.onpaste = (event) =>
      app.processClipboard item for item in event.clipboardData.items

  else
    if RegExp(REDIRECT_URI).test location.href
      storage.set authorize_url: location.href
      # here we pass request to background.js to close this tab
    else
      do app.startAuthorize


class App
  constructor: ->
    console.log 'app start'


  saveAlbumId: ->
    save = =>
      if aid = prompt 'Введите id альбома в который будут загружаться изображения'
        if aid.match(/\d{1,9}/)
          @setSettings 'album_id', aid
          yes
        else
          no
      else
        no

    ok = save() until ok is true

  isAuth: ->
    @getSettings('access_token') and @getSettings('is_auth')


  getSettings: (name) ->
    data = JSON.parse localStorage.getItem APP_NAME
    return console.log "your settings (#{name}) are empty" unless data
    return data[name]


  setSettings: (name, value) ->
    data = JSON.parse localStorage.getItem APP_NAME
    data = data or {}
    data[name] = value
    localStorage.setItem APP_NAME, JSON.stringify data


  startAuthorize: ->
    open Vk.makeAuthorizeUrl() # call a class method
    console.log 'open new tab with auth url..'

    intr_id = setInterval (->
      storage.get 'authorize_url', (data) ->
        app.finishAuthorize data.authorize_url
        #storage.set authorize_url: null
        clearInterval intr_id
      ), 300


  finishAuthorize: (url) ->
    for param in ['access_token', 'expires_in', 'user_id']
      @setSettings param, url.getParam param
    @setSettings 'is_auth', yes
    do @saveAlbumId unless @getSettings 'album_id'


  processClipboard: (item) ->
    if /^image/.test item['type']

      blob = item.getAsFile()
      reader = new FileReader

      reader.readAsDataURL blob

      # If you want to upload it instead, you could use readAsBinaryString,
      # or you could probably put it into an XHR using FormData
      # https://developer.mozilla.org/en/XMLHttpRequest/FormData
      reader.onload = (event) ->
        console.log event.target.result
        binaryString = event.target.result

        vk.getUploadUrl (data) =>
          image = new FormData
          image.append 'photo', binaryString, 'photo.png'
          upload_url = data.response.upload_url

          vk.uploadImage image, to: upload_url, (data) =>
            vk.saveImage data, (data) =>
              if data.error
                alert data.error.error_msg
              else
                alert 'fuck yeah!'

                button = $('.add_media_type_2_photo')[0]
                console.log(button)

                if button.click()
                  console.log 'add_media_type_2_photo click'

      reader.readAsBinaryString blob

class Vk
  constructor: (params = {}) ->
    $.extend @, params

  makeUrl: (base, method, prms) ->
    params = []
    params.push "#{name}=#{value}" for name, value of prms
    params = params.join '&'

    return if method is 'auth'
      "#{base}?#{params}"
    else
      "#{base}/method/#{method}?#{params}"


  @makeAuthorizeUrl: ->
    params =
      client_id: CLIENT_ID
      scope: 'photos'
      display: 'popup'
      redirect_uri: REDIRECT_URI
      response_type: 'token'

    # because vk object yet is not created, we use class method
    Vk.prototype.makeUrl AUTHORIZATION_URI, 'auth', params


  getUploadUrl: (callback) ->
    params =
      access_token: @access_token
      aid: @album_id
      save_big: 1

    url = @makeUrl @api_url, 'photos.getUploadServer', params
    @request url, null, 'GET', callback


  uploadImage: (image, url_param, callback) ->
    @request url_param.to, image, 'POST', callback


  saveImage: (params, callback) ->
    if typeof params is 'string'
      params = JSON.parse params
    album_id = parseInt app.getSettings 'album_id'
    $.extend params,
      caption: "#{Date.now()} #{Math.random().toFixed(3)}"
      access_token: @access_token

    url = @makeUrl @api_url, 'photos.save', params
    @request url, null, 'GET', callback


  request: (url, data, type = 'GET', callback) ->
    xhr = $.ajax
      url: url, data: data, type: type, success: callback
      contentType: off, processData: off, cache: off

    xhr.fail () ->
      console.error arguments

    xhr.always () ->
      console.log arguments


String.prototype.getParam = (name) ->
  reg = "[\\?&#]#{name}=([A-z,0-9]*)"
  results = RegExp(reg).exec this.toString()

  return if results?.length is 2
    decodeURIComponent(results[1])
  else null


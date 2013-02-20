APP_NAME = 'ctrl-vk'
CLIENT_ID = 3427457
AUTHORIZATION_URI = 'https://api.vkontakte.ru/oauth/authorize'
REDIRECT_URI = 'http://api.vk.com/blank.html'
API_URI = 'https://api.vk.com'
storage = chrome.storage.local
dev = yes

window.onload = () ->
  window.app = new App

  if app.isAuth()
    do app.init
  else
    if RegExp(REDIRECT_URI).test location.href
      storage.set authorize_url: location.href
      chrome.extension.sendMessage what_to_do: 'close_me'
    else
      do app.startAuthorize


class App
  init: ->
    console.log 'app start'

    unless @getSettings 'album_id'
      do @saveAlbumId

    window.vk = new Vk
      client_id: CLIENT_ID
      authorization_uri: AUTHORIZATION_URI
      redirect_uri: REDIRECT_URI
      api_url: API_URI
      access_token: app.getSettings 'access_token'
      album_id: app.getSettings 'album_id'

    do @bindPasteHandler


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
    @getSettings 'access_token'


  getSettings: (name) ->
    data = JSON.parse localStorage.getItem APP_NAME
    return console.log "your settings (#{name}) are empty" unless data
    data[name]


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
        if data.authorize_url
          app.finishAuthorize data.authorize_url
          storage.set authorize_url: null
          clearInterval intr_id
      ), 300


  finishAuthorize: (url) ->
    for param in ['access_token', 'expires_in', 'user_id']
      @setSettings param, url.getParam param
    do @init


  bindPasteHandler: ->
    document.onpaste = (event) =>
      app.upload item for item in event.clipboardData.items


  upload: (item) ->
    if /^image\/png/.test item['type']
      blob = item.getAsFile()
      reader = new FileReader

      reader.onload = (event) ->
        console.log event.target.result
        binaryString = event.target.result

        vk.getUploadUrl (data) =>
          if data.error
            return alert data.error.error_msg

          image = new FormData
          image.append 'photo', dataURIToBlob(binaryString), 'photo.png'
          upload_url = data.response.upload_url

          vk.uploadImage image, to: upload_url, (data) =>
            vk.saveImage data, (data) =>
              if data.error
                alert data.error.error_msg
              else
                photo = data.response[0]

                base = photo.src_small.match(/http:\/\/cs\d+\.userapi\.com\/v\d+\//)[0]
                x = photo.src_small.match(/[a-zA-Z0-9]+\/[a-zA-Z0-9]+(?=\.jpg)/)[0]
                mini = JSON.stringify temp: base: base, x_: [x, 50, 50]

                photodata = JSON.stringify
                  type: 'photo'
                  id: "#{photo.owner_id}_#{photo.pid}"
                  mini: mini
                  src_big: photo.src_big
                  src: photo.src
                  hash: ''

                do $('#im_add_media_link').click
                #block.css 'display', 'none'

                inline_js = "
                  var photo = JSON.parse(event.target.dataset.photodata);
                  window.cur.chooseMedia(photo.type,  photo.id, [photo.src_big, photo.src, photo.hash, photo.mini]);
                "

                block = $("<a data-photodata='#{photodata}' onclick='#{inline_js}'>hello from ctrl-vk</a>")

                $('#side_bar').append block

                setTimeout (-> do block.click), 777

      reader.readAsDataURL blob


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
    @request url, off, 'GET', callback


  uploadImage: (image, url_param, callback) ->
    @request url_param.to, image, 'POST', callback


  saveImage: (params, callback) ->
    params = JSON.parse params if typeof params is 'string'

    $.extend params,
      caption: "#{Date.now()} #{Math.random().toFixed(3)}"
      access_token: @access_token

    url = @makeUrl @api_url, 'photos.save', params
    @request url, off, 'GET', callback


  request: (url, data, type = 'GET', callback) ->
    xhr = $.ajax
      url: url, data: data, type: type, success: callback
      contentType: off, processData: off, cache: off

    xhr.fail () ->
      console.error arguments

    xhr.always () ->
      console.log arguments

unless dev
  console.log = console.error = ->

String.prototype.getParam = (name) ->
  reg = "[\\?&#]#{name}=([A-z,0-9]*)"
  results = RegExp(reg).exec this.toString()

  return if results?.length is 2
    decodeURIComponent(results[1])
  else null


window.dataURIToBlob = (dataURI) ->
  byteString = atob dataURI.split(',')[1]
  ab = []; ab.push byteString.charCodeAt key for _ , key in byteString
  mimeString = dataURI.split(',')[0].split(':')[1].split(';')[0]
  new Blob [new Uint8Array ab], type: mimeString

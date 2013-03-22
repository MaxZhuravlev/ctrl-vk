APP_NAME = 'ctrl-vk'
CLIENT_ID = 3427457
AUTHORIZATION_URI = 'https://api.vkontakte.ru/oauth/authorize'
REDIRECT_URI = 'http://api.vk.com/blank.html'
API_URI = 'https://api.vk.com'
localStorage = chrome.storage.local
syncStorage = chrome.storage.sync
dev = yes

window.onload = () ->
  window.app = new App

  if RegExp('chrome-extension://.*/options.html').test location.href
    do app.optionsPage
  else
    do app.init


class App

  optionsPage: ->
    console.log 'options page'
    syncStorage.get ["album_link", "album_id"], (items) ->
      console.log items
      return  unless items.album_link
      $("#album_link").val items.album_link
    document.querySelector("#save_button").addEventListener "click", ->
      matched_album_id = $("#album_link").val().match(/album\d+_(\d+)/)[1]
      syncStorage.set
        album_link: $("#album_link").val()
        album_id: matched_album_id
      , ->
        status = document.getElementById("status")
        status.innerHTML = chrome.i18n.getMessage("saved")
        setTimeout (->
          status.innerHTML = ""
        ), 750
    document.getElementById("album_link_span").innerHTML = chrome.i18n.getMessage("album_link");
    document.getElementById("save_button").innerHTML = chrome.i18n.getMessage("save_button");

  init: ->
    console.log 'app start'

    #todo: автоматическое создание дефолтового шаблона, если шаблон не задан
    #unless @getSettings 'album_id'
    #  do @saveAlbumId

    syncStorage.get ["album_id", "access_token"], (items) ->
      console.log items
      unless items.access_token
        if RegExp(REDIRECT_URI).test location.href
          localStorage.set authorize_url: location.href
          chrome.extension.sendMessage what_to_do: 'close_me'
        else
          do app.startAuthorize
      unless items.album_id
        alert "пожалуйста задайте album id";
      window.vk = new Vk
        client_id: CLIENT_ID
        authorization_uri: AUTHORIZATION_URI
        redirect_uri: REDIRECT_URI
        api_url: API_URI
        access_token: items.album_id
        album_id: items.access_token

      do app.bindPasteHandler

  startAuthorize: ->
    open Vk.makeAuthorizeUrl() # call a class method
    console.log 'open new tab with auth url..'

    intr_id = setInterval (->
      localStorage.get 'authorize_url', (data) ->
        if data.authorize_url
          app.finishAuthorize data.authorize_url
          localStorage.set authorize_url: null
          clearInterval intr_id
      ), 300


  finishAuthorize: (url) ->
    for param in ['access_token', 'expires_in', 'user_id']
      syncStorage.set
        param: url.getParam param
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
                vk.chooseMedia data.response[0]

      reader.readAsDataURL blob


class Vk
  constructor: (params = {}) ->
    $.extend @, params

  chooseMedia: (photo) ->
    base = photo.src_small.match(/http:\/\/cs\d+\.(userapi\.com|vk\.me)\/v\d+\//)[0]
    x = photo.src_small.match(/[a-zA-Z0-9]+\/[a-zA-Z0-9_-]+(?=\.jpg)/)[0]
    mini = JSON.stringify temp: base: base, x_: [x, 50, 50]

    photo_data = JSON.stringify
      type: 'photo'
      id: "#{photo.owner_id}_#{photo.pid}"
      mini: mini
      src_big: photo.src_big
      src: photo.src
      hash: ''

    do $('#im_add_media_link').click
    do $('#im_user_holder').click
    do $('#ctrl-vk').remove

    inline_js = '
      var photo = JSON.parse(event.target.dataset.photo);
      window.cur.chooseMedia(photo.type,  photo.id, [photo.src_big, photo.src, photo.hash, photo.mini]);'

    block = $("<a data-photo='#{photo_data}' onclick='#{inline_js}' id='ctrl-vk'>hello from ctrl-vk</a>")
    block.css 'display', 'none'

    $('#side_bar').append block

    do block.click

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
      scope: 'photos,offline'
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

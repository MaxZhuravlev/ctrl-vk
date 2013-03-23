APP_NAME = 'ctrl-vk'
CLIENT_ID = 3427457
AUTHORIZATION_URI = 'https://api.vkontakte.ru/oauth/authorize'
REDIRECT_URI = 'http://api.vk.com/blank.html'
API_URI = 'https://api.vk.com'
OPTIONS_URI = 'chrome-extension://.*/options.html'
syncStorage = chrome.storage.sync
dev = yes

window.onload = () ->
  window.app = new App

  if app.isAuth()
    if RegExp(OPTIONS_URI).test location.href
      do app.optionsPage
    else
      do app.init
  else
    if RegExp(REDIRECT_URI).test location.href
      syncStorage.set authorize_url: location.href
      chrome.extension.sendMessage what_to_do: 'close_me'
    else
      do app.startAuthorize


class App

  optionsPage: ->
    console.log 'options page'

    syncStorage.get ['album_link', 'album_id'], (items) ->
      console.log items
      return unless items.album_link
      $('#album_link').val items.album_link

    $('#save_button').click ->
      syncStorage.set
        album_link: $('#album_link').val()
        album_id: $("#album_link").val().match(/album\d+_(\d+)/)[1]
      , ->
        $('#status').html chrome.i18n.getMessage 'saved'
        console.log $('#status').html()
        setTimeout (->
          $('#status').html ''
        ), 750

    $('#auto_button').click ->
      syncStorage.get 'access_token_for_creating_album', (items) ->
        window.vk = new Vk
          api_url: API_URI
          access_token: items.access_token_for_creating_album


        vk.createAlbum (data) ->
          aid = data.response.aid
          owner_id = data.response.owner_id
          album_link = "http://vk.com/album#{owner_id}_#{aid}"

          syncStorage.set
            album_link: album_link
            album_id: aid

          do location.reload


    $('#album_link_span').html chrome.i18n.getMessage 'album_link'
    $('#save_button').html chrome.i18n.getMessage 'save_button'


  init: ->
    console.log 'app start'

    #TODO: автоматическое создание дефолтового шаблона, если шаблон не задан
    unless @getSettings 'album_id'
      return do @saveAlbumId

    window.vk = new Vk
      client_id: CLIENT_ID
      authorization_uri: AUTHORIZATION_URI
      redirect_uri: REDIRECT_URI
      api_url: API_URI
      access_token: app.getSettings 'access_token'
      album_id: app.getSettings 'album_id'

    do app.bindPasteHandler


  saveAlbumId: ->
    syncStorage.get ['album_link', 'album_id'], (items) =>
      console.log items # FIXME there is no album_link property

      if items.album_id
        @setSettings 'album_id', items.album_id
      else
        alert chrome.i18n.getMessage 'please_set_album_link'
        # TODO redirect to settings page
        # now we should open settings page manually


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
    result=JSON.stringify data
    if(result!="undefined")
      localStorage.setItem APP_NAME, JSON.stringify data
    console.log 'syncStorage', data


  startAuthorize: ->
    open Vk.makeAuthorizeUrl() # call a class method
    console.log 'open new tab with auth url..'

    intr_id = setInterval (->
      syncStorage.get 'authorize_url', (data) ->
        if data.authorize_url
          app.finishAuthorize data.authorize_url
          syncStorage.set authorize_url: null
          syncStorage.set access_token_for_creating_album: app.getSettings 'access_token'
          clearInterval intr_id

          if RegExp(OPTIONS_URI).test location.href
            do location.reload
      ), 300


  finishAuthorize: (url) ->
    for param in ['access_token', 'expires_in', 'user_id']
      @setSettings param, url.getParam param
    do @init


  bindPasteHandler: ->
    document.onpaste = (event) =>
      app.upload item for item in event.clipboardData.items


  loaders: (act) ->
    tmpl = "
      <div class='im_preview_photo_wrap inl_bl ctrl-vk-loader '>
        <div class='im_preview_photo'>
          <img style='width:50px;height:50px;' src='"+chrome.extension.getURL('images/ajax-loader-large.gif')+"' class='im_preview_photo'> </img>
        </div>
      </div>"

    if act is 'add'
      $('#im_media_preview').append tmpl
    else if act is 'remove'
      do $('#im_media_preview .ctrl-vk-loader:first').remove


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

          app.loaders 'add'

          image = new FormData
          image.append 'photo', dataURIToBlob(binaryString), 'photo.png'
          upload_url = data.response.upload_url

          vk.uploadImage image, to: upload_url, (data) =>
            vk.saveImage data, (data) =>
              app.loaders 'remove'
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
    do $("#add_media_menu_2").hide

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


  createAlbum: (callback) ->
    params =
      access_token: @access_token
      title: 'ctrl-vk'
      description: chrome.i18n.getMessage 'auto_album_description'
      comment_privacy: 3
      privacy: 3

    url = @makeUrl @api_url, 'photos.createAlbum', params
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
APP_NAME = 'ctrl-vk'
CLIENT_ID = 3427457
AUTHORIZATION_URI = 'https://api.vkontakte.ru/oauth/authorize'
REDIRECT_URI = 'http://api.vk.com/blank.html'
API_URI = 'https://api.vk.com'
IS_OPTIONS_PAGE = window.location.href is chrome.extension.getURL 'options.html'
IS_AUTH_PAGE =  RegExp(REDIRECT_URI).test location.href
dev = yes

syncStorage = chrome.storage[ if dev then 'local' else 'sync' ]

#chrome.extension.sendRequest({tab_create: chrome.extension.getURL("options.html")});

window.onload = () ->
  window.app = new App

  syncStorage.get APP_NAME, (items) ->
    console.log 'data from syncStorage', items[APP_NAME]

    app.options = items[APP_NAME] if items[APP_NAME]

    if app.isAuth()
      if IS_OPTIONS_PAGE
        #1.1
        do app.optionsPage
      else
        #1.2
        do app.init
    else
      if IS_AUTH_PAGE
        syncStorage.set authorize_url: location.href
        chrome.extension.sendMessage what_to_do: 'close_me'
      else
        #2.2
        do app.startAuthorize


class App

  options: {}

  optionsPage: ->
    console.log 'options page'

    $('#album_link').val app.options.album_link

    $('#save_button').click =>
      @setSettings 'album_link', $('#album_link').val()
      @setSettings 'album_id', $("#album_link").val().match(/album\d+_(\d+)/)[1]

      $('#status').html chrome.i18n.getMessage 'saved'
      console.log $('#status').html()
      setTimeout (->
        $('#status').html ''
      ), 7500

    $('#auto_button').tooltip
      'title': chrome.i18n.getMessage 'auto_button_tooltip'

    $('#auto_button').click ->
      window.vk = new Vk
        api_url: API_URI
        access_token: app.options.access_token



      do vk.chooseAlbum chrome.i18n.getMessage 'first_auto_album_description'

    $('#album_link_span').html chrome.i18n.getMessage 'album_link'
    $('#save_button').html chrome.i18n.getMessage 'save_button'
    $('#auto_button').html chrome.i18n.getMessage 'auto_button'
    $('#slogan').html chrome.i18n.getMessage 'slogan'


  init: ->
    console.log 'app start'

    if app.hasAlbum()
      window.vk = new Vk
        client_id: CLIENT_ID
        authorization_uri: AUTHORIZATION_URI
        redirect_uri: REDIRECT_URI
        api_url: API_URI
        access_token: app.options.access_token
        album_id: app.options.album_id

      hasValidAlbum=null;

      vk.getAlbum app.options.album_id, (data) ->

        albums = []
        albums.push a for a in data.response

        if albums.length is 0
          # такого альбома у юзера нет
          hasValidAlbum=false
        else
          album = albums[albums.length-1]
          if(album.size<500)
            hasValidAlbum=true
          else
            hasValidAlbum=false

        unless hasValidAlbum
          # если альбом ранее задавался со страницы настроек, то второй и последующие разы создаём его автоматически. чтоб юзер лишний раз не кликал.
          return vk.chooseAlbum chrome.i18n.getMessage 'second_auto_album_description'


    else
      #в первый раз открываем страницу настроек, чтобы юзер мог сам указать желаемый альбом
      return do @fistTimeAlbumChoose


    do app.bindPasteHandler


  fistTimeAlbumChoose: ->
    unless IS_OPTIONS_PAGE
      open chrome.extension.getURL("options.html")


  isAuth: ->
    app.options.access_token

  hasAlbum: ->
    return app.options.album_id

  setSettings: (name, value) ->
    app.options[name] = value
    syncStorage.set 'ctrl-vk': app.options


  startAuthorize: ->
    open Vk.makeAuthorizeUrl() # call a class method
    console.log 'open new tab with auth url..'

    intr_id = setInterval (->
      syncStorage.get 'authorize_url', (data) ->
        if data.authorize_url
          app.finishAuthorize data.authorize_url
          syncStorage.set authorize_url: null
          clearInterval intr_id

          do location.reload
      ), 300


  finishAuthorize: (url) ->
    console.log "finishAuthorize"
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


  chooseAlbum: (comment_for_new_album, callback) ->
    @getAlbums (data) ->
      # TODO make sorting by updating date
      albums = []
      regexp = /ctrl-vk/
      albums.push a for a in data.response when (regexp.test a.title) && (a.size<500)


      if albums.length is 0
        vk.createAlbum comment_for_new_album, (data) =>
          aid = data.response.aid
          owner_id = data.response.owner_id
          album_link = "http://vk.com/album#{owner_id}_#{aid}"

          app.setSettings 'album_link', album_link
          app.setSettings 'album_id', aid

          do location.reload
      else
        album = albums[albums.length-1]
        aid = album.aid
        owner_id = album.owner_id
        album_link = "http://vk.com/album#{owner_id}_#{aid}"

        app.setSettings 'album_link', album_link
        app.setSettings 'album_id', aid

        do location.reload


  createAlbum: (comment_for_new_album, callback) ->
    params =
      access_token: @access_token
      title: 'ctrl-vk'
      description: unescape encodeURIComponent comment_for_new_album #http://mabp.kiev.ua/2008/04/02/encoding_decoding_utf_in_javascript/
      comment_privacy: 3
      privacy: 3

    url = @makeUrl @api_url, 'photos.createAlbum', params
    @request url, off, 'GET', callback


  getAlbums: (callback) ->
    params =
      access_token: @access_token

    url = @makeUrl @api_url, 'photos.getAlbums', params
    @request url, off, 'GET', callback

  getAlbum: (aid, callback) ->
    params =
      access_token: @access_token
      aids: aid

    url = @makeUrl @api_url, 'photos.getAlbums', params
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
APP_NAME = 'ctrl-vk'
CLIENT_ID = 3427457
AUTHORIZATION_URI = 'https://api.vkontakte.ru/oauth/authorize'
REDIRECT_URI = 'http://api.vk.com/blank.html'
API_URI = 'https://api.vk.com'
IS_OPTIONS_PAGE = window.location.href is chrome.extension.getURL 'options.html'
IS_AUTH_PAGE =  RegExp(REDIRECT_URI).test location.href
OPTIONS_PAGE_OPENED =  no

dev = no

syncStorage = chrome.storage[ if dev then 'local' else 'sync' ]
getMessage = chrome.i18n.getMessage

window.onload = () ->
  window.app = new App

  syncStorage.get APP_NAME, (items) ->
    console.log 'data from syncStorage', items[APP_NAME]

    app.options = items[APP_NAME] if items[APP_NAME]

    if app.isAuth()
      if IS_OPTIONS_PAGE
        do app.optionsPage
      else
        do app.init
    else
      if IS_AUTH_PAGE
        syncStorage.set authorize_url: location.href
        chrome.extension.sendMessage what_to_do: 'close_me'
      else
        do app.startAuthorize


class App

  options: {}

  optionsPage: ->
    console.log 'options page'

    $('#album_link').val app.options.album_link

    $('#save_button').click =>
      @setSettings 'album_link', $('#album_link').val()
      @setSettings 'album_id', $("#album_link").val().match(/album\d+_(\d+)/)[1]

      $('#status').html getMessage 'saved'
      console.log $('#status').html()
      setTimeout (->
        $('#status').html ''
      ), 7500

    $('#auto_button').tooltip
      'title': getMessage 'auto_button_tooltip'

    $('#auto_button').click ->
      window.vk = new Vk
        api_url: API_URI
        access_token: app.options.access_token

      do vk.chooseAlbum getMessage 'first_auto_album_description'

    $('#album_link_span').html getMessage 'album_link'
    $('#save_button').html getMessage 'save_button'
    $('#auto_button').html getMessage 'auto_button'
    $('#slogan').html getMessage 'slogan'
    $('#nameMax').html getMessage 'nameMax'
    $('#nameRoma').html getMessage 'nameRoma'
    $('.or').html getMessage 'or'
    if /mac/i.test navigator.platform
      $('#key').attr 'src', 'images/cmd.png'
      $('#key').attr 'class', 'cmd'


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

      has_valid_album = no

      vk.getAlbum app.options.album_id, (data) ->

        albums = []
        albums.push a for a in data.response

        if albums.length is 0
          # такого альбома у юзера нет
          has_valid_album = no
        else
          album = albums[albums.length-1]
          if album.size < 500
            has_valid_album = yes
          else
            has_valid_album = no

        unless has_valid_album
          # если альбом ранее задавался со страницы настроек,
          # то второй и последующие разы создаём его автоматически.
          # чтоб юзер лишний раз не кликал.
          vk.chooseAlbum getMessage 'second_auto_album_description'
          do app.bindPasteHandler
    else
      #в первый раз открываем страницу настроек,
      #чтобы юзер мог сам указать желаемый альбом
      return do @fistTimeAlbumChoose


    do app.bindPasteHandler


  fistTimeAlbumChoose: ->
    if !IS_OPTIONS_PAGE and !IS_AUTH_PAGE and !OPTIONS_PAGE_OPENED
      open chrome.extension.getURL 'options.html'
      OPTIONS_PAGE_OPENED=yes


  isAuth: ->
    app.options.access_token


  hasAlbum: ->
    app.options.album_id


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

          do app.init
      ), 300


  finishAuthorize: (url) ->
    console.log "finishAuthorize"
    for param in ['access_token', 'expires_in', 'user_id']
      @setSettings param, url.getParam param
    do @init


  bindPasteHandler: ->
    #setInterval ->
    #  console.log 'bindPasteHandler'
      document.onpaste = (event) =>
        app.upload item for item in event.clipboardData.items
    #, 1000


  loaders: (act) ->
    tmpl = "
      <div class='im_preview_photo_wrap inl_bl ctrl-vk-loader '>
        <div class='im_preview_photo'>
          <img style='width:50px; height:50px;'
               src='#{ chrome.extension.getURL 'images/ajax-loader-large.gif' }'
               class='im_preview_photo'>
          </img>
        </div>
      </div>"

    multimediaPreview=$(window.getSelection().focusNode).parent().parent().parent().find('.multi_media_preview')

    if act is 'add'
      multimediaPreview.append tmpl
    else if act is 'remove'
      do multimediaPreview.find('.ctrl-vk-loader:first').remove


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

  loadCur: (type, menushka, callback) ->
    if type=="default"
        menushka.click()

        do $('#im_user_holder').click

        do $(".add_media_menu").hide

        do callback


    else
      if type=="microBlog"
        menushka.click()

        photolink = $(".add_media_item").filter(->
          $(this).attr("class").match /add_media_type_\d*_photo/  if $(this).attr("class") isnt `undefined`
        )

        photolink[0].click()


        intervalID = setInterval ( ->
          console.log "interval 100"
          if($(".photos_close_link").length>0)
            $(".photos_close_link")[0].click()
            do $(".add_media_menu").hide

            do callback
            clearInterval(intervalID);
        ), 10






  chooseMedia: (photo) ->
    base = photo.src_small.match(/http:\/\/cs\d+\.(userapi\.com|vk\.me)\/v\d+\//)[0]
    x = photo.src_small.match(/[a-zA-Z0-9]+\/[a-zA-Z0-9_-]+(?=\.jpg)/)[0]

    # работает и для стены и для сообщений
    focusNode= $(window.getSelection().focusNode);
    console.log focusNode

    type="default"
    if focusNode.attr('class')=="clear_fix"
      type="microBlog"


    console.log "type:"+type

    menushka=focusNode.parent().parent().parent().find(".add_media_lnk")[0]


    if type=="default"
      @loadCur type, menushka, ->

        mini = JSON.stringify temp: base: base, x_: [x, 50, 50]

        photo_data = JSON.stringify
          type: 'photo'
          id: "#{photo.owner_id}_#{photo.pid}"
          mini: mini
          src_big: photo.src_big
          src: photo.src
          hash: ''

        do $('#ctrl-vk').remove

        inline_js = '
          var photo = JSON.parse(event.target.dataset.photo);
          window.cur.chooseMedia(photo.type, photo.id, [photo.src_big, photo.src, photo.hash, photo.mini]);'

        block = $("<a data-photo='#{photo_data}' onclick='#{inline_js}' id='ctrl-vk'>hello from ctrl-vk</a>")
        block.css 'display', 'none'

        $('#side_bar').append block

        do block.click

    else

      @loadCur type, menushka, ->
        mini2 = JSON.stringify temp: base: base, x_: [x, 10, 100]

        photo_data2 = JSON.stringify
          type: 'photo'
          id: "#{photo.owner_id}_#{photo.pid}"
          thumb_s: photo.src_small
          thumb_m: photo.src
          view_opts: mini2

        inline_js2 = '
                                var photo = JSON.parse(event.target.dataset.photo);
                                console.log("hello from ctrl-vk (microblog)");
                                return cur.choosePhotoMulti(photo.id,
                                  cur.chooseMedia.pbind(
                                    photo.type, photo.id, {
                                      thumb_s: photo.thumb_s,
                                      thumb_m: photo.thumb_m,
                                      view_opts: photo.view_opts,
                                      editable: {
                                        "sizes": {
                                          "s": [photo.thumb_s, 75, 75],
                                          "m": [photo.thumb_s, 100, 100],
                                          "x": [photo.thumb_s, 100, 100],
                                          "o": [photo.thumb_s, 100, 100],
                                          "p": [photo.thumb_s, 100, 100],
                                          "q": [photo.thumb_s, 100, 100],
                                          "r": [photo.thumb_s, 100, 100]
                                        }
                                      }
                                    }
                                  ), event
                                )
                              '
        block = $("<a data-photo='#{photo_data2}' onclick='#{inline_js2}' id='ctrl-vk'>hello from ctrl-vk</a>")
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
      caption: getMessage 'photo_description'
      access_token: @access_token

    url = @makeUrl @api_url, 'photos.save', params
    @request url, off, 'GET', callback


  chooseAlbum: (comment_for_new_album, callback) ->
    @getAlbums (data) ->
      # TODO make sorting by updating date
      albums = []
      regexp = new RegExp APP_NAME
      albums.push a for a in data.response when (regexp.test a.title) and (a.size < 500)

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
      #http://mabp.kiev.ua/2008/04/02/encoding_decoding_utf_in_javascript/
      description: unescape encodeURIComponent comment_for_new_album
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
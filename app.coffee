APP_NAME = 'ctrl-vk'
CLIENT_ID = 3427457
AUTHORIZATION_URI = 'https://api.vkontakte.ru/oauth/authorize'
REDIRECT_URI = 'http://api.vk.com/blank.html' # redirect uri for vk.com
API_URI = 'https://api.vk.com' # api uri for vk.com

dev = yes
authorizeInProgress = no

window.onload = () ->
  window.app = new App dev

  if app.isAuth()

    window.vk = new Vk
      client_id: CLIENT_ID
      authorization_uri: AUTHORIZATION_URI
      redirect_uri: REDIRECT_URI
      api_url: API_URI
      access_token: app.getSettings 'access_token'
      album_id: app.getSettings 'album_id'

    document.onpaste = (event) =>
      items = event.clipboardData.items

      # will give you the mime types
      console.log JSON.stringify items

      # what for?
      @processClipboard item for item in items

  else
    do app.requestAccessToken


class App
  constructor: ->
    console.log 'app start'


  isAuth: ->
    @getSettings('accessToken') and @getSettings('is_auth')


  getSettings: (name) ->
    unless localStorage
      return alert 'update your browser, dude'

    data = JSON.parse localStorage.getItem "#{APP_NAME}:#{name}"

    unless data
      return console.log 'your settings are empty'

    return data[name] or null


  setSettings: (name, value) ->
    unless localStorage
      return alert 'update your browser, dude'

    data = JSON.parse localStorage.getItem "#{APP_NAME}:#{name}"

    data = data or {}

    data[name] = value

    localStorage.setItem "#{APP_NAME}:#{name}", JSON.stringify value


  requestAccessToken: ->
    authorizeInProgress = yes
    open Vk.makeAuthorizeUrl() # call a class method
    console.log 'open new tab..'


  finishAuthorize: (url) ->
    for param in ['access_token', 'expires_in', 'user_id']
      setSettings param, url.getParam param

    @setSettings 'is_auth', yes

    console.log url


  processClipboard: (item) ->
    if /^image/.test item['type']

      blob = item.getAsFile()
      reader = new FileReader

      #например можно вставить картинку в страницу
      #reader.onload = (event) ->
      #console.log(event.target.result) // data url!
      #img = document.createElement('img')
      #img.src=event.target.result
      #document.body.appendChild(img)

      reader.readAsDataURL blob

      # If you want to upload it instead, you could use readAsBinaryString,
      # or you could probably put it into an XHR using FormData
      # https://developer.mozilla.org/en/XMLHttpRequest/FormData
      reader.onload = (event) ->

        # data url!
        console.log event.target.result
        binaryString = event.target.result

        #vk.getUploadUrl (response) =>
          #formData = new FormData
          #image = formData.append 'photo', blob, 'photo.png'
          #upload_url = response.upload_url

          #vk.uploadImage image, to: upload_url, (response) =>
            #album_id = getSettings 'album_id'
            #vk.saveImage to: album_id, params, (response) =>
              #if response.ok is yes
                #alert 'fuck yeah!'


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
      "#{base}/#{method}?#{params}"


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
    @request url_param.url, image, 'POST', callback


  saveImage: (album_id_prms, params, callback) ->


  request: (url, data, type = 'GET', callback) ->
    $.ajax
      url: url, data: data, type: type, success: callback
      contentType: off, processData: off, cache: off


String.prototype.getParam = (name) ->
  reg = "[\\?&#]#{name}=([A-z,0-9]*)"
  results = RegExp(reg).exec this.toString()

  return if results?.length is 2
    decodeURIComponent(results[1])
  else null


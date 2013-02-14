APP_NAME = 'ctrl-vk'
CLIENT_ID = 3427457
AUTHORIZATION_URI = 'https://api.vkontakte.ru/oauth/authorize'
REDIRECT_URI = 'http://api.vk.com/blank.html' # redirect uri for vk.com
API_URI = 'https://api.vk.com' # api uri for vk.com

dev = yes
authorizeInProgress = no

#if getSettings 'accessToken' or dev
if dev # TODO figure out why getSettings() is undefined
  console.log 'app start'

  document.onpaste = (event) ->
    items = event.clipboardData.items

    # will give you the mime types
    console.log JSON.stringify(items)

    if (item = items[1]) and /^image/.test(item['type'])

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

        button = $('.add_media_type_2_photo')[0]
        console.log(button)

        if button.click()
          console.log 'add_media_type_2_photo click'

      reader.readAsBinaryString blob
else
  do requestAccessToken

window.getSettings = (name) ->
  unless localStorage
    return alert 'update your browser, dude'

  data = JSON.parse localStorage.getItem "#{APP_NAME}:#{name}"

  unless data
    return console.log 'your settings are empty'

  return data[name] or null


window.setSettings = (name, value) ->
  unless localStorage
    return alert 'update your browser, dude'

  data = JSON.parse localStorage.getItem "#{APP_NAME}:#{name}"

  data = data or {}

  data[name] = value

  localStorage.setItem "#{APP_NAME}:#{name}", JSON.stringify value

# here we will be open new window (or tab) with auth page
# for getting acceess toke
window.requestAccessToken = ->
  console.log 'open new tab..'
  authorizeInProgress = yes
  open makeAuthorizeUrl()
  no

window.makeAuthorizeUrl = ->
  params.push "#{name}=#{value}" for name, value of {
    client_id: CLIENT_ID
    scope: 'photos'
    display: 'popup'
    redirect_uri: REDIRECT_URI
    response_type: 'token'
  }

  "#{AUTHORIZATION_URI}?#{params.join('&')}"

window.finishAuthorize = (url) ->
  for param in ['access_token', 'expires_in', 'user_id']
    setSettings param, url.getParam param

  console.log url

String.prototype.getParam = (name) ->
  reg = "[\\?&#]#{name}=([A-z,0-9]*)"
  results = RegExp(reg).exec this.toString()

  return if results?.length is 2
    decodeURIComponent(results[1])
  else null


class Vk
  constructor: (params = {}) ->
    @client_id = params.client_id
    @redirect_uri = params.redirect_uri

  makeAuthorizeUrl: ->
    params.push "#{name}=#{value}" for name, value of {
      client_id: @client_id
      scope: 'photos'
      display: 'popup'
      redirect_uri: @redirect_uri
      response_type: 'token'
    }

    "#{AUTHORIZATION_URI}?#{params.join('&')}"

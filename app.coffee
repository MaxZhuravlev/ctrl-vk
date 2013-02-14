APP_NAME = 'ctrl-vk'
CLIENT_ID = 3427457
AUTHORIZATION_URI = 'https://api.vkontakte.ru/oauth/authorize'
REDIRECT_URI = 'http://api.vk.com/blank.html' # redirect uri for vk.com
API_URI = 'https://api.vk.com' # api uri for vk.com

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

window.getSettings = (name) ->
  unless localStorage
    return alert 'update your browser, dude'

  data = JSON.parse localStorage.getItem "#{APP_NAME}:#{name}"

  unless data
    return alert 'update your browser, dude'

  if value = data[name]
    return value
  else
    return null


window.setSettings = (name, value) ->
  unless localStorage
    return alert 'update your browser, dude'

  data = JSON.parse localStorage.getItem "#{APP_NAME}:#{name}"

  date[name] = value

  localStorage.setItem "#{APP_NAME}:#{name}", JSON.stringify value

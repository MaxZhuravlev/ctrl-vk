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
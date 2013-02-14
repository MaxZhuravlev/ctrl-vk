// Generated by CoffeeScript 1.4.0
(function() {
  var API_URI, APP_NAME, AUTHORIZATION_URI, CLIENT_ID, REDIRECT_URI;

  APP_NAME = 'ctrl-vk';

  CLIENT_ID = 3427457;

  AUTHORIZATION_URI = 'https://api.vkontakte.ru/oauth/authorize';

  REDIRECT_URI = 'http://api.vk.com/blank.html';

  API_URI = 'https://api.vk.com';

  console.log('app start');

  document.onpaste = function(event) {
    var blob, item, items, reader;
    items = event.clipboardData.items;
    console.log(JSON.stringify(items));
    if ((item = items[1]) && /^image/.test(item['type'])) {
      blob = item.getAsFile();
      reader = new FileReader;
      reader.readAsDataURL(blob);
      reader.onload = function(event) {
        var binaryString, button;
        console.log(event.target.result);
        binaryString = event.target.result;
        button = $('.add_media_type_2_photo')[0];
        console.log(button);
        if (button.click()) {
          return console.log('add_media_type_2_photo click');
        }
      };
      return reader.readAsBinaryString(blob);
    }
  };

  window.getSettings = function(name) {
    var data, value;
    if (!localStorage) {
      return alert('update your browser, dude');
    }
    data = JSON.parse(localStorage.getItem("" + APP_NAME + ":" + name));
    if (!data) {
      return alert('update your browser, dude');
    }
    if (value = data[name]) {
      return value;
    } else {
      return null;
    }
  };

  window.setSettings = function(name, value) {
    var data;
    if (!localStorage) {
      return alert('update your browser, dude');
    }
    data = JSON.parse(localStorage.getItem("" + APP_NAME + ":" + name));
    date[name] = value;
    return localStorage.setItem("" + APP_NAME + ":" + name, JSON.stringify(value));
  };

}).call(this);

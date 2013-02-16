// Generated by CoffeeScript 1.4.0
(function() {
  var API_URI, APP_NAME, AUTHORIZATION_URI, App, CLIENT_ID, REDIRECT_URI, Vk, dev;

  APP_NAME = 'ctrl-vk';

  CLIENT_ID = 3427457;

  AUTHORIZATION_URI = 'https://api.vkontakte.ru/oauth/authorize';

  REDIRECT_URI = 'http://api.vk.com/blank.html';

  API_URI = 'https://api.vk.com';

  dev = true;

  window.onload = function() {
    var _this = this;
    window.app = new App(dev);
    app.setSettings('REDIRECT_URI', REDIRECT_URI);
    if (app.isAuth()) {
      window.vk = new Vk({
        client_id: CLIENT_ID,
        authorization_uri: AUTHORIZATION_URI,
        redirect_uri: REDIRECT_URI,
        api_url: API_URI,
        access_token: app.getSettings('access_token'),
        album_id: app.getSettings('album_id')
      });
      return document.onpaste = function(event) {
        var item, items, _i, _len, _results;
        items = event.clipboardData.items;
        console.log(JSON.stringify(items));
        _results = [];
        for (_i = 0, _len = items.length; _i < _len; _i++) {
          item = items[_i];
          _results.push(_this.processClipboard(item));
        }
        return _results;
      };
    } else {
      if (app.getSettings('authorize_in_progress') !== true) {
        return app.requestAccessToken();
      }
    }
  };

  App = (function() {

    function App() {
      console.log('app start');
      this.setSettings('authorize_in_progress', false);
    }

    App.prototype.isAuth = function() {
      return this.getSettings('accessToken') && this.getSettings('is_auth');
    };

    App.prototype.getSettings = function(name) {
      var data;
      if (!localStorage) {
        return alert('update your browser, dude');
      }
      data = JSON.parse(localStorage.getItem(APP_NAME));
      if (!data) {
        return console.log("your settings (" + name + ") are empty");
      }
      return data[name];
    };

    App.prototype.setSettings = function(name, value) {
      var data;
      if (!localStorage) {
        return alert('update your browser, dude');
      }
      data = JSON.parse(localStorage.getItem(APP_NAME));
      data = data || {};
      data[name] = value;
      return localStorage.setItem(APP_NAME, JSON.stringify(data));
    };

    App.prototype.requestAccessToken = function() {
      var url;
      this.setSettings('authorize_in_progress', true);
      url = Vk.makeAuthorizeUrl();
      open(url);
      return console.log('open new tab..');
    };

    App.prototype.finishAuthorize = function(url) {
      var param, _i, _len, _ref;
      _ref = ['access_token', 'expires_in', 'user_id'];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        param = _ref[_i];
        setSettings(param, url.getParam(param));
      }
      this.setSettings('is_auth', true);
      return console.log(url);
    };

    App.prototype.processClipboard = function(item) {
      var blob, reader;
      if (/^image/.test(item['type'])) {
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

    return App;

  })();

  Vk = (function() {

    function Vk(params) {
      if (params == null) {
        params = {};
      }
      $.extend(this, params);
    }

    Vk.prototype.makeUrl = function(base, method, prms) {
      var name, params, value;
      params = [];
      for (name in prms) {
        value = prms[name];
        params.push("" + name + "=" + value);
      }
      params = params.join('&');
      if (method === 'auth') {
        return "" + base + "?" + params;
      } else {
        return "" + base + "/" + method + "?" + params;
      }
    };

    Vk.makeAuthorizeUrl = function() {
      var params;
      params = {
        client_id: CLIENT_ID,
        scope: 'photos',
        display: 'popup',
        redirect_uri: REDIRECT_URI,
        response_type: 'token'
      };
      return Vk.prototype.makeUrl(AUTHORIZATION_URI, 'auth', params);
    };

    Vk.prototype.getUploadUrl = function(callback) {
      var params, url;
      params = {
        access_token: this.access_token,
        aid: this.album_id,
        save_big: 1
      };
      url = this.makeUrl(this.api_url, 'photos.getUploadServer', params);
      return this.request(url, null, 'GET', callback);
    };

    Vk.prototype.uploadImage = function(image, url_param, callback) {
      return this.request(url_param.url, image, 'POST', callback);
    };

    Vk.prototype.saveImage = function(album_id_prms, params, callback) {};

    Vk.prototype.request = function(url, data, type, callback) {
      if (type == null) {
        type = 'GET';
      }
      return $.ajax({
        url: url,
        data: data,
        type: type,
        success: callback,
        contentType: false,
        processData: false,
        cache: false
      });
    };

    return Vk;

  })();

  String.prototype.getParam = function(name) {
    var reg, results;
    reg = "[\\?&#]" + name + "=([A-z,0-9]*)";
    results = RegExp(reg).exec(this.toString());
    if ((results != null ? results.length : void 0) === 2) {
      return decodeURIComponent(results[1]);
    } else {
      return null;
    }
  };

}).call(this);

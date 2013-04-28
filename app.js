// Generated by CoffeeScript 1.4.0
(function() {
  var API_URI, APP_NAME, AUTHORIZATION_URI, App, CLIENT_ID, IS_AUTH_PAGE, IS_OPTIONS_PAGE, OPTIONS_PAGE_OPENED, REDIRECT_URI, Vk, dev, getMessage, syncStorage;

  APP_NAME = 'ctrl-vk';

  CLIENT_ID = 3427457;

  AUTHORIZATION_URI = 'https://api.vkontakte.ru/oauth/authorize';

  REDIRECT_URI = 'http://api.vk.com/blank.html';

  API_URI = 'https://api.vk.com';

  IS_OPTIONS_PAGE = window.location.href === chrome.extension.getURL('options.html');

  IS_AUTH_PAGE = RegExp(REDIRECT_URI).test(location.href);

  OPTIONS_PAGE_OPENED = false;

  dev = true;

  syncStorage = chrome.storage[dev ? 'local' : 'sync'];

  getMessage = chrome.i18n.getMessage;

  window.onload = function() {
    window.app = new App;
    return syncStorage.get(APP_NAME, function(items) {
      console.log('data from syncStorage', items[APP_NAME]);
      if (items[APP_NAME]) {
        app.options = items[APP_NAME];
      }
      if (app.isAuth()) {
        if (IS_OPTIONS_PAGE) {
          return app.optionsPage();
        } else {
          return app.init();
        }
      } else {
        if (IS_AUTH_PAGE) {
          syncStorage.set({
            authorize_url: location.href
          });
          return chrome.extension.sendMessage({
            what_to_do: 'close_me'
          });
        } else {
          return app.startAuthorize();
        }
      }
    });
  };

  App = (function() {

    function App() {}

    App.prototype.options = {};

    App.prototype.optionsPage = function() {
      var _this = this;
      console.log('options page');
      $('#album_link').val(app.options.album_link);
      $('#save_button').click(function() {
        _this.setSettings('album_link', $('#album_link').val());
        _this.setSettings('album_id', $("#album_link").val().match(/album\d+_(\d+)/)[1]);
        $('#status').html(getMessage('saved'));
        console.log($('#status').html());
        return setTimeout((function() {
          return $('#status').html('');
        }), 7500);
      });
      $('#auto_button').tooltip({
        'title': getMessage('auto_button_tooltip')
      });
      $('#auto_button').click(function() {
        window.vk = new Vk({
          api_url: API_URI,
          access_token: app.options.access_token
        });
        return vk.chooseAlbum(getMessage('first_auto_album_description'))();
      });
      $('#album_link_span').html(getMessage('album_link'));
      $('#save_button').html(getMessage('save_button'));
      $('#auto_button').html(getMessage('auto_button'));
      $('#slogan').html(getMessage('slogan'));
      $('#nameMax').html(getMessage('nameMax'));
      $('#nameRoma').html(getMessage('nameRoma'));
      $('.or').html(getMessage('or'));
      if (/mac/i.test(navigator.platform)) {
        $('#key').attr('src', 'images/cmd.png');
        return $('#key').attr('class', 'cmd');
      }
    };

    App.prototype.init = function() {
      var has_valid_album;
      console.log('app start');
      if (app.hasAlbum()) {
        window.vk = new Vk({
          client_id: CLIENT_ID,
          authorization_uri: AUTHORIZATION_URI,
          redirect_uri: REDIRECT_URI,
          api_url: API_URI,
          access_token: app.options.access_token,
          album_id: app.options.album_id
        });
        has_valid_album = false;
        vk.getAlbum(app.options.album_id, function(data) {
          var a, album, albums, _i, _len, _ref;
          albums = [];
          _ref = data.response;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            a = _ref[_i];
            albums.push(a);
          }
          if (albums.length === 0) {
            has_valid_album = false;
          } else {
            album = albums[albums.length - 1];
            if (album.size < 500) {
              has_valid_album = true;
            } else {
              has_valid_album = false;
            }
          }
          if (!has_valid_album) {
            vk.chooseAlbum(getMessage('second_auto_album_description'));
            return app.bindPasteHandler();
          }
        });
      } else {
        return this.fistTimeAlbumChoose();
      }
      return app.bindPasteHandler();
    };

    App.prototype.fistTimeAlbumChoose = function() {
      if (!IS_OPTIONS_PAGE && !IS_AUTH_PAGE && !OPTIONS_PAGE_OPENED) {
        open(chrome.extension.getURL('options.html'));
        return OPTIONS_PAGE_OPENED = true;
      }
    };

    App.prototype.isAuth = function() {
      return app.options.access_token;
    };

    App.prototype.hasAlbum = function() {
      return app.options.album_id;
    };

    App.prototype.setSettings = function(name, value) {
      app.options[name] = value;
      return syncStorage.set({
        'ctrl-vk': app.options
      });
    };

    App.prototype.startAuthorize = function() {
      var intr_id;
      open(Vk.makeAuthorizeUrl());
      console.log('open new tab with auth url..');
      return intr_id = setInterval((function() {
        return syncStorage.get('authorize_url', function(data) {
          if (data.authorize_url) {
            app.finishAuthorize(data.authorize_url);
            syncStorage.set({
              authorize_url: null
            });
            clearInterval(intr_id);
            return app.init();
          }
        });
      }), 300);
    };

    App.prototype.finishAuthorize = function(url) {
      var param, _i, _len, _ref;
      console.log("finishAuthorize");
      _ref = ['access_token', 'expires_in', 'user_id'];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        param = _ref[_i];
        this.setSettings(param, url.getParam(param));
      }
      return this.init();
    };

    App.prototype.bindPasteHandler = function() {
      var _this = this;
      return document.onpaste = function(event) {
        var item, _i, _len, _ref, _results;
        _ref = event.clipboardData.items;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          item = _ref[_i];
          _results.push(app.upload(item));
        }
        return _results;
      };
    };

    App.prototype.loaders = function(act) {
      var multimediaPreview, tmpl;
      tmpl = "      <div class='im_preview_photo_wrap inl_bl ctrl-vk-loader '>        <div class='im_preview_photo'>          <img style='width:50px; height:50px;'               src='" + (chrome.extension.getURL('images/ajax-loader-large.gif')) + "'               class='im_preview_photo'>          </img>        </div>      </div>";
      multimediaPreview = $(window.getSelection().focusNode).parent().parent().parent().find('.multi_media_preview');
      if (act === 'add') {
        return multimediaPreview.append(tmpl);
      } else if (act === 'remove') {
        return multimediaPreview.find('.ctrl-vk-loader:first').remove();
      }
    };

    App.prototype.upload = function(item) {
      var blob, reader;
      if (/^image\/png/.test(item['type'])) {
        blob = item.getAsFile();
        reader = new FileReader;
        reader.onload = function(event) {
          var binaryString,
            _this = this;
          console.log(event.target.result);
          binaryString = event.target.result;
          return vk.getUploadUrl(function(data) {
            var image, upload_url;
            if (data.error) {
              return alert(data.error.error_msg);
            }
            app.loaders('add');
            image = new FormData;
            image.append('photo', dataURIToBlob(binaryString), 'photo.png');
            upload_url = data.response.upload_url;
            return vk.uploadImage(image, {
              to: upload_url
            }, function(data) {
              return vk.saveImage(data, function(data) {
                app.loaders('remove');
                if (data.error) {
                  return alert(data.error.error_msg);
                } else {
                  return vk.chooseMedia(data.response[0]);
                }
              });
            });
          });
        };
        return reader.readAsDataURL(blob);
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

    Vk.prototype.loadCur = function(type, menushka, callback) {
      var intervalID, photolink;
      if (type === "default") {
        menushka.click();
        $('#im_user_holder').click();
        return vk.loadCurFinish(callback);
      } else {
        if (type === "microBlog") {
          menushka.click();
          photolink = $(".add_media_item").filter(function() {
            if ($(this).attr("class") !== undefined) {
              return $(this).attr("class").match(/add_media_type_\d*_photo/);
            }
          });
          photolink[0].click();
          intervalID = setInterval((function() {
            console.log("interval 100");
            if ($(".photos_close_link").length > 0) {
              $(".photos_close_link")[0].click();
              vk.loadCurFinish(callback);
              return clearInterval(intervalID);
            }
          }), 20);
          return setTimeout((function() {
            return clearInterval(intervalID);
          }), 5000);
        } else {
          if (type === "newMessage") {
            menushka.click();
            photolink = $(".add_media_item").filter(function() {
              if ($(this).attr("class") !== undefined) {
                return $(this).attr("class").match(/add_media_type_\d*_photo/);
              }
            });
            photolink[0].click();
            intervalID = setInterval((function() {
              console.log("interval 100");
              if ($(".photos_close_link").length > 0) {
                $(".photos_close_link")[0].click();
                vk.loadCurFinish(callback);
                return clearInterval(intervalID);
              }
            }), 20);
            return setTimeout((function() {
              return clearInterval(intervalID);
            }), 5000);
          }
        }
      }
    };

    Vk.prototype.loadCurFinish = function(callback) {
      callback();
      return $(".add_media_menu").hide();
    };

    Vk.prototype.chooseMedia = function(photo) {
      var base, focusNode, menushka, type, x;
      base = photo.src_small.match(/http:\/\/cs\d+\.(userapi\.com|vk\.me)\/v\d+\//)[0];
      x = photo.src_small.match(/[a-zA-Z0-9]+\/[a-zA-Z0-9_-]+(?=\.jpg)/)[0];
      focusNode = $(window.getSelection().focusNode);
      console.log(focusNode);
      type = "default";
      if (focusNode.attr('class') === "clear_fix") {
        type = "microBlog";
      } else {
        if (focusNode.attr('id') === "mail_box_editable") {
          type = "newMessage";
        }
      }
      console.log("type:" + type);
      menushka = focusNode.parent().parent().parent().find(".add_media_lnk")[0];
      if (type === "default") {
        return this.loadCur(type, menushka, function() {
          var block, inline_js, mini, photo_data;
          mini = JSON.stringify({
            temp: {
              base: base,
              x_: [x, 50, 50]
            }
          });
          photo_data = JSON.stringify({
            type: 'photo',
            id: "" + photo.owner_id + "_" + photo.pid,
            mini: mini,
            src_big: photo.src_big,
            src: photo.src,
            hash: ''
          });
          $('#ctrl-vk').remove();
          inline_js = '\
          var photo = JSON.parse(event.target.dataset.photo);\
          window.cur.chooseMedia(photo.type, photo.id, [photo.src_big, photo.src, photo.hash, photo.mini]);';
          block = $("<a data-photo='" + photo_data + "' onclick='" + inline_js + "' id='ctrl-vk'>hello from ctrl-vk</a>");
          block.css('display', 'none');
          $('#side_bar').append(block);
          return block.click();
        });
      } else {
        return this.loadCur(type, menushka, function() {
          var block, inline_js2, mini2, photo_data2;
          if (type === "newMessage" && dev) {
            debugger;
          }
          mini2 = JSON.stringify({
            temp: {
              base: base,
              x_: [x, 10, 100]
            }
          });
          photo_data2 = JSON.stringify({
            type: 'photo',
            id: "" + photo.owner_id + "_" + photo.pid,
            thumb_s: photo.src_small,
            thumb_m: photo.src,
            view_opts: mini2
          });
          inline_js2 = '\
                                var photo = JSON.parse(event.target.dataset.photo);\
                                console.log("hello from ctrl-vk (microblog)");\
                                return cur.choosePhotoMulti(photo.id,\
                                  cur.chooseMedia.pbind(\
                                    photo.type, photo.id, {\
                                      thumb_s: photo.thumb_s,\
                                      thumb_m: photo.thumb_m,\
                                      view_opts: photo.view_opts,\
                                      editable: {\
                                        "sizes": {\
                                          "s": [photo.thumb_s, 75, 75],\
                                          "m": [photo.thumb_s, 100, 100],\
                                          "x": [photo.thumb_s, 100, 100],\
                                          "o": [photo.thumb_s, 100, 100],\
                                          "p": [photo.thumb_s, 100, 100],\
                                          "q": [photo.thumb_s, 100, 100],\
                                          "r": [photo.thumb_s, 100, 100]\
                                        }\
                                      }\
                                    }\
                                  ), event\
                                )\
                              ';
          block = $("<a data-photo='" + photo_data2 + "' onclick='" + inline_js2 + "' id='ctrl-vk'>hello from ctrl-vk</a>");
          block.css('display', 'none');
          $('#side_bar').append(block);
          return block.click();
        });
      }
    };

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
        return "" + base + "/method/" + method + "?" + params;
      }
    };

    Vk.makeAuthorizeUrl = function() {
      var params;
      params = {
        client_id: CLIENT_ID,
        scope: 'photos,offline',
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
      return this.request(url, false, 'GET', callback);
    };

    Vk.prototype.uploadImage = function(image, url_param, callback) {
      return this.request(url_param.to, image, 'POST', callback);
    };

    Vk.prototype.saveImage = function(params, callback) {
      var url;
      if (typeof params === 'string') {
        params = JSON.parse(params);
      }
      $.extend(params, {
        caption: getMessage('photo_description'),
        access_token: this.access_token
      });
      url = this.makeUrl(this.api_url, 'photos.save', params);
      return this.request(url, false, 'GET', callback);
    };

    Vk.prototype.chooseAlbum = function(comment_for_new_album, callback) {
      return this.getAlbums(function(data) {
        var a, aid, album, album_link, albums, owner_id, regexp, _i, _len, _ref,
          _this = this;
        albums = [];
        regexp = new RegExp(APP_NAME);
        _ref = data.response;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          a = _ref[_i];
          if ((regexp.test(a.title)) && (a.size < 500)) {
            albums.push(a);
          }
        }
        if (albums.length === 0) {
          return vk.createAlbum(comment_for_new_album, function(data) {
            var aid, album_link, owner_id;
            aid = data.response.aid;
            owner_id = data.response.owner_id;
            album_link = "http://vk.com/album" + owner_id + "_" + aid;
            app.setSettings('album_link', album_link);
            app.setSettings('album_id', aid);
            return location.reload();
          });
        } else {
          album = albums[albums.length - 1];
          aid = album.aid;
          owner_id = album.owner_id;
          album_link = "http://vk.com/album" + owner_id + "_" + aid;
          app.setSettings('album_link', album_link);
          app.setSettings('album_id', aid);
          return location.reload();
        }
      });
    };

    Vk.prototype.createAlbum = function(comment_for_new_album, callback) {
      var params, url;
      params = {
        access_token: this.access_token,
        title: 'ctrl-vk',
        description: unescape(encodeURIComponent(comment_for_new_album)),
        comment_privacy: 3,
        privacy: 3
      };
      url = this.makeUrl(this.api_url, 'photos.createAlbum', params);
      return this.request(url, false, 'GET', callback);
    };

    Vk.prototype.getAlbums = function(callback) {
      var params, url;
      params = {
        access_token: this.access_token
      };
      url = this.makeUrl(this.api_url, 'photos.getAlbums', params);
      return this.request(url, false, 'GET', callback);
    };

    Vk.prototype.getAlbum = function(aid, callback) {
      var params, url;
      params = {
        access_token: this.access_token,
        aids: aid
      };
      url = this.makeUrl(this.api_url, 'photos.getAlbums', params);
      return this.request(url, false, 'GET', callback);
    };

    Vk.prototype.request = function(url, data, type, callback) {
      var xhr;
      if (type == null) {
        type = 'GET';
      }
      xhr = $.ajax({
        url: url,
        data: data,
        type: type,
        success: callback,
        contentType: false,
        processData: false,
        cache: false
      });
      xhr.fail(function() {
        return console.error(arguments);
      });
      return xhr.always(function() {
        return console.log(arguments);
      });
    };

    return Vk;

  })();

  if (!dev) {
    console.log = console.error = function() {};
  }

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

  window.dataURIToBlob = function(dataURI) {
    var ab, byteString, key, mimeString, _, _i, _len;
    byteString = atob(dataURI.split(',')[1]);
    ab = [];
    for (key = _i = 0, _len = byteString.length; _i < _len; key = ++_i) {
      _ = byteString[key];
      ab.push(byteString.charCodeAt(key));
    }
    mimeString = dataURI.split(',')[0].split(':')[1].split(';')[0];
    return new Blob([new Uint8Array(ab)], {
      type: mimeString
    });
  };

}).call(this);

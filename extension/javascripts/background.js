chrome.tabs.onUpdated.addListener(function(tabId, changeInfo, tab) {
  if (app.getSettings('authorizeInProgress')) {
    alert('my tab');
    REDIRECT_URI = app.getSettings('REDIRECT_URI');
    if (tab.url.indexOf(REDIRECT_URI + "#access_token") >= 0) {
      app.setSettings('authorize_in_progress', false);
      chrome.tabs.remove(tabId);
      return app.finishAuthorize(tab.url);
    }
  } else {
    alert('not my');
  }
});


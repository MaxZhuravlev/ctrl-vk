chrome.tabs.onUpdated.addListener(function(tabId, changeInfo, tab) {
  console.log('tab');
  if (app.authorizeInProgress) {
    if (tab.url.indexOf(REDIRECT_URI + "#access_token") >= 0) {
      app.authorizeInProgress = false;
      chrome.tabs.remove(tabId);
      return finishAuthorize(tab.url);
    }
  }
});


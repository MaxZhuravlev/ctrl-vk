chrome.tabs.onUpdated.addListener(function(tabId, changeInfo, tab) {
  var authorizeInProgress;
  console.log('tab');
  if (authorizeInProgress) {
    if (tab.url.indexOf(REDIRECT_URI + "#access_token") >= 0) {
      authorizeInProgress = false;
      chrome.tabs.remove(tabId);
      return finishAuthorize(tab.url);
    }
  }
});


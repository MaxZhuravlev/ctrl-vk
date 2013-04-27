chrome.extension.onMessage.addListener(
  function(request, sender, sendResponse) {
    if (request.what_to_do == 'close_me') {
      chrome.tabs.remove(sender.tab.id);
    }
});

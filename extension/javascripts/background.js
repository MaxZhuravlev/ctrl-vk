chrome.extension.onMessage.addListener(
  function(request, sender, sendResponse) {
    if (request.what_to_do == 'close_me') {
      chrome.tabs.remove(sender.tab.id);
    } else if (request.what_to_do == 'ololo_click') {
      chrome.tabs.executeScript(sender.tab.id, {code: request.inline_js}, function(response) {
        console.log('ololo done');
      });
    }
});


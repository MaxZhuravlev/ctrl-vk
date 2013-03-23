chrome.extension.onMessage.addListener(
  function(request, sender, sendResponse) {
    if (request.what_to_do == 'close_me_and_return_extension_id') {
      sendResponse({extension_id: chrome.i18n.getMessage("@@extension_id")});
      chrome.tabs.remove(sender.tab.id);
    }
});

/**
 * Created by Max Zhuravlev
 * Date: 2/20/13
 * Time: 9:07 PM
 */
// Save this script as `options.js`

// Saves options to localStorage.


// Usually we try to store settings in the "sync" area since a lot of the time
// it will be a better user experience for settings to automatically sync
// between browsers.
//
// However, "sync" is expensive with a strict quota (both in storage space and
// bandwidth) so data that may be as large and updated as frequently as the CSS
// may not be suitable.
var storage = chrome.storage.sync;


function save_options() {

    storage.set({'album_id': $("#album_id").val()}, function() {
        // Notify that we saved.
        //message('Settings saved');

        // Update status to let user know options were saved.
        var status = document.getElementById("status");
        status.innerHTML = chrome.i18n.getMessage("saved");
        setTimeout(function() {
            status.innerHTML = "";
        }, 750);
    });


}

// Restores select box state to saved value from localStorage.
function restore_options() {

    storage.get(['album_id'], function(items) {
        console.log(items);

        if (!items.album_id) {
            return;
        }

        $("#album_id").val(items.album_id);

    });


}
document.addEventListener('DOMContentLoaded', restore_options);
document.querySelector('#save_button').addEventListener('click', save_options);


document.getElementById("album_link_span").innerHTML = chrome.i18n.getMessage("album_link");
document.getElementById("save_button").innerHTML = chrome.i18n.getMessage("save_button");
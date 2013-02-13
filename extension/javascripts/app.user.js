console.log('app start');

document.onpaste = function(event){
  var items = event.clipboardData.items;

  console.log(JSON.stringify(items)); // will give you the mime types

  if ( item = items[1] ) {
    if ( /^image/.test(item["type"]) ) {
      console.log("image/png");

      var blob = item.getAsFile();
      var reader = new FileReader();

      /*
        *
      // например можно вставить картинку в страницу
      reader.onload = function(event){
      console.log(event.target.result); // data url!
      var img = document.createElement('img')
      img.src=event.target.result;
      document.body.appendChild(img);

      };
      reader.readAsDataURL(blob);
      */


      // If you want to upload it instead, you could use readAsBinaryString, or you could probably put it into an XHR using FormData https://developer.mozilla.org/en/XMLHttpRequest/FormData
      reader.onload = function(event){

        console.log(event.target.result); // data url!
        var binaryString=event.target.result;

        var button = $('.add_media_type_2_photo')[0];
        console.log(button);

        button.click();
        console.log("add_media_type_2_photo click");

      };

      reader.readAsBinaryString(blob);
    }
  }
}

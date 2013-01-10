$(document).ready(function(){
    console.log('app start');

    var ctrlDown = false;
    var ctrlKey = 17, vKey = 86, cKey = 67;

    $(document).keydown(function(e)
    {
        if (e.keyCode == ctrlKey) ctrlDown = true;
    }).keyup(function(e)
        {
            if (e.keyCode == ctrlKey) ctrlDown = false;
        });

    //$(".no-copy-paste").keydown(function(e)
    $(document).keydown(function(e)
    {
        if (ctrlDown && (e.keyCode == vKey)){
            alert('ctr+v detected!');

        }
    });

});

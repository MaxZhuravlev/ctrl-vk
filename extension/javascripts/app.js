$(document).ready(function(){
    console.log('app start');


    var div = document.createElement('div')
    div.id='thenewdivid'
    document.body.appendChild(div)
    $('#thenewdivid').css({'width':'400px','display':'none','text-align':'left','font-size':'13px','position':'absolute',
        'border': 'solid 1px gray','padding': '3px','background-color':'white','z-index':'9999'})


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

            $('#thenewdivid').css({'top':100,'left':100});
            $('#thenewdivid').empty();
            $('#thenewdivid').html('123');

            if($('#thenewdivid').is(':visible')){
                $('#thenewdivid').hide();
            }else{
                $('#thenewdivid').show();
            }

            $('.add_media_type_2_photo').click();
            $('.photos_choose_row a').click();

        }
    });

});

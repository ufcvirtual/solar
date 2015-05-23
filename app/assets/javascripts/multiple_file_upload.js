function add_files(){
  $('#files_').click();
}

$(function(){
  $('#files_').change(function(){
    $('.files_list').html('');
    var files = $(this)[0].files;
    $.each(files, function(i){
      $('.files_list').append("<div id='file'>"+files[i].name+" ( "+files[i].size+"Kb ) </div>");
    });
  });
});

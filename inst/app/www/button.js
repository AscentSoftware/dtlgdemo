jQuery(function($){
  $('.btn[data-bs-toggle="collapse"]').on('click', function(){
    $(this)
    .data('text-original', $(this).text())
    .text($(this).data('text-alt') )
    .data('text-alt', $(this).data('text-original'));
  });
});

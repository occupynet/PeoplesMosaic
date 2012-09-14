var $mosaic;
$(document).ready(function(){

  $(".mosaic").first().addClass("infinite-scrolling");
  
  $("div.block").click(function(){
    $.ajax('/campaigns/block/'+$(this).attr('slug')+'/'+$(this).attr('edit_link')+'/'+$(this).attr('media_id'))
    $(this).parent().parent().fadeOut()
  })
  
  
  $("div.duplicates").click(function(){
    $.ajax('/campaigns/remove_duplicates/'+ $(this).attr('slug')+'/'+$(this).attr('edit_link')+'/'+$(this).attr('media_id'))
    $(this).parent().parent().fadeOut()
  })
  

  $("#bigpic").click(function(e){
    e.stopPropagation();
    $(this).fadeOut('fast');
  });
    var setOverlays = function(el){
      $(el).find(".grid").unbind('hover') ;
      $(el).find(".overlay").unbind('click');
      $(el).find(".block").unbind('click');
      $(el).find(".duplicates").unbind('click');

      $(el).find(".grid").each(function(i,e){
        var o = $(e).find(".overlay");
        var img = $(e).find("img").first();
        $(o).css("height",($(e).height()-40)+"px");
        $(o).click(function(){
          $("#bigpic").find("img").attr("src",img.attr("src"));
          $("#bigpic").css("width","100%")
          $("#bigpic").find("img").css("margin","0% 25%");
          $("#bigpic").fadeIn();
        })
        
        $("div.block").click(function(){
$.ajax('/campaigns/block/'+$(this).attr('slug')+'/'+$(this).attr('edit_link')+'/'+$(this).attr('media_id'))
          $(this).parent().parent().fadeOut()
        })

        $("div.duplicates").click(function(){
          $.ajax('/campaigns/remove_duplicates/'+ $(this).attr('slug')+'/'+$(this).attr('edit_link')+'/'+$(this).attr('media_id'))
          $(this).parent().parent().fadeOut()
        })
        
        
        $(e).hover(function(){
          $(this).find('.overlay').stop().fadeTo('fast',0.9);
        }, function (){
            $(o).stop().fadeTo('fast',0);  
          })
      })
    }
    
    $mosaic = $('.mosaic').first();
    $mosaic.isotope({
             // options
             itemSelector : '.grid',
             layoutMode : 'masonry',
             animationEngine: 'css',
          }, setOverlays($(".mosaic").first()));
    
      $mosaic.infinitescroll({
        navSelector  : 'div#more',    // selector for the paged navigation 
        nextSelector : 'div#more a',  // selector for the NEXT link (to page 2)
        itemSelector : '.mosaic div.grid',     // selector for all items you'll retrieve
        debug: false,
        animate: false,
        loading: {
            finishedMsg: 'No more pages to load.',
            img: 'http://i.imgur.com/qkKy8.gif'
          }
        },
        // call Isotope as a callback
        function( newElements ) {
          $mosaic.isotope( 'appended', $( newElements ) ); 
          setOverlays($('.mosaic').last());
          if ($(".grid").size() > 480 ) {
            var g = $(".grid");
            for (i=0; i < 30; i++) {
              $(g[i]).remove();
            }
            g = null;
          }
        }
      );
      
})

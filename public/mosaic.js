var $mosaic;
$(document).ready(function(){

  $(".mosaic").first().addClass("infinite-scrolling");
  
  $(".reveal").click(function(e){
     $(".modal").each(function(i,e){
        if($(this).attr("rel")==$(e).attr("rel")){
          $(e).fadeIn('fast')
        }
      });   
  });
  $(".hide").click(function(e){
    $(this).parent().fadeOut('fast');
  })
  
  
  $("div.block").click(function(){
    $.ajax('/campaigns/block/'+$(this).attr('slug')+'/'+$(this).attr('edit_link')+'/'+$(this).attr('media_id'))
    $(this).parent().parent().fadeOut()
  })
  
  $(".campaign .photo").each(function(i,e){
    var o = $(e).find('.clearoverlay');
    $(e).hover(function(){
      $(this).find('.clearoverlay').stop().fadeTo('fast',0.8);
    }, function (){
        $(o).stop().fadeTo('fast',0);  
      })
  })
  
  
  $("div.duplicates").click(function(){
    $.ajax('/campaigns/remove_duplicates/'+ $(this).attr('slug')+'/'+$(this).attr('edit_link')+'/'+$(this).attr('media_id'))
    $(this).parent().parent().fadeOut()
  })
  
  var showBigPic = function(img){
  $("#bigpic").find("img").attr("src",img.html());
  $("#bigpic").css("width","100%");
  $("#bigpic").css("top",$(window).scrollTop()+"px");
  $("#bigpic").find("img").css("margin","0% 25%");
  $("#bigpic").fadeIn();
  $("#bigpic").click(function(e){
      e.stopPropagation();
      $(this).fadeOut('fast');
    });
  } 
  

    var setOverlays = function(el){
      $(el).find(".grid").unbind('hover') ;
      $(el).find(".overlay").unbind('click');
      $(el).find(".block").unbind('click');
      $(el).find(".duplicates").unbind('click');
      $(el).find(".snapshots img.tile").unbind('click');
      $(el).find(".tightgrid img.tile").unbind('click');
      $(el).find(".tightgrid img.tile").unbind('hover');
      
      $(el).find(".snapshot img.tile").click(function(){
        var img = $(this).parent().find("div.fullsize").first();
        $("#bigpic").find(".caption").html($(this).parent().find(".caption").html())
        showBigPic(img)
        })
      $(el).find(".tightgrid img.tile").hover(function(){
        $("#overlay").html($(this).parent().find(".content").html());
        console.log($(this).parent().find(".content").html())
        $("#overlay").offset({top:$(this).offset().top-120, left:$(this).offset().left})
        $("#overlay").show();
      })
      $(el).find(".tightgrid img.tile").click(function(){
        var img = $(this).parent().find("div.fullsize").first();
        $("#overlay").fadeOut('fast');
        showBigPic(img)
      })
      

      $(el).find(".grid").each(function(i,e){
        var o = $(e).find(".overlay");
        var img = $(e).find("div.fullsize").first();
        $(o).css("height",($(e).height()-40)+"px");
        $(o).click(function(){showBigPic(img)});
        
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
    
    $campaigns = $('.campaigns').first();
    $campaigns.isotope({
      itemSelector : '.campaign',
      layoutMode : 'masonry',
      animationEngine : 'jquery',
      getSortData: {
        date: function ( $elem ){
          return parseInt($elem.find('.date').first().text())*(-1);
        },
        alphabetical: function ($elem) {
          return $elem.find('.name').first().text()
        },
        activity: function ($elem) {
          return parseInt($elem.find('.activityScore').first().text())*(-1)
        }
      }    
    });
    
    
        var $optionSets = $('.buttons .optionset'),
            $optionLinks = $optionSets.find('.button');

        $optionLinks.click(function(){
          var $this = $(this);
          if ( $this.hasClass('selected') ) {
               return false;
             }
             //toggle "selected classes"
         var $optionSet = $this.parents('.optionset');
         $optionSet.find('.selected').removeClass('selected');
         $this.addClass('selected');
          var options = {},
          key = $optionSet.attr('dataOptionKey'),
          value = $this.attr('dataOptionValue');
        // parse 'false' as false boolean
        value = value === 'false' ? false : value;
        options[ key ] = value;
        if ( key === 'layoutMode' && typeof changeLayoutMode === 'function' ) {
          // changes in layout modes need extra logic
          changeLayoutMode( $this, options )
        } else {
          // otherwise, apply new options
          $campaigns.isotope( options );
        }
      });
    
    
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
          if ($(".grid").size() > 400 ) {
            var g = $(".grid");
            for (i=0; i < 60; i++) {
              $(g[i]).remove();
            }
            g = null;
          }
        }
      );
    //set display to ALL
    window.setTimeout(function(){
      $("#activitySort").first().click();
    },1000)
})

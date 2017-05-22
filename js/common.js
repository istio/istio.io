---
sitemap_exclude: y
---

// Jquery UI for tabbed panes
$.getScript("https://ajax.googleapis.com/ajax/libs/jqueryui/1.10.4/jquery-ui.min.js", function(){
  setupTabs();
});

//Set up tabs
function setupTabs(rootElement) {
      rootElement = rootElement || document;
      var tabs = $(rootElement).find('div.tabs');
      if(tabs.length > 0) {
        tabs.tabs();
      }
}

// Make the table of contents
$(document).ready(function() {
    var $window = $(window);

    // Sticky Nav on Scroll Up
    var iScrollPos = 0;

    $window.scroll(function () {
      var iCurScrollPos = $(this).scrollTop();
        if (iCurScrollPos > iScrollPos) {
          //Scrolling Down
          if ($('#sticky-nav').visible()){
            $('#sticky-nav').removeClass("on-page");
          }
        } else {
          //Scrolling Up
          if ($('.nav-hero-container').visible(true) && $('#sticky-nav').visible()){
            $('#sticky-nav').removeClass("on-page");
          } else if (!$('.nav-hero-container').visible(true)) {
            $('#sticky-nav').addClass("on-page");
          }
        }
        iScrollPos = iCurScrollPos;
    });
    
    $('.toc').click(function(){
      setTimeout(function(){
        $('#sticky-nav').addClass("on-page");
      }, 1000)
    });

    setTimeout(function(){
      if (document.URL.indexOf("#") != -1 && document.URL.indexOf("contribute") == -1 ) {
        $('#sticky-nav').addClass("on-page");
      }
    }, 1000);

    // Scroll to sections
    $('.btn-floating').on('click', function(){
      $('html, body').scrollTo(('#' +($(this).data("target"))), 350);
    })

    $('#toc').toc({ listType: 'ul' });

    $('.nav-toggle, .hamburger').on('click', function(){
      $('.top-nav').toggleClass('right');
    });

    $('.nav-doc-toggle').on('click', function(){
      $('.doc-list').toggleClass('active');
    });

    $(window).on('resize',function(){
      if ($(window).width() >= 768 && !($('.top-nav').hasClass('right'))) {
        $('.top-nav').addClass('right');
      }
    });

    $('.toggle').on('click',function(){
      $(this).toggleClass('active');
    });

    $('.hero-down-arrow').on('click', function(){
      var scrollToY = $('.hero-wrapper:eq(0)').position().top;
      $('html,body').animate({scrollTop:scrollToY}, 300);
    });
});

// Collapsible navbar menu, using https://github.com/jordnkr/collapsible
$.getScript("{{ site.baseurl }}/js/jquery.collapsible.js", function(){
  highlightActive();
  $('.submenu').collapsible();
});

// TOC script
// https://github.com/ghiculescu/jekyll-table-of-contents
(function($){
  $.fn.toc = function(options) {
    var defaults = {
      noBackToTopLinks: false,
      title: '',
      minimumHeaders: 2,
      headers: 'h2, h3, h4, h5, h6',
      listType: 'ol', // values: [ol|ul]
      showEffect: 'show', // values: [show|slideDown|fadeIn|none]
      showSpeed: 'slow' // set to 0 to deactivate effect
    },
    settings = $.extend(defaults, options);

    function fixedEncodeURIComponent (str) {
      return encodeURIComponent(str).replace(/[!'()*]/g, function(c) {
        return '%' + c.charCodeAt(0).toString(16);
      });
    }

    var headers = $(settings.headers).filter(function() {
      // get all headers with an ID
      var previousSiblingName = $(this).prev().attr( "name" );
      if (!this.id && previousSiblingName) {
        this.id = $(this).attr( "id", previousSiblingName.replace(/\./g, "-") );
      }
      return this.id;
    }), output = $(this);
    if (!headers.length || headers.length < settings.minimumHeaders || !output.length) {
      return;
    }

    if (0 === settings.showSpeed) {
      settings.showEffect = 'none';
    }

    var render = {
      show: function() {
        $('#toc').addClass('toc');
        output.hide().html(html).show(settings.showSpeed); 
      },
      slideDown: function() { output.hide().html(html).slideDown(settings.showSpeed); },
      fadeIn: function() { output.hide().html(html).fadeIn(settings.showSpeed); },
      none: function() { output.html(html); }
    };

    var get_level = function(ele) { return parseInt(ele.nodeName.replace("H", ""), 10); }
    var highest_level = headers.map(function(_, ele) { return get_level(ele); }).get().sort()[0];
    var return_to_top = '<i class="icon-arrow-up back-to-top"> </i>';

    var level = get_level(headers[0]),
      this_level,
      html = settings.title + " <"+settings.listType+">";
    headers.on('click', function() {
      if (!settings.noBackToTopLinks) {
        window.location.hash = this.id;
      }
    })
    .addClass('clickable-header')
    .each(function(_, header) {
      this_level = get_level(header);
      if (!settings.noBackToTopLinks && this_level === highest_level) {
        $(header).addClass('top-level-header').after(return_to_top);
      }
      if (this_level === level) // same level as before; same indenting
        html += "<li><a href='#" + fixedEncodeURIComponent(header.id) + "'>" + header.innerHTML + "</a>";
      else if (this_level <= level){ // higher level than before; end parent ol
        for(i = this_level; i < level; i++) {
          html += "</li></"+settings.listType+">"
        }
        html += "<li><a href='#" + fixedEncodeURIComponent(header.id) + "'>" + header.innerHTML + "</a>";
      }
      else if (this_level > level) { // lower level than before; expand the previous to contain a ol
        for(i = this_level; i > level; i--) {
          html += "<"+settings.listType+"><li>"
        }
        html += "<a href='#" + fixedEncodeURIComponent(header.id) + "'>" + header.innerHTML + "</a>";
      }
      level = this_level; // update for the next one
    });
    html += "</"+settings.listType+">";
    if (!settings.noBackToTopLinks) {
      $(document).on('click', '.back-to-top', function() {
        $(window).scrollTop(0);
        window.location.hash = '';
      });
    }

    render[settings.showEffect]();
  };
})(jQuery);

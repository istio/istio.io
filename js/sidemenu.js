(function($) {
  $(document).ready( function() {
    var sidebarOpen = true;
    var sidebar = $("#sidebar-container");
    var content = $("#content-container");
    var tab = $("#tab-container");
    var width = $(document). width();

    function setSidebar() {
      // set sidebar height, breakpoint at iPad in landscape
      //if (screen.height > 768)
      //  sidebar.height($('footer').position().top + 50);
    
      // 992 is the default breakpoint set in Bootstrap 3 for col-md
      var width = $(document).width();
      if (width < 992) {
        sidebar.hide();
        sidebarOpen = false;
      }
    }

    $(document).on('click', '#sidebar-tab', function() {
      $(this).toggleClass('glyphicon-chevron-right');
      $(this).toggleClass('glyphicon-chevron-left');
      sidebar.toggle(250);
      sidebarOpen = !sidebarOpen;

      if (!sidebarOpen) {
        tab.removeClass("col-xs-1");
        tab.removeClass("tab-neg-margin");
        tab.removeClass("pull-left");

        content.removeClass("thin-left-border");
        content.removeClass("col-sm-9");
        content.addClass("col-sm-11");
      }
      else {
        tab.addClass("col-xs-1");
        tab.addClass("tab-neg-margin");
        tab.addClass("pull-left");
        
        content.removeClass("col-sm-11");
        content.addClass("thin-left-border");
        content.addClass("col-sm-9");
      }
    });

    /* toggle category tree */
    $(document).on('click', '.tree-toggle', function () {
        $(this).children('i.fa').toggleClass('fa-caret-right');
        $(this).children('i.fa').toggleClass('fa-caret-down');
        $(this).parent().children('ul.tree').toggle(200);
    });

    function onWindowResize() {
    	setSidebar();
    }

    // initialize
    window.addEventListener('resize', onWindowResize, false);
    window.onload = function() {
      setSidebar();
    }
  });
}(jQuery));

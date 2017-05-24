(function($) {
  $(document).ready( function() {
    var sidebarOpen = true;
    var sidebar = $("#sidebar-container");
    var content = $("#content-container");
    var tab = $("#tab-container");
    var sidebarTab = $("#sidebar-tab");
    var hasExpandedNavOnSmallScreen = false;

    function setSidebar() {
      // set sidebar height, breakpoint at iPad in landscape
      //if (screen.height > 768)
      //  sidebar.height($('footer').position().top + 50);
    
      // 992 is the default breakpoint set in Bootstrap 3 for col-md
      var width = $(document).width();
      if (width < 992 && !hasExpandedNavOnSmallScreen) {
        sidebar.hide();
        sidebarTab.removeClass('glyphicon-chevron-left');
        sidebarTab.addClass('glyphicon-chevron-right');
        sidebarOpen = false;
      }
    }

    $(document).on('click', '#sidebar-tab', function() {
      hasExpandedNavOnSmallScreen = true;
      $(this).toggleClass('glyphicon-chevron-right');
      $(this).toggleClass('glyphicon-chevron-left');
      sidebar.toggle(250);
      sidebarOpen = !sidebarOpen;

      if (!sidebarOpen) {
        tab.removeClass("col-xs-1 tab-neg-margin pull-left");

        content.removeClass("thin-left-border col-sm-9");
        content.addClass("col-sm-11");
      }
      else {
        tab.addClass("col-xs-1 tab-neg-margin pull-left");
        
        content.removeClass("col-sm-11");
        content.addClass("thin-left-border col-sm-9");
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

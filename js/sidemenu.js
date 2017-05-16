(function($) {
  $(document).ready( function() {
    var sidebarOpen = true;
    var sidebar = $("#sidebar-container");
    var content = $("#content-container");
    var width = $(document). width();

    function setSidebar() {
      // set sidebar height, breakpoint at iPad in landscape
      if (screen.height > 768)
        sidebar.height($('footer').position().top + 50);
    
      // 992 is the default breakpoint set in Bootstrap 3 for col-md
      if (width < 992) {
        sidebar.toggle();
        sidebar.sidebarOpen = !sidebar.sidebarOpen;
      }

    /*
      // 1756 is a judgement call on the breakpoint for when the sidebar needs a col-lg-3 and not col-lg-12
      if (width < 1756) {
        if (sidebar.hasClass("col-lg-2"))
          sidebar.removeClass("col-lg-2");
        if (!sidebar.hasClass("col-lg-3"))
          sidebar.addClass("col-lg-3");

        if (content.hasClass("col-lg-10"))
          content.removeClass("col-lg-10");
        if (!content.hasClass("col-lg-9"))
          content.addClass("col-lg-9");
      }
      else {
        if (sidebar.hasClass("col-lg-3"))
          sidebar.removeClass("col-lg-3");
        if (!sidebar.hasClass("col-lg-2"))
          sidebar.addClass("col-lg-2");

        if (content.hasClass("col-lg-9"))
          content.removeClass("col-lg-9");
        if (!content.hasClass("col-lg-10"))
          content.addClass("col-lg-10");
      }
    */
    }

    $(document).on('click', '#sidebar-tab', function() {
      $(this).toggleClass('glyphicon-chevron-right');
      $(this).toggleClass('glyphicon-chevron-left');
      sidebar.toggle(250);
      sidebarOpen = !sidebarOpen;
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

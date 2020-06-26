


(function ($) {
    function doSearch() {
        var url = '/v0.2/search/?q=' + document.getElementsByName('q')[0].value;
        window.location.assign(url);
    }

    $(document).ready(function() {
        $('#searchbox_demo').on('submit', function(e) {
            e.preventDefault();
            doSearch();
        });

        $('.btn-search').on('click', function(e) {
            e.preventDefault();
            doSearch();
        });

        function setSearchBoxSize() {
            var width = screen.width < 1024 ? "20" : "30";
            $("input[name='q']").attr("size", width);
        }

        var resizeTimeout;
        function resizeThrottler() {
            function timeoutHandler() {
                resizeTimeout = null;
                actualResizeHandler();
            }

            // ignore resize events as long as an actualResizeHandler execution is in the queue
            if ( !resizeTimeout ) {
                resizeTimeout = setTimeout(timeoutHandler, 66);
            }
        }

        function actualResizeHandler() {
            setSearchBoxSize();
        }

        $(window).on('resize', resizeThrottler);
        setSearchBoxSize();
    });
}(jQuery));

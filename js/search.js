(function ($) {
    function doSearch() {
        var url = '/docs/search/?q=' + document.getElementsByName('q')[0].value;
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
    });
}(jQuery));

(function ($) {
    $(document).ready(function() {
        $('#searchbox_demo').on('submit', function(e) {
            e.preventDefault();
            var url = '/docs/search/?q=' + document.getElementsByName('q')[0].value;
            window.location.assign(url);
        });
    });
}(jQuery));

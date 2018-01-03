---
---
{% include home.html %}

"use strict"

function doSearch() {
    var url = '{{home}}/search?q=' + document.getElementsByName('q')[0].value;
    window.location.assign(url);
}

$(function ($) {
    $(document).ready(function() {
        $('.btn-search').on('click', function(e) {
            e.preventDefault();
            doSearch();
        });

        // toggle sidebar on/off
        $('[data-toggle="offcanvas"]').on('click', function () {
            $('.row-offcanvas').toggleClass('active')
            $(this).children('i.fa').toggleClass('fa-chevron-right');
            $(this).children('i.fa').toggleClass('fa-chevron-left');
        })

        // toggle category tree in sidebar
        $(document).on('click', '.tree-toggle', function () {
            $(this).children('i.fa').toggleClass('fa-caret-right');
            $(this).children('i.fa').toggleClass('fa-caret-down');
            $(this).parent().children('ul.tree').toggle(200);
        });
    });
}(jQuery));

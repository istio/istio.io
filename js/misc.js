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

        // toggle copy button
        $(document).on('mouseenter', 'pre', function () {
            $(this).children("div.copy").toggleClass("show", true)
            $(this).children("div.copy").toggleClass("hide", false)
        });

        // toggle copy button
        $(document).on('mouseleave', 'pre', function () {
            $(this).children("div.copy").toggleClass("show", false)
            $(this).children("div.copy").toggleClass("hide", true)
        });
    });
}(jQuery));

(function(){
    var div = "<div class='copy hide'><a style='color: white' class='copy-button'>Copy</a></div>";
    var pre = document.getElementsByTagName('PRE');
    for (var i = 0; i < pre.length; i++) {
        pre[i].insertAdjacentHTML('afterbegin', div);
    };

    var copyCode = new Clipboard('.copy-button', {
        target: function(trigger) {
            return trigger.parentElement.nextElementSibling;
        }
    });

    // On success:
    // - Change the "Copy" text to "Done".
    // - Swap it to "Copy" in 2s.

    copyCode.on('success', function(event) {
        event.clearSelection();
        event.trigger.textContent = 'Done';
        window.setTimeout(function() {
            event.trigger.textContent = 'Copy';
        }, 2000);
    });

    // On error (Safari):
    // - Change to "Not supported"
    // - Swap it to "Copy" in 2s.

    copyCode.on('error', function(event) {
        event.trigger.textContent = 'Not supported';
        window.setTimeout(function() {
            event.trigger.textContent = 'Copy';
        }, 5000);
    });
})();

(function(){
    function anchorForId(id) {
        var anchor = document.createElement("a");
        anchor.className = "header-link";
        anchor.href      = "#" + id;
        anchor.innerHTML = "<i class=\"fa fa-link\"></i>";
        return anchor;
    }

    function linkifyAnchors(level, containingElement) {
        var headers = containingElement.getElementsByTagName("h" + level);
        for (var h = 0; h < headers.length; h++) {
            var header = headers[h];

            if (typeof header.id !== "undefined" && header.id !== "") {
                header.appendChild(anchorForId(header.id));
            }
        }
    }

    for (var level = 1; level <= 6; level++) {
        linkifyAnchors(level, document);
    }

    var links = document.getElementsByTagName("a")
    for (var i = 0; i < links.length; i++) {
        var l = links[i]
        if (l.hostname && l.hostname != location.hostname) {
            l.setAttribute("target", "_blank")
        }
    }
})();

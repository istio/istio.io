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
            $(this).next().toggleClass("copy-show", true)
            $(this).next().toggleClass("copy-hide", false)
        });

        // toggle copy button
        $(document).on('mouseleave', 'pre', function () {
            $(this).next().toggleClass("copy-show", false)
            $(this).next().toggleClass("copy-hide", true)
        });

        // toggle copy button
        $(document).on('mouseenter', 'button.copy', function () {
            $(this).toggleClass("copy-show", true)
            $(this).toggleClass("copy-hide", false)
        });

        // toggle copy button
        $(document).on('mouseleave', 'button.copy', function () {
            $(this).toggleClass("copy-show", false)
            $(this).toggleClass("copy-hide", true)
        });
    });
}(jQuery));

// Apply a bunch of systematic modification to the DOM of all pages.
// Ideally, this stuff could be handled offline as part of preparing the
// HTML, but alas our current toolchain won't allow that in a clean/simple
// way.
function patchDOM() {
    // Add a Copy button to all PRE blocks
    function attachCopyButtons() {
        var pre = document.getElementsByTagName('PRE');
        for (var i = 0; i < pre.length; i++) {
            var button = document.createElement("BUTTON");
            button.title = "Copy to clipboard";
            button.className = "copy copy-hide";
            button.innerText = "Copy";

            pre[i].parentElement.appendChild(button);
        }

        var copyCode = new Clipboard('button.copy', {
            target: function (trigger) {
                return trigger.previousElementSibling;
            }
        });

        // On success:
        // - Change the "Copy" text to "Done".
        // - Swap it to "Copy" in 2s.

        copyCode.on('success', function (event) {
            event.clearSelection();
            event.trigger.textContent = 'Done';
            window.setTimeout(function () {
                event.trigger.textContent = 'Copy';
            }, 2000);
        });

        // On error (Safari):
        // - Change to "Not supported"
        // - Swap it to "Copy" in 2s.

        copyCode.on('error', function (event) {
            event.trigger.textContent = 'Not supported';
            window.setTimeout(function () {
                event.trigger.textContent = 'Copy';
            }, 5000);
        });
    }

    // Add a link icon next to each header so people can easily get bookmarks to headers
    function attachLinksToHeaders() {
        for (var level = 1; level <= 6; level++) {
            for (var header in document.getElementsByTagName("h" + level)) {
                if (typeof header.id !== "undefined" && header.id !== "") {
                    var i = document.createElement("i");
                    i.className = "fa fa-link";

                    var anchor = document.createElement("a");
                    anchor.className = "header-link";
                    anchor.href = "#" + header.id;
                    anchor.appendChild(i);

                    header.appendChild(anchor);
                }
            }
        }
    }

    // Make it so each link outside of the current domain opens up in a different window
    function makeOutsideLinksOpenInTabs() {
        for (var link in document.getElementsByTagName("a")) {
            if (link.hostname && link.hostname != location.hostname) {
                link.setAttribute("target", "_blank")
            }
        }
    }

    // Load the content of any externally-hosted PRE blocks
    function loadExternalPreBlocks() {

        function fetchFile(elem, url) {
            fetch(url).then(response => response.text()).then(data => {
                elem.firstChild.innerText = data;
            });
        }

        var pre = document.getElementsByTagName('PRE');
        for (var i = 0; i < pre.length; i++) {
            if (pre[i].hasAttribute("data-src")) {
                fetchFile(pre[i], pre[i].getAttribute("data-src"))
            }
        }
    }

    attachCopyButtons();
    attachLinksToHeaders();
    makeOutsideLinksOpenInTabs();
    loadExternalPreBlocks();
}

document.addEventListener("DOMContentLoaded", patchDOM)

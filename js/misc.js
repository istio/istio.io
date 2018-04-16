---
---
{% include home.html %}

"use strict"

$(function ($) {
    // Show the navbar links, hide the search box
    function showLinks() {
        var $form = $('#search_form')
        var $textbox = $('#search_textbox');
        var $links = $('#navbar-links')

        $form.removeClass('active');
        $links.addClass('active');
        $textbox.val('');
        $textbox.removeClass("grow");
    }

    // Show the navbar search box, hide the links
    function showSearchBox() {
        var $form = $('#search_form')
        var $textbox = $('#search_textbox');
        var $links = $('#navbar-links')

        $form.addClass('active');
        $links.removeClass('active');
        $textbox.addClass("grow");
        $textbox.focus();
    }

    // Hide the search box when the user hits the ESC key
    $('body').on('keyup', function(event) {
        if (event.which == 27) {
            showLinks();
        }
    });

    // Show the search box
    $('#search_show').on('click', function(event) {
        event.preventDefault();
        showSearchBox();
    });

    // Hide the search box
    $('#search_close').on('click', function(event) {
        event.preventDefault();
        showLinks();
    });

    // When the user submits the search form, initiate a search
    $('#search_form').submit(function(event) {
        event.preventDefault();
        var $textbox = $('#search_textbox');
        var url = '{{home}}/search.html?q=' + $textbox.val();
        showLinks();
        window.location.assign(url);
    });

    $(document).ready(function() {
        // toggle sidebar on/off
        $('[data-toggle="offcanvas"]').on('click', function () {
            $('.row-offcanvas').toggleClass('active')
            $(this).children('i.fa').toggleClass('fa-flip-horizontal');
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
            button.setAttribute("aria-label", "Copy to clipboard");

            var parent = pre[i].parentElement;
            if (parent.tagName == "DIV") {
                // This is the case for HTML produced from markdown through Jekyll
                parent.appendChild(button);
            } else {
                // This is the case for HTML produced by protoc-gen-docs from proto sources
                // we hackily create a DIV on the fly to make this case look like what we get
                // from Jekyll
                var div = document.createElement("DIV")
                div.className = "highlight"
                parent.insertBefore(div, pre[i])
                div.appendChild(pre[i])
                div.appendChild(button)
            }
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

    function attachLink(node) {
        var i = document.createElement("i");
        i.className = "fa fa-link";

        var anchor = document.createElement("a");
        anchor.className = "header-link";
        anchor.href = "#" + node.id;
        anchor.setAttribute("aria-hidden", "true");
        anchor.appendChild(i);

        node.appendChild(anchor);
    }

    // Add a link icon next to each header so people can easily get bookmarks to headers
    function attachLinksToHeaders() {
        for (var level = 1; level <= 6; level++) {
            var headers = document.getElementsByTagName("h" + level);
            for (var i = 0; i < headers.length; i++) {
                var header = headers[i]
                if (header.id !== "") {
                    attachLink(header);
                }
            }
        }
    }

    // Add a link icon next to each defined term so people can easily get bookmarks to them in the glossary
    function attachLinksToDefinedTerms() {
        var terms = document.getElementsByTagName("dt");
        for (var i = 0; i < terms.length; i++) {
            var term = terms[i]
            if (term.id !== "") {
                attachLink(term);
            }
        }
    }

    // Make it so each link outside of the current domain opens up in a different window
    function makeOutsideLinksOpenInTabs() {
        var links = document.getElementsByTagName("a");
        for (var i = 0; i < links.length; i++) {
            var link = links[i];
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

    function createEndnotes() {
        var notes = document.getElementById("endnotes");
        if (notes == undefined) {
            return;
        }

        // look for anchors in the main section of the doc only (skip headers, footers, tocs, nav bars, etc)
        var main = document.getElementsByTagName("main")[0];
        var links = main.getElementsByTagName("a");
        var count = 1;
        for (var i = 0; i < links.length; i++) {
            var link = links[i];
            if (link.pathname == location.pathname) {
                // skip links on the current page
                continue;
            }

            if (link.pathname.endsWith("/") && link.hash != "") {
                // skip links on the current page
                continue;
            }

            if (link.parentElement.tagName == "FIGURE") {
                // skip links inside figures
                continue;
            }

            // add the superscript reference
            link.insertAdjacentHTML("afterend", "<sup class='endnote-ref'>" + count + "</sup>");

            // and add a list entry for the link
            var li = document.createElement("li");
            li.innerText = link.href;
            notes.appendChild(li);
            count++;
        }
    }

    attachCopyButtons();
    attachLinksToHeaders();
    attachLinksToDefinedTerms();
    makeOutsideLinksOpenInTabs();
    loadExternalPreBlocks();
    createEndnotes();
}

// initialized after the DOM has been loaded
var scrollToTopButton;
var tocLinks;
var tocHeadings;

// discover a few DOM elements up front so we don't need to do it a zillion times for the life of the page
function getDOMTopology() {
    scrollToTopButton = document.getElementById("scroll-to-top");

    var toc = document.getElementById("toc");
    if (toc != undefined) {
        tocLinks = toc.getElementsByTagName("A");
        tocHeadings = new Array(tocLinks.length);

        for (var i = 0; i < tocLinks.length; i++) {
            tocHeadings[i] = document.getElementById(tocLinks[i].hash.substring(1));
        }
    }

    // one forced call here to make sure everything looks right
    handleScroll();
}

function handleScroll() {
    // Based on the scroll position, make the "scroll to top" button visible or not
    function controlScrollToTopButton() {
        if (scrollToTopButton) {
            if (document.body.scrollTop > 300 || document.documentElement.scrollTop > 300) {
                scrollToTopButton.style.display = "block";
            } else {
                scrollToTopButton.style.display = "none";
            }
        }
    }

    // Based on the scroll position, activate a TOC entry
    function controlTOCActivation() {
        if (tocLinks) {
            var closestHeadingBelowTop = -1;
            var closestHeadingBelowTopPos = 1000000;
            var closestHeadingAboveTop = -1;
            var closestHeadingAboveTopPos = -1000000;

            for (var i = 0; i < tocLinks.length; i++) {
                var cbr = tocHeadings[i].getBoundingClientRect();

                if (cbr.width || cbr.height) {
                    if ((cbr.top >= 0) && (cbr.top < window.innerHeight)) {
                        // heading is on the screen
                        if (cbr.top < closestHeadingBelowTopPos) {
                            closestHeadingBelowTop = i;
                            closestHeadingBelowTopPos = cbr.top;
                        }
                    } else if (cbr.top < 0) {
                        // heading is above the screen
                        if (cbr.top > closestHeadingAboveTopPos) {
                            closestHeadingAboveTop = i;
                            closestHeadingAboveTopPos = cbr.top;
                        }
                    }
                }

                tocLinks[i].classList.remove("current");
            }

            if (closestHeadingBelowTop >= 0) {
                tocLinks[closestHeadingBelowTop].classList.add("current");
            } else if (closestHeadingAboveTop >= 0) {
                tocLinks[closestHeadingAboveTop].classList.add("current");
            }
        }
    }

    controlScrollToTopButton();
    controlTOCActivation();
}

// Scroll the document to the top
function scrollToTop() {
    document.body.scrollTop = 0; // For Safari
    document.documentElement.scrollTop = 0; // For Chrome, Firefox, IE and Opera
}

document.addEventListener("DOMContentLoaded", patchDOM);
document.addEventListener("DOMContentLoaded", getDOMTopology);
window.addEventListener("scroll", handleScroll);

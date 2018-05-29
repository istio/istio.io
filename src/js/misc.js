"use strict";

$(function ($) {
    // Show the navbar links, hide the search box
    function showLinks() {
        var $form = $('#search_form');
        var $textbox = $('#search_textbox');
        var $links = $('#navbar-links');

        $form.removeClass('active');
        $links.addClass('active');
        $textbox.val('');
        $textbox.removeClass("grow");
    }

    // Show the navbar search box, hide the links
    function showSearchBox() {
        var $form = $('#search_form');
        var $textbox = $('#search_textbox');
        var $links = $('#navbar-links');

        $form.addClass('active');
        $links.removeClass('active');
        $textbox.addClass("grow");
        $textbox.focus();
    }

    // Hide the search box when the user hits the ESC key
    $('body').on('keyup', function(event) {
        if (event.which === 27) {
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
        var $search_page_url = $('#search_page_url');
        var url = $search_page_url.val() + '?q=' + $textbox.val();
        showLinks();
        window.location.assign(url);
    });

    $(document).ready(function() {
        // toggle sidebar on/off
        $('[data-toggle="offcanvas"]').on('click', function () {
            $('.row-offcanvas').toggleClass('active');
            $(this).children('i.fa').toggleClass('fa-flip-horizontal');
        });

        // toggle category tree in sidebar
        $(document).on('click', '.tree-toggle', function () {
            $(this).children('i.fa').toggleClass('fa-caret-right');
            $(this).children('i.fa').toggleClass('fa-caret-down');
            $(this).parent().children('ul.tree').toggle(200);
        });

        // toggle copy button
        $(document).on('mouseenter', 'pre', function () {
            $(this).next().toggleClass("copy-show", true);
            $(this).next().toggleClass("copy-hide", false)
        });

        // toggle copy button
        $(document).on('mouseleave', 'pre', function () {
            $(this).next().toggleClass("copy-show", false);
            $(this).next().toggleClass("copy-hide", true)
        });

        // toggle copy button
        $(document).on('mouseenter', 'button.copy', function () {
            $(this).toggleClass("copy-show", true);
            $(this).toggleClass("copy-hide", false)
        });

        // toggle copy button
        $(document).on('mouseleave', 'button.copy', function () {
            $(this).toggleClass("copy-show", false);
            $(this).toggleClass("copy-hide", true)
        });
    });
}(jQuery));

// Scroll the document to the top
function scrollToTop() {
    document.body.scrollTop = 0; // For Safari
    document.documentElement.scrollTop = 0; // For Chrome, Firefox, IE and Opera
}

// initialized after the DOM has been loaded by getDOMTopology
var scrollToTopButton;
var tocLinks;
var tocHeadings;

// post-processing we do once the DOM has loaded
function handleDOMLoaded() {

    // Apply a bunch of systematic modification to the DOM of all pages.
    // Ideally, this stuff could be handled offline as part of preparing the
    // HTML, but alas our current toolchain won't allow that in a clean/simple
    // way.
    function patchDOM() {

        // To compensate for https://github.com/gohugoio/hugo/issues/4785, certain code blocks are
        // indented in markdown by four spaces. This removes these four spaces so that the visuals
        // are correct.
        function compensateForHugoBug() {
            var code = document.getElementsByTagName('CODE');
            for (var i = 0; i < code.length; i++) {
                var text = code[i].innerText;
                var lines = text.split("\n");
                if ((lines.length > 0) && lines[0].startsWith("    ")) {
                    for (var j = 0; j < lines.length; j++) {
                        if (lines[j].startsWith("    ")) {
                            lines[j] = lines[j].slice(4);
                        }
                    }
                    code[i].innerText = lines.join('\n');
                }
            }
        }

        // Add a Copy button to all PRE blocks
        function attachCopyButtons() {
            var pre = document.getElementsByTagName('PRE');
            for (var i = 0; i < pre.length; i++) {
                var button = document.createElement("BUTTON");
                button.title = "Copy to clipboard";
                button.className = "copy copy-hide";
                button.innerText = "Copy";
                button.setAttribute("aria-label", "Copy to clipboard");

                // wrap the PRE block in a DIV so we have a place to attach the copy button
                var div = document.createElement("DIV");
                div.className = "copy";
                pre[i].parentElement.insertBefore(div, pre[i]);
                div.appendChild(pre[i]);
                div.appendChild(button);

                // apply syntax highlighting
                Prism.highlightElement(pre[i].firstChild, false);
            }

            var copyCode = new Clipboard('button.copy', {
                text: function (trigger) {
                    var commands = trigger.previousElementSibling.getElementsByClassName("command");
                    if ((commands !== null) && (commands.length > 0)) {
                        var lines = commands[0].innerText.split("\n");
                        var cmd = "";
                        for (var i = 0; i < lines.length; i++) {
                            if (lines[i].startsWith("$ ")) {
                                lines[i] = lines[i].substring(2);
                            }

                            if (cmd !== "") {
                                cmd = cmd + "\n";
                            }

                            cmd += lines[i];
                        }

                        return cmd;
                    }

                    return trigger.previousElementSibling.innerText;
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

        function applySyntaxColoring() {
            var pre = document.getElementsByTagName('PRE');
            for (var i = 0; i < pre.length; i++) {
                var code = pre[i].firstChild;

                var cl = "";
                for (var j = 0; j < code.classList.length; j++) {
                    if (code.classList.item(j).startsWith("language-command")) {
                        cl = code.classList.item(j);
                        break;
                    }
                }

                if (cl !== "") {
                    var text = code.innerText;
                    var lines = text.split("\n");

                    var bottom = false;
                    var cmd = "";
                    var output = "";
                    var escape = false;
                    for (var j = 0; j < lines.length; j++) {
                        var line = lines[j];

                        if (bottom) {
                            output = output + "\n" + line;
                        } else {
                            if (line.startsWith("$ ")) {
                                // line is definitely a command
                            } else if (escape) {
                                // continuation
                            } else {
                                bottom = true;
                                output = line;
                                continue;
                            }

                            escape = (line.endsWith("\\"));

                            if (cmd !== "") {
                                cmd = cmd + "\n";
                            }
                            cmd = cmd + line;
                        }
                    }

                    // in case someone forgot the $, treat everything as a command instead of as output
                    if (cmd === "") {
                        cmd = output;
                        output = "";
                    }

                    var colored = Prism.highlight(cmd, Prism.languages["bash"], "bash");
                    var html = "<div class='command'>" + colored + "</div>";

                    if (output !== "") {
                        // apply formatting to the output?
                        var prefix = "language-command-output-as-";
                        if (cl.length > prefix.length) {
                            var lang = cl.substr(prefix.length);
                            output = Prism.highlight(output, Prism.languages[lang], lang);
                        }

                        html += "<div class='output'>" + output + "</div>";
                    }

                    code.innerHTML = html;
                    code.classList.remove(cl);
                    code.classList.add("command-output");
                } else {
                    Prism.highlightElement(code, false);
                }
            }
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
                    var header = headers[i];
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
                var term = terms[i];
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
                if (link.hostname && link.hostname !== location.hostname) {
                    link.setAttribute("target", "_blank");
                    link.setAttribute("rel", "noopener");
                }
            }
        }

        // Load the content of any externally-hosted PRE blocks
        function loadExternalPreBlocks() {

            function fetchFile(elem, url) {
                fetch(url).then(function (response) {
                    return response.text();
                }).then(function (data) {
                    elem.firstChild.innerText = data;
                    Prism.highlightElement(elem.firstChild, false);
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
            if (notes === null) {
                return;
            }

            // look for anchors in the main section of the doc only (skip headers, footers, tocs, nav bars, etc)
            var main = document.getElementsByTagName("main")[0];
            var links = main.getElementsByTagName("a");
            var map = new Map(null);
            for (var i = 0; i < links.length; i++) {
                var link = links[i];
                if (link.pathname === location.pathname) {
                    // skip links on the current page
                    continue;
                }

                if (link.pathname.endsWith("/") && link.hash !== "") {
                    // skip links on the current page
                    continue;
                }

                if (link.classList.contains("not-for-endnotes")) {
                    // skip links that don't want to be included
                    continue;
                }

                var count = map.get(link.href);
                if (count === undefined) {
                    count = map.size + 1;
                    map.set(link.href, count);

                    // add a list entry for the link
                    var li = document.createElement("li");
                    li.innerText = link.href;
                    notes.appendChild(li);
                }

                // add the superscript reference
                link.insertAdjacentHTML("afterend", "<sup class='endnote-ref'>" + count + "</sup>");
            }
        }

        compensateForHugoBug();
        attachCopyButtons();
        applySyntaxColoring();
        attachLinksToHeaders();
        attachLinksToDefinedTerms();
        makeOutsideLinksOpenInTabs();
        loadExternalPreBlocks();
        createEndnotes();
    }

    // discover a few DOM elements up front so we don't need to do it a zillion times for the life of the page
    function getDOMTopology() {
        scrollToTopButton = document.getElementById("scroll-to-top");

        var toc = document.getElementById("toc");
        if (toc !== null) {
            tocLinks = toc.getElementsByTagName("A");
            tocHeadings = new Array(tocLinks.length);

            for (var i = 0; i < tocLinks.length; i++) {
                tocHeadings[i] = document.getElementById(tocLinks[i].hash.substring(1));
            }
        }
    }

    patchDOM();
    getDOMTopology();

    // one forced call here to make sure everything looks right
    handlePageScroll();
}

// What we do when the user scrolls the page
function handlePageScroll() {
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

document.addEventListener("DOMContentLoaded", handleDOMLoaded);
window.addEventListener("scroll", handlePageScroll);

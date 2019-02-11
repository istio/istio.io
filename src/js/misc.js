"use strict";

$(function ($) {
    // Show the navbar links, hide the search box
    function showNavBarLinks() {
        var $form = $('#search_form');
        var $textbox = $('#search_textbox');
        var $links = $('#navbar-links');

        $form.removeClass('active');
        $links.addClass('active');
        $textbox.val('');
    }

    // Show the navbar search box, hide the links
    function showSearchBox() {
        var $form = $('#search_form');
        var $textbox = $('#search_textbox');
        var $links = $('#navbar-links');

        $form.addClass('active');
        $links.removeClass('active');
        $textbox.focus();
    }

    // Hide the search box when the user hits the ESC key
    $('body').on('keyup', function(event) {
        if (event.which === 27) {
            showNavBarLinks();
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
        showNavBarLinks();
    });

    // When the user submits the search form, initiate a search
    $('#search_form').submit(function(event) {
        event.preventDefault();
        var $textbox = $('#search_textbox');
        var $search_page_url = $('#search_page_url');
        var url = $search_page_url.val() + '?q=' + $textbox.val();
        showNavBarLinks();
        window.location.assign(url);
    });

    var recurse = false;

    // Save a cookie when a user selects a tab in a tabset
    $('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
        if (recurse) {
            // prevent endless recursion...
            return;
        }

        var tab = e.target;
        var cookie_name = tab.getAttribute("data-cookie-name");
        var cookie_value = tab.getAttribute("data-cookie-value");
        if (cookie_name === null || cookie_name === "") {
            return;
        }

        createCookie(cookie_name, cookie_value);

        var tabs = document.querySelectorAll('a[data-toggle="tab"]');
        for (var i = 0; i < tabs.length; i++) {
            var tab = tabs[i];
            if (cookie_name === tab.getAttribute("data-cookie-name")) {
                if (cookie_value === tab.getAttribute("data-cookie-value")) {

                    // there's gotta be a way to call the tab() function directly since I already have the
                    // requisite object in hand. Alas, I can't figure it out. So query the document to find
                    // the same object again, and call the tab function on the result.
                    recurse = true;
                    $('.nav-tabs a[href="' + tab.hash + '"]').tab('show');
                    recurse = false;
                }
            }
        }
    });

    $(document).ready(function() {
        // toggle sidebar on/off
        $('#sidebar-toggler').on('click', function () {
            $('#sidebar-container').toggleClass('active');
            $(this).children('svg.icon').toggleClass('flipped');
        });

        // toggle category tree in sidebar
        $(document).on('click', '.tree-toggle', function () {
            $(this).children('i.chevron').toggleClass('d-none');
            $(this).parent().children('ul.tree').toggle(200);
        });

        // toggle toolbar buttons
        $(document).on('mouseenter', 'pre', function () {
            $(this).next().addClass("toolbar-show");
            $(this).next().next().addClass("toolbar-show");
            $(this).next().next().next().addClass("toolbar-show");
        });

        // toggle toolbar buttons
        $(document).on('mouseleave', 'pre', function () {
            $(this).next().removeClass("toolbar-show");
            $(this).next().next().removeClass("toolbar-show");
            $(this).next().next().next().removeClass("toolbar-show");
        });

        // toggle copy button
        $(document).on('mouseenter', 'button.copy', function () {
            $(this).addClass("toolbar-show");
        });

        // toggle copy button
        $(document).on('mouseleave', 'button.copy', function () {
            $(this).removeClass("toolbar-show");
        });

        // toggle download button
        $(document).on('mouseenter', 'button.download', function () {
            $(this).addClass("toolbar-show");
        });

        // toggle download button
        $(document).on('mouseleave', 'button.download', function () {
            $(this).removeClass("toolbar-show");
        });

        // toggle print button
        $(document).on('mouseenter', 'button.print', function () {
            $(this).addClass("toolbar-show");
        });

        // toggle print button
        $(document).on('mouseleave', 'button.print', function () {
            $(this).removeClass("toolbar-show");
        });

        // activate the popovers
        $("[data-toggle=popover]").popover();
    });
}(jQuery));

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

        // Add a toolbar to all PRE blocks
        function attachToolbarToPreBlocks() {
            var pre = document.getElementsByTagName('PRE');
            for (var i = 0; i < pre.length; i++) {
                var copyButton = document.createElement("BUTTON");
                copyButton.title = buttonCopy;
                copyButton.className = "copy";
                copyButton.innerHTML = "<svg><use xlink:href='" + iconFile + "#copy'/></svg>";
                copyButton.setAttribute("aria-label", "Copy to clipboard");

                var downloadButton = document.createElement("BUTTON");
                downloadButton.title = buttonDownload;
                downloadButton.className = "download";
                downloadButton.innerHTML = "<svg><use xlink:href='" + iconFile + "#download'/></svg>";
                downloadButton.setAttribute("aria-label", downloadButton.title);
                downloadButton.onclick = function(e) {
                    var div = e.currentTarget.parentElement;
                    var codes = div.getElementsByTagName("CODE");
                    if ((codes !== null) && (codes.length > 0)) {
                        var code = codes[0];
                        var text = getToolbarDivText(div);
                        var downloadas = code.getAttribute("data-downloadas");
                        if (downloadas === null || downloadas === "") {
                            downloadas = "foo";

                            var lang = "";
                            for (var j = 0; j < code.classList.length; j++) {
                                if (code.classList.item(j).startsWith("language-")) {
                                    lang = code.classList.item(j).substr(9);
                                    break;
                                }
                            }

                            if (lang.startsWith("command")) {
                                lang = "bash";
                            } else if (lang === "") {
                                lang = "txt";
                            }

                            downloadas = docTitle + "." + lang;
                        }
                        saveFile(downloadas, text);
                    }
                    return true;
                };

                var printButton = document.createElement("BUTTON");
                printButton.title = buttonPrint;
                printButton.className = "print";
                printButton.innerHTML = "<svg><use xlink:href='" + iconFile + "#printer'/></svg>";
                printButton.setAttribute("aria-label", printButton.title);
                printButton.onclick = function(e) {
                    var div = e.currentTarget.parentElement;
                    var text = getToolbarDivText(div);
                    printText(text);
                    return true;
                };

                // wrap the PRE block in a DIV so we have a place to attach the toolbar buttons
                var div = document.createElement("DIV");
                div.className = "toolbar";
                pre[i].parentElement.insertBefore(div, pre[i]);
                div.appendChild(pre[i]);
                div.appendChild(printButton);
                div.appendChild(downloadButton);
                div.appendChild(copyButton);
            }

            var copyCode = new ClipboardJS('button.copy', {
                text: function (trigger) {
                    return getToolbarDivText(trigger.parentElement);
                }
            });

            copyCode.on('error', function (event) {
                alert("Sorry, but copying is not supported by your browser");
            });
        }

        function getToolbarDivText(div) {
            var commands = div.getElementsByClassName("command");
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

            return div.innerText;
        }

        function applySyntaxColoringToPreBlocks() {
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
                    var outputStart = 0;
                    var lines = code.innerText.split("\n");
                    var cmd = "";
                    var escape = false;
                    var escapeUntilEOF = false;
                    var tmp = "";
                    for (var j = 0; j < lines.length; j++) {
                        var line = lines[j];

                        if (line.startsWith("$ ")) {
                            if (tmp !== "") {
                                cmd += "$ " + Prism.highlight(tmp, Prism.languages["bash"], "bash") + "\n";
                            }

                            tmp = line.slice(2);

                            if (line.contains("<<EOF")) {
                                escapeUntilEOF = true;
                            }
                        } else if (escape) {
                            // continuation
                            tmp += "\n" + line;

                            if (line.endsWith("<<EOF")) {
                                escapeUntilEOF = true;
                            }
                        } else if (escapeUntilEOF) {
                            tmp += "\n" + line;
                            if (line === "EOF") {
                                escapeUntilEOF = false;
                            }
                        } else {
                            outputStart = j;
                            break;
                        }

                        escape = line.endsWith("\\");
                    }

                    if (tmp !== "") {
                        cmd += "$ " + Prism.highlight(tmp, Prism.languages["bash"], "bash") + "\n";
                    }

                    if (cmd !== "") {
                        cmd = cmd.replace(/@(.*?)@/g, "<a href='https://raw.githubusercontent.com/istio/istio/" + branchName + "/$1'>$1</a>");

                        var html = "<div class='command'>" + cmd + "</div>";

                        var output = "";
                        if (outputStart > 0) {
                            for (var j = outputStart; j < lines.length; j++) {
                                if (output !== "") {
                                    output += "\n";
                                }
                                output += lines[j];
                            }
                        }

                        if (output !== "") {
                            // apply formatting to the output?
                            var prefix = "language-command-output-as-";
                            if (cl.startsWith(prefix)) {
                                var lang = cl.substr(prefix.length);
                                output = Prism.highlight(output, Prism.languages[lang], lang);
                            } else {
                                output = escapeHTML(output);
                            }

                            html += "<div class='output'>" + output + "</div>";
                        }

                        code.innerHTML = html;
                        code.classList.remove(cl);
                        code.classList.add("command-output");
                    } else {
                        // someone probably forgot to start a block with $, so let's just treat the whole thing as being a `bash` block
                        Prism.highlightElement(code, false);
                    }
                } else {
                    // this isn't one of our special code blocks, so handle normally
                    Prism.highlightElement(code, false);
                }
            }
        }

        function attachLink(node) {
            var anchor = document.createElement("a");
            anchor.className = "header-link";
            anchor.href = "#" + node.id;
            anchor.setAttribute("aria-hidden", "true");
            anchor.innerHTML = "<svg class='icon'><use xlink:href='" + iconFile + "#links'/></svg>";

            node.appendChild(anchor);
        }

        // Add a link icon next to each header so people can easily get bookmarks to headers
        function attachLinksToHeaders() {
            for (var level = 2; level <= 6; level++) {
                var headers = document.getElementsByTagName("h" + level.toString());
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
                    elem.firstChild.textContent = data;
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
            var num_links = 0;
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

                if (link.classList.contains("btn")) {
                    // skip button links
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
                num_links++;
            }

            if (num_links === 0) {
                // if there are no links on this page, hide the whole section
                var div = document.getElementsByClassName("link-endnotes")[0];
                div.style.display = "none";
            }
        }

        attachToolbarToPreBlocks();
        applySyntaxColoringToPreBlocks();
        attachLinksToHeaders();
        attachLinksToDefinedTerms();
        makeOutsideLinksOpenInTabs();
        loadExternalPreBlocks();
        createEndnotes();
    }

    function selectTabs() {
        var tabs = document.querySelectorAll('a[data-toggle="tab"]');
        for (var i = 0; i < tabs.length; i++) {
            var tab = tabs[i];
            var cookie_name = tab.getAttribute("data-cookie-name");
            var cookie_value = tab.getAttribute("data-cookie-value");

            if (cookie_name === null || cookie_name === "") {
                continue;
            }

            var v = readCookie(cookie_name);
            if (cookie_value === v) {
                // there's gotta be a way to call the tab() function directly since I already have the
                // requisite object in hand. Alas, I can't figure it out. So query the document to find
                // the same object again, and call the tab function on the result.
                $('.nav-tabs a[href="' + tab.hash + '"]').tab('show');
            }
        }
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
    selectTabs();
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
                var heading = tocHeadings[i];
                if (heading === null) {
                    continue;
                }

                var cbr = heading.getBoundingClientRect();

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

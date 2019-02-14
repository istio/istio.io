"use strict";

// initialized after the DOM has been loaded by getDOMTopology
let scrollToTopButton;
let tocLinks;
let tocHeadings;

// post-processing we do once the DOM has loaded
function handleDOMLoaded() {

    // Apply a bunch of systematic modification to the DOM of all pages.
    // Ideally, this stuff could be handled offline as part of preparing the
    // HTML, but alas our current toolchain won't allow that in a clean/simple
    // way.
    function patchDOM() {

        function attachLink(node) {
            const anchor = document.createElement("a");
            anchor.className = "header-link";
            anchor.href = "#" + node.id;
            anchor.setAttribute("aria-hidden", "true");
            anchor.innerHTML = "<svg class='icon'><use xlink:href='" + iconFile + "#links'/></svg>";

            node.appendChild(anchor);
        }

        // Add a link icon next to each header so people can easily get bookmarks to headers
        function attachLinksToHeaders() {
            for (let level = 2; level <= 6; level++) {
                document.querySelectorAll("h" + level.toString()).forEach(hdr => {
                    if (hdr.id !== "") {
                        attachLink(hdr);
                    }
                });
            }
        }

        // Add a link icon next to each defined term so people can easily get bookmarks to them in the glossary
        function attachLinksToDefinedTerms() {
            document.querySelectorAll('dt').forEach(dt => {
                if (dt.id !== "") {
                    attachLink(dt);
                }
            });
        }

        // Make it so each link outside of the current domain opens up in a different window
        function makeOutsideLinksOpenInTabs() {
            document.querySelectorAll('a').forEach(link => {
                if (link.hostname && link.hostname !== location.hostname) {
                    link.setAttribute("target", "_blank");
                    link.setAttribute("rel", "noopener");
                }
            });
        }

        function createEndnotes() {
            const notes = document.getElementById("endnotes");
            if (notes === null) {
                return;
            }

            // look for anchors in the main section of the doc only (skip headers, footers, tocs, nav bars, etc)
            const main = document.getElementsByTagName("main")[0];
            const map = new Map(null);
            let num_links = 0;
            main.querySelectorAll('a').forEach(link => {
                if (link.pathname === location.pathname) {
                    // skip links on the current page
                    return;
                }

                if (link.pathname.endsWith("/") && link.hash !== "") {
                    // skip links on the current page
                    return;
                }

                if (link.classList.contains("btn")) {
                    // skip button links
                    return;
                }

                if (link.classList.contains("not-for-endnotes")) {
                    // skip links that don't want to be included
                    return;
                }

                let count = map.get(link.href);
                if (count === undefined) {
                    count = map.size + 1;
                    map.set(link.href, count);

                    // add a list entry for the link
                    const li = document.createElement("li");
                    li.innerText = link.href;
                    notes.appendChild(li);
                }

                // add the superscript reference
                link.insertAdjacentHTML("afterend", "<sup class='endnote-ref'>" + count + "</sup>");
                num_links++;
            });

            if (num_links === 0) {
                // if there are no links on this page, hide the whole section
                const div = document.getElementsByClassName("link-endnotes")[0];
                div.style.display = "none";
            }
        }

        function fixupPreBlocks() {

            // Add a toolbar to all PRE blocks
            function attachToolbar(pre) {
                const copyButton = document.createElement("BUTTON");
                copyButton.title = buttonCopy;
                copyButton.className = "copy";
                copyButton.innerHTML = "<svg><use xlink:href='" + iconFile + "#copy'/></svg>";
                copyButton.setAttribute("aria-label", "Copy to clipboard");
                copyButton.addEventListener("mouseenter", (e) => e.currentTarget.classList.add("toolbar-show"));
                copyButton.addEventListener("mouseleave", (e) => e.currentTarget.classList.remove("toolbar-show"));

                const downloadButton = document.createElement("BUTTON");
                downloadButton.title = buttonDownload;
                downloadButton.className = "download";
                downloadButton.innerHTML = "<svg><use xlink:href='" + iconFile + "#download'/></svg>";
                downloadButton.setAttribute("aria-label", downloadButton.title);
                downloadButton.addEventListener("mouseenter", (e) => e.currentTarget.classList.add("toolbar-show"));
                downloadButton.addEventListener("mouseleave", (e) => e.currentTarget.classList.remove("toolbar-show"));

                downloadButton.addEventListener("click", (e) => {
                    const div = e.currentTarget.parentElement;
                    const codes = div.getElementsByTagName("CODE");
                    if ((codes !== null) && (codes.length > 0)) {
                        const code = codes[0];
                        const text = getToolbarDivText(div);
                        let downloadas = code.getAttribute("data-downloadas");
                        if (downloadas === null || downloadas === "") {
                            let lang = "";
                            for (let j = 0; j < code.classList.length; j++) {
                                if (code.classList.item(j).startsWith("language-")) {
                                    lang = code.classList.item(j).substr(9);
                                    break;
                                }
                            }

                            if (lang.startsWith("command")) {
                                lang = "bash";
                            } else if (lang === "markdown") {
                                lang = "md";
                            } else if (lang === "") {
                                lang = "txt";
                            }

                            downloadas = docTitle + "." + lang;
                        }
                        saveFile(downloadas, text);
                    }
                    return true;
                });

                const printButton = document.createElement("BUTTON");
                printButton.title = buttonPrint;
                printButton.className = "print";
                printButton.innerHTML = "<svg><use xlink:href='" + iconFile + "#printer'/></svg>";
                printButton.setAttribute("aria-label", printButton.title);
                printButton.addEventListener("mouseenter", (e) => e.currentTarget.classList.add("toolbar-show"));
                printButton.addEventListener("mouseleave", (e) => e.currentTarget.classList.remove("toolbar-show"));

                printButton.addEventListener("click", (e) => {
                    const div = e.currentTarget.parentElement;
                    const text = getToolbarDivText(div);
                    printText(text);
                    return true;
                });

                // wrap the PRE block in a DIV so we have a place to attach the toolbar buttons
                const div = document.createElement("DIV");
                div.className = "toolbar";
                pre.parentElement.insertBefore(div, pre);
                div.appendChild(pre);
                div.appendChild(printButton);
                div.appendChild(downloadButton);
                div.appendChild(copyButton);

                pre.addEventListener("mouseenter", (e) => {
                    e.currentTarget.nextSibling.classList.add("toolbar-show");
                    e.currentTarget.nextSibling.nextSibling.classList.add("toolbar-show");
                    e.currentTarget.nextSibling.nextSibling.nextSibling.classList.add("toolbar-show");
                });

                pre.addEventListener("mouseleave", (e) => {
                    e.currentTarget.nextSibling.classList.remove("toolbar-show");
                    e.currentTarget.nextSibling.nextSibling.classList.remove("toolbar-show");
                    e.currentTarget.nextSibling.nextSibling.nextSibling.classList.remove("toolbar-show");
                });
            }

            function getToolbarDivText(div) {
                const commands = div.getElementsByClassName("command");
                if ((commands !== null) && (commands.length > 0)) {
                    const lines = commands[0].innerText.split("\n");
                    let cmd = "";
                    for (let i = 0; i < lines.length; i++) {
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

            function applySyntaxColoring(pre) {
                const code = pre.firstChild;

                let cl = "";
                for (let j = 0; j < code.classList.length; j++) {
                    if (code.classList.item(j).startsWith("language-command")) {
                        cl = code.classList.item(j);
                        break;
                    }
                }

                if (cl !== "") {
                    let firstLineOfOutput = 0;
                    let lines = code.innerText.split("\n");
                    let cmd = "";
                    let escape = false;
                    let escapeUntilEOF = false;
                    let tmp = "";
                    for (let j = 0; j < lines.length; j++) {
                        const line = lines[j];

                        if (line.startsWith("$ ")) {
                            if (tmp !== "") {
                                cmd += "$ " + Prism.highlight(tmp, Prism.languages["bash"], "bash") + "\n";
                            }

                            tmp = line.slice(2);

                            if (line.includes("<<EOF")) {
                                escapeUntilEOF = true;
                            }
                        } else if (escape) {
                            // continuation
                            tmp += "\n" + line;

                            if (line.includes("<<EOF")) {
                                escapeUntilEOF = true;
                            }
                        } else if (escapeUntilEOF) {
                            tmp += "\n" + line;
                            if (line === "EOF") {
                                escapeUntilEOF = false;
                            }
                        } else {
                            firstLineOfOutput = j;
                            break;
                        }

                        escape = line.endsWith("\\");
                    }

                    if (tmp !== "") {
                        cmd += "$ " + Prism.highlight(tmp, Prism.languages["bash"], "bash") + "\n";
                    }

                    if (cmd !== "") {
                        cmd = cmd.replace(/@(.*?)@/g, "<a href='https://raw.githubusercontent.com/istio/istio/" + branchName + "/$1'>$1</a>");

                        let html = "<div class='command'>" + cmd + "</div>";

                        let output = "";
                        if (firstLineOfOutput > 0) {
                            for (let j = firstLineOfOutput; j < lines.length; j++) {
                                if (output !== "") {
                                    output += "\n";
                                }
                                output += lines[j];
                            }
                        }

                        if (output !== "") {
                            // apply formatting to the output?
                            let prefix = "language-command-output-as-";
                            if (cl.startsWith(prefix)) {
                                let lang = cl.substr(prefix.length);
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

            // Load the content of any externally-hosted PRE block
            function loadExternal(pre) {

                function fetchFile(elem, url) {
                    fetch(url).then(function (response) {
                        return response.text();
                    }).then(function (data) {
                        elem.firstChild.textContent = data;
                        Prism.highlightElement(elem.firstChild, false);
                    });
                }

                if (pre.hasAttribute("data-src")) {
                    fetchFile(pre, pre.getAttribute("data-src"))
                }
            }

            document.querySelectorAll('pre').forEach((pre) => {
                attachToolbar(pre);
                applySyntaxColoring(pre);
                loadExternal(pre);
            });

            const clipboard = new ClipboardJS('button.copy', {
                text: function (trigger) {
                    return getToolbarDivText(trigger.parentElement);
                }
            });

            clipboard.on('error', () => alert("Sorry, but copying is not supported by your browser"));
        }

        fixupPreBlocks();
        attachLinksToHeaders();
        attachLinksToDefinedTerms();
        makeOutsideLinksOpenInTabs();
        createEndnotes();
    }

    function selectTabs() {
        document.querySelectorAll('a[data-toggle="tab"]').forEach(tab => {
            const cookie_name = tab.getAttribute("data-cookie-name");
            const cookie_value = tab.getAttribute("data-cookie-value");

            if (cookie_name === null || cookie_name === "") {
                return;
            }

            const v = readCookie(cookie_name);
            if (cookie_value === v) {
                // there's gotta be a way to call the tab() function directly since I already have the
                // requisite object in hand. Alas, I can't figure it out. So query the document to find
                // the same object again, and call the tab function on the result.
                $('.nav-tabs a[href="' + tab.hash + '"]').tab('show');
            }
        });
    }

    // discover a few DOM elements up front so we don't need to do it a zillion times for the life of the page
    function getDOMTopology() {
        scrollToTopButton = document.getElementById("scroll-to-top");

        const toc = document.getElementById("toc");
        if (toc !== null) {
            tocLinks = toc.getElementsByTagName("A");
            tocHeadings = new Array(tocLinks.length);

            for (let i = 0; i < tocLinks.length; i++) {
                tocHeadings[i] = document.getElementById(tocLinks[i].hash.substring(1));
            }
        }
    }

    function attachSearchHandlers() {
        // Show the navbar links, hide the search box
        function showNavBarLinks() {
            document.getElementById('search_form').classList.remove('active');
            document.getElementById('navbar-links').classList.add('active');
            document.getElementById('search_textbox').value = '';
        }

        // Show the navbar search box, hide the links
        function showSearchBox() {
            document.getElementById('search_form').classList.add('active');
            document.getElementById('navbar-links').classList.remove('active');
            document.getElementById('search_textbox').focus();
        }

        // Hide the search box when the user hits the ESC key
        document.body.addEventListener("keyup", e => {
            if (e.which === 27) {
                showNavBarLinks();
            }
        });

        // Show the search box
        document.getElementById('search_show').addEventListener("click", e => {
            e.preventDefault();
            showSearchBox();
        });

        // Hide the search box
        document.getElementById('search_close').addEventListener("click", e => {
            e.preventDefault();
            showNavBarLinks();
        });

        // When the user submits the search form, initiate a search
        document.getElementById('search_form').addEventListener("submit", e => {
            e.preventDefault();
            const textbox = document.getElementById('search_textbox');
            const search_page_url = document.getElementById('search_page_url');
            const url = search_page_url.value + '?q=' + textbox.value;
            showNavBarLinks();
            window.location.assign(url);
        });
    }

    function attachSidebarHandlers() {
        // toggle subtree in sidebar
        document.querySelectorAll('.tree-toggle').forEach(o => {
            o.addEventListener("click", () => {
                o.querySelectorAll('i.chevron').forEach(chevron => {
                    chevron.classList.toggle('show');
                });

                if (o.nextElementSibling.style.display === "none") {
                    o.nextElementSibling.style.display = "block";
                } else {
                    o.nextElementSibling.style.display = "none";
                }
            });
        });

        // toggle sidebar on/off
        const toggler = document.getElementById('sidebar-toggler');
        if (toggler) {
            toggler.addEventListener("click", (e) => {
                document.getElementById("sidebar-container").classList.toggle('active');
                e.currentTarget.querySelector('svg.icon').classList.toggle('flipped');
            });
        }
    }

    let recurse = false;

    function attachTabHandlers() {
        // Save a cookie when a user selects a tab in a tabset
        $('a[data-toggle="tab"]').on('shown.bs.tab', e => {
            if (recurse) {
                // prevent endless recursion...
                return;
            }

            let tab = e.target;
            let cookie_name = tab.getAttribute("data-cookie-name");
            let cookie_value = tab.getAttribute("data-cookie-value");
            if (cookie_name === null || cookie_name === "") {
                return;
            }

            createCookie(cookie_name, cookie_value);

            document.querySelectorAll('a[data-toggle="tab"]').forEach(tab => {
                if (cookie_name === tab.getAttribute("data-cookie-name")) {
                    if (cookie_value === tab.getAttribute("data-cookie-value")) {
                        // there's gotta be a way to call the tab() function directly since I already have the
                        // DOM object in hand. Alas, I can't figure it out. So query and call the tab function on the result.
                        recurse = true;
                        $('.nav-tabs a[href="' + tab.hash + '"]').tab('show');
                        recurse = false;
                    }
                }
            });
        });
    }

    function enablePopovers() {
        // activate the popovers
        $("[data-toggle=popover]").popover();
    }

    patchDOM();
    selectTabs();
    getDOMTopology();
    attachSearchHandlers();
    attachSidebarHandlers();
    attachTabHandlers();
    enablePopovers();
    loadActiveStyleSheet();

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
            let closestHeadingBelowTop = -1;
            let closestHeadingBelowTopPos = 1000000;
            let closestHeadingAboveTop = -1;
            let closestHeadingAboveTopPos = -1000000;

            for (let i = 0; i < tocLinks.length; i++) {
                const heading = tocHeadings[i];
                if (heading === null) {
                    continue;
                }

                const cbr = heading.getBoundingClientRect();

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

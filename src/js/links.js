"use strict";

function handleLinks() {

    function attachSelfLink(node) {
        if (node.id === "") {
            return;
        }

        const anchor = document.createElement("a");
        anchor.className = "self-link";
        anchor.href = "#" + node.id;
        anchor.setAttribute("aria-hidden", "true");
        anchor.innerHTML = "<svg class='icon'><use xlink:href='" + iconFile + "#links'/></svg>";

        node.appendChild(anchor);
    }

    function attachSelfLinks() {
        // add a link icon next to each header so people can easily get bookmarks to headers
        queryAll(document, "h2").forEach(attachSelfLink);
        queryAll(document, "h3").forEach(attachSelfLink);
        queryAll(document, "h4").forEach(attachSelfLink);
        queryAll(document, "h5").forEach(attachSelfLink);
        queryAll(document, "h6").forEach(attachSelfLink);

        // add a link icon next to each defined term so people can easily get bookmarks to them in the glossary
        queryAll(document, "dt").forEach(attachSelfLink);
    }

    // Make it so each link outside of the current domain opens up in a different window
    function makeOutsideLinksOpenInTabs() {
        queryAll(document, "a").forEach(link => {
            if (link.hostname && link.hostname !== location.hostname) {
                link.setAttribute("target", "_blank");
                link.setAttribute("rel", "noopener");
            }
        });
    }

    // Create the set of endnotes that expand URLs when printing
    function createEndnotes() {
        const notes = getById("endnotes");
        if (notes === null) {
            return;
        }

        // look for anchors in the main section of the main article only (skip headers, footers, tocs, nav bars, etc)
        const article = document.getElementsByTagName("article")[0];
        const map = new Map(null);
        let numLinks = 0;
        queryAll(article, 'a').forEach(link => {
            if (link.pathname === location.pathname) {
                // skip links pointing to the current page
                return;
            }

            if (link.pathname.endsWith("/") && link.hash !== "") {
                // skip links pointing to the current page
                return;
            }

            if (link.classList.contains("btn")) {
                // skip button links
                return;
            }

            if (link.dataset.skipendnotes === "true") {
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
            link.insertAdjacentHTML("afterend", "<sup class='endnote-ref' aria-hidden='true'>" + count + "</sup>");
            numLinks++;
        });

        if (numLinks > 0) {
            // only show the section if there are links
            getById("endnotes-container").classList.add('show');
        }
    }

    attachSelfLinks();
    makeOutsideLinksOpenInTabs();
    createEndnotes();
}

handleLinks();

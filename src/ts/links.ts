// Copyright 2019 Istio Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

declare var iconFile: string;

function handleLinks(): void {

    function attachSelfLink(node: HTMLElement): void {
        if (node.id === "") {
            return;
        }

        const anchor = document.createElement("a");
        anchor.className = "self-link";
        anchor.href = "#" + node.id;
        anchor.setAttribute("aria-hidden", "true");
        anchor.setAttribute("tabindex", "-1");
        anchor.innerHTML = "<svg class='icon'><use xlink:href='" + iconFile + "#links'/></svg>";

        node.appendChild(anchor);
    }

    function attachSelfLinks(): void {
        // add a link icon next to each header so people can easily get bookmarks to headers
        document.querySelectorAll("h2").forEach(attachSelfLink);
        document.querySelectorAll("h3").forEach(attachSelfLink);
        document.querySelectorAll("h4").forEach(attachSelfLink);
        document.querySelectorAll("h5").forEach(attachSelfLink);
        document.querySelectorAll("h6").forEach(attachSelfLink);

        // add a link icon next to each defined term so people can easily get bookmarks to them in the glossary
        document.querySelectorAll("dt").forEach(attachSelfLink);
    }

    // Make it so each link outside of the current domain opens up in a different window
    function makeOutsideLinksOpenInTabs(): void {
        document.querySelectorAll("a").forEach(link => {
            if (link.hostname && link.hostname !== location.hostname) {
                link.setAttribute("target", "_blank");
                link.setAttribute("rel", "noopener");
            }
        });
    }

    // Create the set of endnotes that expand URLs when printing
    function createEndnotes(): void {
        const notes = getById("endnotes");
        if (!notes) {
            return;
        }

        // look for anchors in the main section of the main article only (skip headers, footers, tocs, nav bars, etc)
        const article = document.getElementsByTagName("article")[0];
        const map = new Map(null);
        let numLinks = 0;
        article.querySelectorAll("a").forEach(link => {
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
            const ec = getById("endnotes-container");
            if (ec) {
                ec.classList.add("show");
            }
        }
    }

    attachSelfLinks();
    makeOutsideLinksOpenInTabs();
    createEndnotes();
}

handleLinks();

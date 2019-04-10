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

// initialized after the DOM has been loaded
let scrollToTopButton: HTMLElement | null;
let tocLinks: HTMLCollectionOf<HTMLAnchorElement>;
let tocHeadings: HTMLElement[] = [];
let pageHeader: HTMLElement | null;

function handleScroll(): void {
    function dealWithScroll(): void {
        // Based on the scroll position, make the "scroll to top" button visible or not
        function controlScrollToTopButton(): void {
            if (scrollToTopButton) {
                if (document.body.scrollTop > 300 || document.documentElement.scrollTop > 300) {
                    scrollToTopButton.classList.add("show");
                } else {
                    scrollToTopButton.classList.remove("show");
                }
            }
        }

        // Based on the scroll position, activate a TOC entry
        function controlTOCActivation(): void {
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

                    // get the bounding rectangle of the heading's text area (ignores borders, margins, etc)
                    const range = document.createRange();
                    range.setStart(heading, 0);
                    range.setEnd(heading, 1);
                    const cbr = range.getBoundingClientRect();

                    if (cbr.width || cbr.height) {
                        if ((cbr.top >= pageHeaderHeight) && (cbr.top < window.innerHeight)) {
                            // heading top is on the screen
                            if (cbr.top + cbr.height - 1 < window.innerHeight) {
                                // heading bottom is on the screen
                                if (cbr.top + cbr.height - 1 < closestHeadingBelowTopPos) {
                                    closestHeadingBelowTop = i;
                                    closestHeadingBelowTopPos = cbr.top;
                                }
                            }
                        } else if (cbr.top < pageHeaderHeight) {
                            // heading is above the visible portion of the page
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

        const pageHeaderHeight = (pageHeader ? pageHeader.getBoundingClientRect().height : 0);

        controlScrollToTopButton();
        controlTOCActivation();

        // HACK ALERT! When deep linking to a table row, the row ends up under the page header. This
        // hack is here to detect that case and force-scroll the row into view.
        //
        // Note that this only works once for a given target row per page load. If the user is clicking
        // around within a page, the second click to the same deep link will not trigger this hack and
        // the user will be left with the row under the page header.
        const target = document.querySelector<HTMLElement>(":target");
        if (target && target.tagName === "TR" && !target.dataset.scrolled) {
            document.documentElement.scrollTop -= pageHeaderHeight;
            target.dataset.scrolled = "true";
        }
    }

    // discover a few DOM elements up front so we don't need to do it a zillion times for the life of the page

    scrollToTopButton = getById("scroll-to-top");
    listen(scrollToTopButton, click, () => {
        // scroll the document to the top
        document.body.scrollTop = 0;            // for Safari
        document.documentElement.scrollTop = 0; // for Chrome, Firefox, IE and Opera
    });

    const toc = getById("toc");
    if (toc) {
        tocLinks = toc.getElementsByTagName("a");
        for (const link of tocLinks) {
            if (link) {
                const id = link.hash.substring(1);
                const hdr = getById(id);
                if (hdr) {
                    tocHeadings.push(hdr);
                }
            }
        }
    }

    pageHeader = document.getElementsByTagName("header")[0];

    // make sure things look right if we load a page to a specific anchor position
    dealWithScroll();

    // what we do when the user scrolls the page
    listen(window, "scroll", dealWithScroll);
}

handleScroll();

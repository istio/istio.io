"use strict";

// initialized after the DOM has been loaded
let scrollToTopButton;
let tocLinks;
let tocHeadings;

// what we do when the user scrolls the page
window.addEventListener("scroll", handlePageScroll);

// discover a few DOM elements up front so we don't need to do it a zillion times for the life of the page
document.addEventListener('DOMContentLoaded', () => {
    scrollToTopButton = document.getElementById('scroll-to-top');

    const toc = document.getElementById('toc');
    if (toc) {
        tocLinks = toc.getElementsByTagName('a');
        tocHeadings = new Array(tocLinks.length);

        for (let i = 0; i < tocLinks.length; i++) {
            tocHeadings[i] = document.getElementById(tocLinks[i].hash.substring(1));
        }
    }

    // make sure things look right if we load a page to a specific anchor position
    handlePageScroll();
});

function handlePageScroll() {
    // Based on the scroll position, make the "scroll to top" button visible or not
    function controlScrollToTopButton() {
        if (scrollToTopButton) {
            if (document.body.scrollTop > 300 || document.documentElement.scrollTop > 300) {
                scrollToTopButton.classList.add('show');
            } else {
                scrollToTopButton.classList.remove('show');
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

    // HACK ALERT! When deep linking to a table row, the row ends up under the page header. This
    // hack is here to detect that case and force-scroll the row into view.
    //
    // Note that this only works once for a given target row per page load. If the user is clicking
    // around within a page, the second click to the same deep link will not trigger this hack and
    // the user will be left with the row under the page header.
    const target = document.querySelector(":target");
    if (target && target.tagName === 'TR' && !target.dataset.scrolled) {
        document.documentElement.scrollTop -= 55;   // where 55 is the approximate header height
        target.dataset.scrolled = 'true';
    }
}

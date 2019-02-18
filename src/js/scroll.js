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
    if (toc !== null) {
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
}

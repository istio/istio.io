"use strict";

function handleTabs() {
    queryAll(document, ".tabset").forEach(tabset => {
        queryAll(tabset, ".tab-strip").forEach(strip => {
            const cookieName = strip.dataset.cookieName;

            // select the active tabs on the page per cookie values
            if (cookieName) {
                const cookieValue = readCookie(cookieName);
                if (cookieValue) {
                    queryAll(strip, "a").forEach(anchor => {
                        if (anchor.dataset.cookieValue === cookieValue) {
                            anchor.classList.add(active);
                            getById(anchor.dataset.tab).classList.add(active);
                        } else {
                            anchor.classList.remove(active);
                            getById(anchor.dataset.tab).classList.remove(active);
                        }
                    });
                }
            }

            // attach the event handlers to support tab sets
            queryAll(strip, "a").forEach(anchor => {
                listen(anchor, click, () => {
                    queryAll(strip, "a").forEach(anchor2 => {
                        anchor2.classList.remove(active);
                        getById(anchor2.dataset.tab).classList.remove(active);
                    });

                    anchor.classList.add(active);
                    getById(anchor.dataset.tab).classList.add(active);
                    if (cookieName !== null) {
                        createCookie(cookieName, anchor.dataset.cookieValue);
                    }
                });
            });
        });
    });
}

handleTabs();

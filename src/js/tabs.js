"use strict";

function handleTabs() {

    function updateLikeTabsets(cookieName, cookieValue) {
        queryAll(document, "[role=tablist]").forEach(tabset => {
            queryAll(tabset, ".tab-strip").forEach(strip => {
                if (strip.dataset.cookieName === cookieName) {
                    queryAll(strip, button).forEach(tab => {
                        if (tab.dataset.cookieValue === cookieValue) {
                            tab.classList.add(active);
                            getById(tab.dataset.tab).classList.add(active);
                        } else {
                            tab.classList.remove(active);
                            getById(tab.dataset.tab).classList.remove(active);
                        }
                    });
                }
            });
        });
    }

    queryAll(document, "[role=tablist]").forEach(tabset => {
        queryAll(tabset, ".tab-strip").forEach(strip => {
            const cookieName = strip.dataset.cookieName;
            if (cookieName) {
                const cookieValue = readCookie(cookieName);
                if (cookieValue) {
                    updateLikeTabsets(cookieName, cookieValue);
                }
            }

            // attach the event handlers to support tab sets
            queryAll(strip, button).forEach(tab => {
                listen(tab, click, () => {
                    queryAll(strip, button).forEach(tab2 => {
                        tab2.classList.remove(active);
                        getById(tab2.dataset.tab).classList.remove(active);
                    });

                    tab.classList.add(active);
                    getById(tab.dataset.tab).classList.add(active);
                    if (cookieName !== null) {
                        createCookie(cookieName, tab.dataset.cookieValue);
                        updateLikeTabsets(cookieName, tab.dataset.cookieValue);
                    }
                });
            });
        });
    });
}

handleTabs();

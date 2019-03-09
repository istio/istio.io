"use strict";

function handleTabs() {
    queryAll(document, "[role=tablist]").forEach(tabset => {
        queryAll(tabset, ".tab-strip").forEach(strip => {
            const cookieName = strip.dataset.cookieName;

            // select the active tabs on the page per cookie values
            if (cookieName) {
                const cookieValue = readCookie(cookieName);
                if (cookieValue) {
                    queryAll(strip, button).forEach(tab => {
                        if (tab.dataset.cookieValue === cookieValue) {
                            tab.classList.add(active);
                            tab.tabIndex = -1;
                            getById(tab.dataset.tab).classList.add(active);
                        } else {
                            tab.classList.remove(active);
                            getById(tab.dataset.tab).classList.remove(active);
                        }
                    });
                }
            }

            // attach the event handlers to support tab sets
            queryAll(strip, button).forEach(tab => {
                listen(tab, click, () => {
                    queryAll(strip, button).forEach(tab2 => {
                        tsb2.classList.remove(active);
                        tab2.tabIndex = 0;
                        getById(tab2.dataset.tab).classList.remove(active);
                    });

                    tab.classList.add(active);
                    tab.tabIndex = -1;
                    getById(tab.dataset.tab).classList.add(active);
                    if (cookieName !== null) {
                        createCookie(cookieName, tab.dataset.cookieValue);
                    }
                });
            });
        });
    });
}

handleTabs();

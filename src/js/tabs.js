"use strict";

function handleTabs() {
    queryAll(document, "[role=tablist]").forEach(tabset => {
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
            queryAll(strip, "button").forEach(button => {
                listen(button, click, () => {
                    queryAll(strip, "button").forEach(button2 => {
                        button2.classList.remove(active);
                        getById(button2.dataset.tab).classList.remove(active);
                    });

                    button.classList.add(active);
                    getById(button.dataset.tab).classList.add(active);
                    if (cookieName !== null) {
                        createCookie(cookieName, button.dataset.cookieValue);
                    }
                });
            });
        });
    });
}

handleTabs();

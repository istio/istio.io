"use strict";

document.addEventListener('DOMContentLoaded', () => {

    // Select the active tabs on the page per cookie values
    function selectActiveTabs() {
        document.querySelectorAll(".tabset").forEach(tabset => {
            tabset.querySelectorAll(".tab-strip").forEach(strip => {
                const cookieName = strip.dataset.cookieName;
                if (cookieName) {
                    const cookieValue = readCookie(cookieName);
                    if (cookieValue) {
                        strip.querySelectorAll("a").forEach(anchor => {
                            if (anchor.dataset.cookieValue == cookieValue) {
                                anchor.classList.add("active");
                                document.getElementById(anchor.dataset.tab).classList.add('active');
                            } else {
                                anchor.classList.remove("active");
                                document.getElementById(anchor.dataset.tab).classList.remove('active');
                            }
                        });
                    }
                }
            });
        });
    }

    // Attach the event handlers to support tab sets
    function attachTabHandlers() {
        document.querySelectorAll(".tabset").forEach(tabset => {
            tabset.querySelectorAll(".tab-strip").forEach(strip => {
                const cookieName = strip.dataset.cookieName;
                strip.querySelectorAll("a").forEach(anchor => {
                    const cookieValue = anchor.dataset.cookieValue;
                    anchor.addEventListener("click", () => {
                        strip.querySelectorAll("a").forEach(anchor2 => {
                            anchor2.classList.remove('active');
                            document.getElementById(anchor2.dataset.tab).classList.remove('active');
                        });

                        anchor.classList.add("active");
                        document.getElementById(anchor.dataset.tab).classList.add('active');
                        if (cookieName !== null) {
                            createCookie(cookieName, cookieValue);
                        }
                    });
                });
            });
        });
    }

    selectActiveTabs();
    attachTabHandlers();
});

"use strict";

function handleTabs() {

    function updateLikeTabsets(cookieName, cookieValue) {
        queryAll(document, ".tabset").forEach(tabset => {
            queryAll(tabset, ".tab-strip").forEach(strip => {
                if (strip.dataset.cookieName === cookieName) {
                    queryAll(strip, "[role=tab]").forEach(tab => {
                        const panel = getById(tab.getAttribute("aria-controls"));
                        if (tab.dataset.cookieValue === cookieValue) {
                            tab.setAttribute("aria-selected", "true");
                            tab.setAttribute("tabindex", "-1");
                            panel.removeAttribute("hidden");
                        } else {
                            tab.removeAttribute("aria-selected");
                            tab.setAttribute("tabindex", "-1");
                            panel.setAttribute("hidden", "");
                        }
                    });
                }
            });
        });
    }

    queryAll(document, ".tabset").forEach(tabset => {
        const strip = query(tabset, ".tab-strip");
        if (strip === null) {
            return;
        }

        const cookieName = strip.dataset.cookieName;
        const panels = queryAll(tabset, '[role=tabpanel]');

        const tabs = [];
        queryAll(strip, '[role=tab]').forEach(tab => {
            tabs.push(tab);
        });

        function activateTab(tab) {
            deactivateAllTabs();
            tab.removeAttribute('tabindex');
            tab.setAttribute('aria-selected', 'true');
            getById(tab.getAttribute('aria-controls')).removeAttribute('hidden');
        }

        function deactivateAllTabs() {
            tabs.forEach(tab => {
                tab.setAttribute('tabindex', '-1');
                tab.setAttribute('aria-selected', 'false');
            });

            panels.forEach(panel => {
                panel.setAttribute('hidden', '');
            });
        }

        function focusFirstTab() {
            tabs[0].focus();
        }

        function focusLastTab() {
            tabs[tabs.length - 1].focus();
        }

        function focusNextTab(current) {
            const index = tabs.indexOf(current);
            if (index < tabs.length - 1) {
                tabs[index+1].focus();
            } else {
                tabs[0].focus();
            }
        }

        function focusPrevTab(current) {
            const index = tabs.indexOf(current);
            if (index > 0) {
                tabs[index-1].focus();
            } else {
                tabs[tabs.length - 1].focus();
            }
        }

        function getIndexFirstChars(startIndex, ch) {
            for (let i = startIndex; i < tabs.length; i++) {
                const firstChar = tabs[i].textContent.trim().substring(0, 1).toLowerCase();
                if (ch === firstChar) {
                    return i;
                }
            }
            return -1;
        }

        function focusTabByChar(current, ch) {
            ch = ch.toLowerCase();

            // Check remaining slots in the strip
            let index = getIndexFirstChars(tabs.indexOf(current) + 1, ch);

            // If not found in remaining slots, check from beginning
            if (index === -1) {
                index = getIndexFirstChars(0, ch);
            }

            // If match was found...
            if (index > -1) {
                tabs[index].focus();
            }
        }

        if (cookieName) {
            const cookieValue = readCookie(cookieName);
            if (cookieValue) {
                updateLikeTabsets(cookieName, cookieValue);
            }
        }

        // attach the event handlers to support tab sets
        queryAll(strip, button).forEach(tab => {

            listen(tab, "focus", () => {
                activateTab(tab);

                if (cookieName) {
                    createCookie(cookieName, tab.dataset.cookieValue);
                    updateLikeTabsets(cookieName, tab.dataset.cookieValue);
                }
            });

            listen(tab, keydown, e => {
                const ch = e.key;

                if (e.ctrlKey || e.altKey || e.metaKey) {
                    // nothing
                }
                else if (e.shiftKey) {
                    if (isPrintableCharacter(ch)) {
                        focusTabByChar(tab, ch);
                    }
                } else {
                    switch (e.keyCode) {
                        case keyCodes.LEFT:
                            focusPrevTab(tab);
                            break;

                        case keyCodes.RIGHT:
                            focusNextTab(tab);
                            break;

                        case keyCodes.HOME:
                            focusFirstTab();
                            break;

                        case keyCodes.END:
                            focusLastTab();
                            break;

                        default:
                            if (isPrintableCharacter(ch)) {
                                focusTabByChar(tab, ch);
                            }
                            break;
                    }
                    e.preventDefault();
                    e.cancelBubble = true;
                }
            });
        });
    });
}

handleTabs();

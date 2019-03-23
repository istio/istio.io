"use strict";

function handleTabs() {

    function updateLikeTabsets(cookieName, cookieValue) {
        queryAll(document, ".tabset").forEach(tabset => {
            queryAll(tabset, ".tab-strip").forEach(strip => {
                if (strip.dataset.cookieName === cookieName) {
                    queryAll(strip, "[role=tab]").forEach(tab => {
                        const panel = getById(tab.getAttribute(ariaControls));
                        if (tab.dataset.cookieValue === cookieValue) {
                            tab.setAttribute(ariaSelected, "true");
                            tab.removeAttribute(tabIndex);
                            panel.removeAttribute("hidden");
                        } else {
                            tab.removeAttribute(ariaSelected);
                            tab.setAttribute(tabIndex, "-1");
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

        const kbdnav = new KbdNav(tabs);

        function activateTab(tab) {
            deactivateAllTabs();
            tab.removeAttribute(tabIndex);
            tab.setAttribute(ariaSelected, 'true');
            getById(tab.getAttribute(ariaControls)).removeAttribute('hidden');
        }

        function deactivateAllTabs() {
            tabs.forEach(tab => {
                tab.setAttribute(tabIndex, '-1');
                tab.setAttribute(ariaSelected, 'false');
            });

            panels.forEach(panel => {
                panel.setAttribute('hidden', '');
            });
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

            listen(tab, "click", () => {
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
                        kbdnav.focusElementByChar(ch);
                    }
                } else {
                    switch (e.keyCode) {
                        case keyCodes.LEFT:
                            kbdnav.focusPrevElement();
                            break;

                        case keyCodes.RIGHT:
                            kbdnav.focusNextElement();
                            break;

                        case keyCodes.HOME:
                            kbdnav.focusFirstElement();
                            break;

                        case keyCodes.END:
                            kbdnav.focusLastElement();
                            break;

                        case keyCodes.TAB:
                            return;

                        default:
                            if (isPrintableCharacter(ch)) {
                                kbdnav.focusElementByChar(ch);
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

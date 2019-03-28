"use strict";

// Attach the event handlers to support the sidebar
function handleSidebar() {
    const sidebar = getById('sidebar');
    if (sidebar == null) {
        return;
    }

    // toggle subtree in sidebar
    queryAll(sidebar, '.body').forEach(body => {
        queryAll(body, button).forEach(o => {
            listen(o, click, e => {
                let button = e.currentTarget;
                button.classList.toggle("show");
                const ul = button.nextElementSibling.nextElementSibling;
                toggleAttribute(ul, ariaExpanded);

                let el = ul;
                do {
                    el = el.parentElement;
                } while (!el.classList.contains('body'));

                // adjust the body's max height to the total size of the body's content
                el.style.maxHeight = el.scrollHeight + "px";
            });
        });
    });

    const headers = [];
    queryAll(sidebar, '.header').forEach(header => {
        headers.push(header);
    });

    const kbdnav = new KbdNav(headers);

    function toggleHeader(header) {
        const body = header.nextElementSibling;

        body.classList.toggle('show');
        toggleAttribute(header, ariaExpanded);

        if (body.classList.contains('show')) {
            // set this as the limit for expansion
            body.style.maxHeight = body.scrollHeight + "px";
        } else {
            // if was expanded, reset this
            body.style.maxHeight = null;
        }
    }

    // expand/collapse cards
    queryAll(sidebar, '.header').forEach(header => {
        if (header.classList.contains("dynamic")) {
            listen(header, click, () => {
                toggleHeader(header);
            });

            listen(header, keydown, e => {
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
                        case keyCodes.UP:
                            kbdnav.focusPrevElement();
                            break;

                        case keyCodes.DOWN:
                            kbdnav.focusNextElement();
                            break;

                        case keyCodes.HOME:
                            kbdnav.focusFirstElement();
                            break;

                        case keyCodes.END:
                            kbdnav.focusLastElement();
                            break;

                        case keyCodes.RETURN:
                            toggleHeader(header);
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
        }
    });

    // force expand the default cards
    queryAll(sidebar, '.body').forEach(body => {
        if (body.classList.contains("default")) {
            body.style.maxHeight = body.scrollHeight + "px";
            body.classList.toggle("default");
            body.classList.toggle("show");
            const header = body.previousElementSibling;
            toggleAttribute(header, ariaExpanded);
        }
    });

    // toggle sidebar on/off
    const toggler = getById('sidebar-toggler');
    if (toggler) {
        listen(toggler, click, e => {
            getById("sidebar-container").classList.toggle(active);
            query(e.currentTarget, 'svg.icon').classList.toggle('flipped');
        });
    }
}

handleSidebar();

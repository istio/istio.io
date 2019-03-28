"use strict";

// Attach the event handlers to support menus
function handleMenu() {
    queryAll(document, '.menu').forEach(menu => {
        const trigger = query(menu, ".menu-trigger");
        const content = query(menu, ".menu-content");

        // get all the menu items, setting role="menuitem" and tabindex="-1" along the way
        let items = [];
        for (let i = 0; i < content.children.length; i++) {
            const el = content.children[i];
            if (el.getAttribute("role") === 'menuitem') {
                items.push(el);
            }
        }

        const kbdnav = new KbdNav(items);

        function focusTrigger() {
            trigger.focus();
        }

        listen(trigger, click, e => {
            toggleOverlay(menu);
            toggleAttribute(e.currentTarget, ariaExpanded);
            e.cancelBubble = true;
        });

        listen(trigger, keydown, e => {
            const ch = e.key;

            switch (e.keyCode) {
                case keyCodes.SPACE:
                case keyCodes.RETURN:
                case keyCodes.DOWN:
                    showOverlay(menu);
                    kbdnav.focusFirstElement();
                    break;

                case keyCodes.UP:
                    showOverlay(menu);
                    kbdnav.focusLastElement();
                    break;

                default:
                    if (isPrintableCharacter(ch)) {
                        kbdnav.focusElementByChar(ch);
                    }
                    return;
            }
            e.stopPropagation();
            e.preventDefault();
        });

        items.forEach(el => {
            listen(el, keydown, e => {
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
                        case keyCodes.SPACE:
                            break;

                        case keyCodes.RETURN:
                            const evt = new MouseEvent("click", {
                                view: window,
                                bubbles: true,
                                cancelable: true,
                                clientX: 20,
                            });
                            el.dispatchEvent(evt);
                            break;

                        case keyCodes.ESC:
                        case keyCodes.TAB:
                            focusTrigger();
                            closeActiveOverlay();
                            return;

                        case keyCodes.UP:
                            kbdnav.focusPrevElement();
                            break;

                        case keyCodes.DOWN:
                            kbdnav.focusNextElement();
                            break;

                        case keyCodes.HOME:
                        case keyCodes.PAGEUP:
                            kbdnav.focusFirstElement();
                            break;

                        case keyCodes.END:
                        case keyCodes.PAGEDOWN:
                            kbdnav.focusLastElement();
                            break;

                        default:
                            if (isPrintableCharacter(ch)) {
                                kbdnav.focusElementByChar(ch);
                            }
                            return;
                    }
                    e.stopPropagation();
                    e.preventDefault();
                }
            });
        });
    });
}

handleMenu();

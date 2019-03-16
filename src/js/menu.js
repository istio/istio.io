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

        function focusTrigger() {
            trigger.focus();
        }

        function focusFirstItem() {
            items[0].focus();
        }

        function focusLastItem() {
            items[items.length - 1].focus();
        }

        function focusNextItem(current) {
            const index = items.indexOf(current);
            if (index < items.length - 1) {
                items[index+1].focus();
            } else {
                items[0].focus();
            }
        }

        function focusPrevItem(current) {
            const index = items.indexOf(current);
            if (index > 0) {
                items[index-1].focus();
            } else {
                items[items.length - 1].focus();
            }
        }

        function getIndexFirstChars(startIndex, ch) {
            for (let i = startIndex; i < items.length; i++) {
                const firstChar = items[i].textContent.trim().substring(0, 1).toLowerCase();
                if (ch === firstChar) {
                    return i;
                }
            }
            return -1;
        }

        function focusItemByChar(current, ch) {
            ch = ch.toLowerCase();

            // Check remaining slots in the menu
            let index = getIndexFirstChars(items.indexOf(current) + 1, ch);

            // If not found in remaining slots, check from beginning
            if (index === -1) {
                index = getIndexFirstChars(0, ch);
            }

            // If match was found...
            if (index > -1) {
                if (!isActiveOverlay(menu)) {
                    showOverlay(menu);
                    toggleAttribute(trigger, ariaExpanded);
                }
                items[index].focus();
            }
        }

        listen(trigger, click, e => {
            toggleOverlay(menu);
            toggleAttribute(e.currentTarget, ariaExpanded);
            e.cancelBubble = true;
        });

        listen(trigger, keydown, e => {
            const ch = e.key;

            if (e.ctrlKey || e.altKey || e.metaKey) {
                // nothing
            }
            else if (e.shiftKey) {
                if (isPrintableCharacter(ch)) {
                    focusItemByChar(items[items.length - 1], ch);
                }
            } else {
                switch (e.keyCode) {
                    case keyCodes.SPACE:
                    case keyCodes.RETURN:
                    case keyCodes.DOWN:
                        showOverlay(menu);
                        focusFirstItem();
                        e.preventDefault();
                        e.cancelBubble = true;
                        break;

                    case keyCodes.UP:
                        showOverlay(menu);
                        focusLastItem();
                        e.preventDefault();
                        e.cancelBubble = true;
                        break;

                    default:
                        if (isPrintableCharacter(ch)) {
                            focusItemByChar(items[items.length -1], ch);
                        }
                        break;
                }
            }
        });

        items.forEach(el => {
            listen(el, keydown, e => {
                const ch = e.key;

                if (e.ctrlKey || e.altKey || e.metaKey) {
                    // nothing
                }
                else if (e.shiftKey) {
                    if (isPrintableCharacter(ch)) {
                        focusItemByChar(el, ch);
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
                            break;

                        case keyCodes.UP:
                            focusPrevItem(el);
                            break;

                        case keyCodes.DOWN:
                            focusNextItem(el);
                            break;

                        case keyCodes.HOME:
                        case keyCodes.PAGEUP:
                            focusFirstItem();
                            break;

                        case keyCodes.END:
                        case keyCodes.PAGEDOWN:
                            focusLastItem();
                            break;

                        default:
                            if (isPrintableCharacter(ch)) {
                                focusItemByChar(el, ch);
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

handleMenu();

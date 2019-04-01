// Copyright 2019 Istio Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Attach the event handlers to support menus
function handleMenu(): void {
    document.querySelectorAll<HTMLElement>(".menu").forEach(menu => {
        const trigger = menu.querySelector<HTMLElement>(".menu-trigger");
        const content = menu.querySelector<HTMLElement>(".menu-content");

        if (!trigger || !content) {
            // malformed menu
            return;
        }

        // get all the menu items, setting role="menuitem" and tabindex="-1" along the way
        const items: HTMLElement[] = [];
        for (const el of content.children) {
            const child = el as HTMLElement;
            if (child.getAttribute("role") === "menuitem") {
                items.push(child);
            }
        }

        const kbdnav = new KbdNav(items);

        function focusTrigger() {
            if (trigger) {
                trigger.focus();
            }
        }

        listen(trigger, click, e => {
            toggleOverlay(menu);
            toggleAttribute((e.currentTarget as HTMLElement), ariaExpanded);
            e.cancelBubble = true;
        });

        listen(trigger, keydown, o => {
            const e = o as KeyboardEvent;
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
            listen(el, keydown, o => {
                const e = o as KeyboardEvent;
                const ch = e.key;

                if (e.ctrlKey || e.altKey || e.metaKey) {
                    // nothing
                } else if (e.shiftKey) {
                    if (isPrintableCharacter(ch)) {
                        kbdnav.focusElementByChar(ch);
                    }
                } else {
                    switch (e.keyCode) {
                        case keyCodes.SPACE:
                            break;

                        case keyCodes.RETURN:
                            const evt = new MouseEvent(click, {
                                bubbles: true,
                                cancelable: true,
                                clientX: 20,
                                view: window,
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

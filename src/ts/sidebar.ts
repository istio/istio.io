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

declare type Callback = (element: HTMLElement) => void;

/* tslint:disable */
interface Window {
    observeResize(el: HTMLElement, callback: Callback): void;
}
/* tslint:enable */

// Attach the event handlers to support the sidebar
function handleSidebar(): void {
    const sidebar = getById("sidebar");
    if (!sidebar) {
        return;
    }

    // toggle subtree in sidebar
    sidebar.querySelectorAll<HTMLElement>(".body").forEach(body => {
        body.querySelectorAll<HTMLElement>(button).forEach(o => {
            listen(o, click, e => {
                const button = e.currentTarget as HTMLElement;
                button.classList.toggle("show");
                const next = button.nextElementSibling;
                if (!next) {
                    return;
                }

                const ul = next.nextElementSibling as HTMLElement;
                if (!ul) {
                    return;
                }

                toggleAttribute(ul, ariaExpanded);

                let el = ul;
                do {
                    el = el.parentElement as HTMLElement;
                } while (!el.classList.contains("body"));

                // adjust the body's max height to the total size of the body's content
                el.style.maxHeight = el.scrollHeight + "px";
            });
        });

        window.observeResize(body, el => {
            if ((el.style.maxHeight !== null) && (el.style.maxHeight !== "")) {
                el.style.maxHeight = el.scrollHeight + "px";
            }
        });
    });

    const headers: HTMLElement[] = [];
    sidebar.querySelectorAll<HTMLElement>(".header").forEach(header => {
        headers.push(header);
    });

    const kbdnav = new KbdNav(headers);

    function toggleHeader(header: HTMLElement): void {
        const body = header.nextElementSibling as HTMLElement;
        if (!body) {
            return;
        }

        body.classList.toggle("show");
        toggleAttribute(header, ariaExpanded);

        if (body.classList.contains("show")) {
            // set this as the limit for expansion
            body.style.maxHeight = body.scrollHeight + "px";
        } else {
            // if was expanded, reset this
            body.style.maxHeight = null;
        }
    }

    // expand/collapse cards
    sidebar.querySelectorAll<HTMLElement>(".header").forEach(header => {
        if (header.classList.contains("dynamic")) {
            listen(header, click, () => {
                toggleHeader(header);
            });

            listen(header, keydown, o => {
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
    sidebar.querySelectorAll<HTMLElement>(".body").forEach(body => {
        if (body.classList.contains("default")) {
            body.classList.toggle("default");
            body.classList.toggle("show");
            body.style.maxHeight = body.scrollHeight + "px";
            const header = body.previousElementSibling as HTMLElement;
            if (header) {
                toggleAttribute(header, ariaExpanded);
            }
        }
    });

    // toggle sidebar on/off
    listen(getById("sidebar-toggler"), click, e => {
        const sc = getById("sidebar-container");
        if (sc) {
            sc.classList.toggle(active);
            const icon = (e.currentTarget as HTMLElement).querySelector<HTMLElement>("svg.icon");
            if (icon) {
                icon.classList.toggle("flipped");
            }
        }
    });
}

handleSidebar();

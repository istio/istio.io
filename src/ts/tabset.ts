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

function selectTabsets(categoryName: string, categoryValue: string): void {
    document.querySelectorAll(".tabset").forEach(tabset => {
        tabset.querySelectorAll(".tab-strip").forEach(o => {
            const strip = o as HTMLElement;
            if (strip.dataset.categoryName === categoryName) {
                strip.querySelectorAll<HTMLElement>("[role=tab]").forEach(tab => {
                    const attr = tab.getAttribute(ariaControls);
                    if (!attr) {
                        return;
                    }

                    const panel = getById(attr);
                    if (!panel) {
                        return;
                    }

                    if (tab.dataset.categoryValue === categoryValue) {
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

function handleTabs(): void {

    document.querySelectorAll(".tabset").forEach(tabset => {
        const strip = tabset.querySelector<HTMLElement>(".tab-strip");
        if (!strip) {
            return;
        }

        const categoryName = strip.dataset.categoryName;
        const forgetTab = strip.dataset.forgetTab !== undefined;
        const panels = tabset.querySelectorAll<HTMLElement>("[role=tabpanel]");

        const tabs: HTMLElement[] = [];
        strip.querySelectorAll<HTMLElement>("[role=tab]").forEach(tab => {
            tabs.push(tab);
        });

        const categoryValues = tabs.map(tab => tab.dataset.categoryValue);

        const kbdnav = new KbdNav(tabs);

        function activateTab(tab: HTMLElement): void {
            deactivateAllTabs();
            tab.removeAttribute(tabIndex);
            tab.setAttribute(ariaSelected, "true");

            const ac = tab.getAttribute(ariaControls);
            if (ac) {
                const other = getById(ac);
                if (other) {
                    other.removeAttribute("hidden");
                }
            }
        }

        function deactivateAllTabs(): void {
            tabs.forEach(tab => {
                tab.setAttribute(tabIndex, "-1");
                tab.setAttribute(ariaSelected, "false");
            });

            panels.forEach(panel => {
                panel.setAttribute("hidden", "");
            });
        }

        if (categoryName) {
            let categoryValue;
            const hashTab = location.hash.replace("#", "");

            if (hashTab) {
                if (categoryValues.indexOf(hashTab) > -1) {
                    categoryValue = hashTab;
                }
            } else if (!forgetTab) {
                categoryValue = readLocalStorage(categoryName);
                if (categoryValue) {
                    selectTabsets(categoryName, categoryValue);
                }
            }

            if (categoryValue) {
                selectTabsets(categoryName, categoryValue);
            }
        }

        // attach the event handlers to support tab sets
        strip.querySelectorAll<HTMLElement>(button).forEach(tab => {

            listen(tab, "focus", () => {
                activateTab(tab);

                if (categoryName) {
                    const categoryValue = tab.dataset.categoryValue;
                    if (categoryValue) {
                        if (!forgetTab) {
                            localStorage.setItem(categoryName, categoryValue);
                        }
                        selectTabsets(categoryName, categoryValue);
                    }
                }
            });

            listen(tab, "click", () => {
                activateTab(tab);

                if (categoryName) {
                    const categoryValue = tab.dataset.categoryValue;
                    if (categoryValue) {
                        if (!forgetTab) {
                            localStorage.setItem(categoryName, categoryValue);
                        }
                        selectTabsets(categoryName, categoryValue);
                    }
                }
            });

            listen(tab, keydown, o => {
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

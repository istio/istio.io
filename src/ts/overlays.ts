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

declare class Popper {
    constructor(a: HTMLElement, b: HTMLElement, c: any);
    public destroy(): void;
}

// tracks any overlay displayed on the page (e.g. menu or popover)
let overlay: HTMLElement | null = null;
let popper: Popper | null = null;

// show/hide the specific overlay
function toggleOverlay(element: HTMLElement): void {
    if (overlay === element) {
        closeActiveOverlay();
    } else {
        if (overlay) {
            closeActiveOverlay();
        }
        element.classList.add("show");
        overlay = element;
    }
}

// explicitly show the specific overlay
function showOverlay(element: HTMLElement): void {
    if (overlay === element) {
        return;
    }
    closeActiveOverlay();
    element.classList.add("show");
    overlay = element;
}

// explicitly close the active overlay
function closeActiveOverlay(): void {
    if (overlay) {
        overlay.classList.remove("show");
        overlay = null;

        if (popper) {
            popper.destroy();
            popper = null;
        }
    }
}

function handleOverlays(): void {
    // Attach a popper to the given anchor
    function attachPopper(anchor: HTMLElement, element: HTMLElement): void {
        if (popper) {
            popper.destroy();
        }

        popper = new Popper(anchor, element, {
            modifiers: {
                flip: {
                    enabled: true,
                },
                preventOverflow: {
                    enabled: true,
                },
                shift: {
                    enabled: true,
                },
            },
            placement: "auto-start",
        });
    }

    // Expand spans that define terms into appropriate popup markup
    document.querySelectorAll<HTMLElement>(".term").forEach(term => {
        const i = document.createElement("i");
        i.innerHTML = "<svg class='icon'><use xlink:href='" + iconFile + "#glossary'/></svg>";

        const span = document.createElement("span");
        span.innerText = " " + term.dataset.title;

        const title = document.createElement("div");
        title.className = "title";
        title.appendChild(i);
        title.appendChild(span);

        const body = document.createElement("div");
        body.className = "body";
        if (term.dataset.body) {
            body.innerHTML = term.dataset.body;
        }

        const arrow = document.createElement("div");
        arrow.className = "arrow";
        arrow.setAttribute("x-arrow", "");

        const div = document.createElement("div");
        div.className = "popover";
        div.appendChild(title);
        div.appendChild(body);
        div.appendChild(arrow);
        div.setAttribute("aria-hidden", "true");
        listen(div, click, e => {
            e.cancelBubble = true;
        });

        const parent = term.parentElement;
        if (parent) {
            parent.insertBefore(div, term.nextElementSibling);
        }
        term.removeAttribute("data-title");
        term.removeAttribute("data-body");
        listen(term, click, e => {
            e.cancelBubble = true;
            toggleOverlay(div);
            attachPopper(term, div);
        });
    });

    // Expand download buttons that need an update notice into appropriate popup markup
    document.querySelectorAll<HTMLAnchorElement>(".update-notice").forEach(downloadButton => {
        const i = document.createElement("i");
        i.innerHTML = "<svg class='icon'><use xlink:href='" + iconFile + "#callout-tip'/></svg>";

        const span = document.createElement("span");
        span.innerText = " " + downloadButton.dataset.title;

        const title = document.createElement("div");
        title.className = "title";
        title.appendChild(i);
        title.appendChild(span);

        const body = document.createElement("div");
        body.className = "body";
        body.innerHTML =
            "<p>" + downloadButton.dataset.updateadvice + "</p>" +
            "<a class='btn wide' href='" + downloadButton.dataset.updatehref + "'>" + downloadButton.dataset.updatebutton + "</a>" +
            "<a class='btn wide' target='_blank' rel='noopener' href='" + downloadButton.dataset.downloadhref + "'>" +
            downloadButton.dataset.downloadbuttontext + "</a>";

        const arrow = document.createElement("div");
        arrow.className = "arrow";
        arrow.setAttribute("x-arrow", "");

        const div = document.createElement("div");
        div.className = "popover";
        div.appendChild(title);
        div.appendChild(body);
        div.appendChild(arrow);
        div.setAttribute("aria-hidden", "true");
        listen(div, click, e => {
            e.cancelBubble = true;
        });

        const parent = downloadButton.parentElement;
        if (parent) {
            parent.insertBefore(div, downloadButton.nextElementSibling);
        }

        downloadButton.removeAttribute("data-title");
        downloadButton.removeAttribute("data-downloadhref");
        downloadButton.removeAttribute("data-updatehref");
        downloadButton.removeAttribute("data-updateadvice");
        downloadButton.removeAttribute("data-updatebutton");

        listen(downloadButton, click, e => {
            e.cancelBubble = true;
            toggleOverlay(div);
            attachPopper(downloadButton, div);
        });
    });

    listen(window, click, closeActiveOverlay);
    listen(window, "resize", closeActiveOverlay);
}

handleOverlays();

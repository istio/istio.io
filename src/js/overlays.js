"use strict";

// tracks any overlay displayed on the page (e.g. menu or popover)
let overlay = null;
let popper = null;

function isActiveOverlay(element) {
    return overlay === element;
}

// show/hide the specific overlay
function toggleOverlay(element) {
    if (overlay === element) {
        closeActiveOverlay();
    } else {
        if (overlay != null) {
            closeActiveOverlay();
        }
        element.classList.add('show');
        overlay = element;
    }
}

// explicitly show the specific overlay
function showOverlay(element) {
    if (overlay === element) {
        return;
    }
    closeActiveOverlay();
    element.classList.add('show');
    overlay = element;
}

// explicitly close the active overlay
function closeActiveOverlay() {
    if (overlay !== null) {
        overlay.classList.remove('show');
        overlay = null;

        if (popper !== null) {
            popper.destroy();
            popper = null;
        }
    }
}

function handleOverlays() {
    // Attach a popper to the given anchor
    function attachPopper(anchor, element) {
        if (popper !== null) {
            popper.destroy();
        }

        popper = new Popper(anchor, element, {
            placement: 'auto-start',
            modifiers: {
                preventOverflow: {
                    enabled: true,
                },
                shift: {
                    enabled: true,
                },
                flip: {
                    enabled: true,
                }
            },
        });
    }

    // Expand spans that define terms into appropriate popup markup
    queryAll(document, '.term').forEach(term => {
        const i = document.createElement('i');
        i.innerHTML = "<svg class='icon'><use xlink:href='" + iconFile + "#glossary'/></svg>";

        const span = document.createElement('span');
        span.innerText = " " + term.dataset.title;

        const title = document.createElement('div');
        title.className = 'title';
        title.appendChild(i);
        title.appendChild(span);

        const body = document.createElement('div');
        body.className = 'body';
        body.innerHTML = term.dataset.body;

        const arrow = document.createElement('div');
        arrow.className = 'arrow';
        arrow.setAttribute('x-arrow', '');

        const div = document.createElement('div');
        div.className = 'popover';
        div.appendChild(title);
        div.appendChild(body);
        div.appendChild(arrow);
        div.setAttribute("aria-hidden", "true");
        listen(div, click, e => {
            e.cancelBubble = true;
        });

        term.parentNode.insertBefore(div, term.nextSibling);
        term.removeAttribute('data-title');
        term.removeAttribute('data-body');
        listen(term, click, e => {
            e.cancelBubble = true;
            toggleOverlay(div);
            attachPopper(term, div);
        });
    });

    listen(window, click, closeActiveOverlay);
    listen(window, "resize", closeActiveOverlay);
}

handleOverlays();

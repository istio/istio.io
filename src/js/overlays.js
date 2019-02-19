"use strict";

// tracks any overlay displayed on the page (e.g. menu or popover)
let overlay = null;
let popper = null;

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
            flip: {
                enabled: true,
                behavior: ['left', 'right', 'top', 'bottom']
            },
        },
    });
}

window.addEventListener("click", closeActiveOverlay);

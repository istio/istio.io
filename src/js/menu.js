"use strict";

// Attach the event handlers to support menus
document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('.menu').forEach(menu => {
        menu.querySelector(".menu-trigger").addEventListener("click", e => {
            e.cancelBubble = true;
            toggleOverlay(menu);
        });
    });
});

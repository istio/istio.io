"use strict";

// Attach the event handlers to support menus
function handleMenu() {
    queryAll(document, '.menu').forEach(menu => {
        listen(query(menu, ".menu-trigger"), click, e => {
            e.cancelBubble = true;
            toggleOverlay(menu);
        });
    });
}

handleMenu();

"use strict";

// Attach the event handlers to support menus
onDOMLoaded(() => {
    queryAll(document, '.menu').forEach(menu => {
        listen(query(menu, ".menu-trigger"), click, e => {
            e.cancelBubble = true;
            toggleOverlay(menu);
        });
    });
});

"use strict";

// Attach the event handlers to support the sidebar
function handleSidebar() {
    const sidebar = getById('sidebar');
    if (sidebar == null) {
        return;
    }

    // toggle subtree in sidebar
    queryAll(sidebar, '.body').forEach(body => {
        queryAll(body, button).forEach(o => {
            listen(o, click, e => {
                let button = e.currentTarget;
                button.classList.toggle("show");
                const ul = button.nextElementSibling.nextElementSibling;
                toggleAttribute(ul, ariaExpanded);

                let el = ul;
                do {
                    el = el.parentElement;
                } while (!el.classList.contains('body'));

                // adjust the body's max height to the total size of the body's content
                el.style.maxHeight = el.scrollHeight + "px";
            });
        });
    });

    // expand/collapse cards
    queryAll(sidebar, '.header').forEach(header => {
        if (header.classList.contains("dynamic")) {
            listen(header, click, () => {
                const body = header.nextElementSibling;

                body.classList.toggle('show');
                toggleAttribute(header, ariaExpanded);

                if (body.classList.contains('show')) {
                    // set this as the limit for expansion
                    body.style.maxHeight = body.scrollHeight + "px";
                } else {
                    // if was expanded, reset this
                    body.style.maxHeight = null;
                }
            });
        }
    });

    // force expand the default cards
    queryAll(sidebar, '.body').forEach(body => {
        if (body.classList.contains("default")) {
            body.style.maxHeight = body.scrollHeight + "px";
            body.classList.toggle("default");
            body.classList.toggle("show");
            const header = body.previousElementSibling;
            toggleAttribute(header, ariaExpanded);
        }
    });

    // toggle sidebar on/off
    const toggler = getById('sidebar-toggler');
    if (toggler) {
        listen(toggler, click, e => {
            getById("sidebar-container").classList.toggle(active);
            query(e.currentTarget, 'svg.icon').classList.toggle('flipped');
        });
    }
}

handleSidebar();

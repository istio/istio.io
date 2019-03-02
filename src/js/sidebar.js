"use strict";

// Attach the event handlers to support the sidebar
function handleSidebar() {
    const sidebar = getById('sidebar');
    if (sidebar == null) {
        return;
    }

    // toggle subtree in sidebar
    queryAll(sidebar, '.tree-toggle').forEach(o => {
        listen(o, click, () => {
            queryAll(o, 'i.chevron').forEach(chevron => {
                chevron.classList.toggle('show');
            });

            o.nextElementSibling.classList.toggle("show");

            let e = o.parentElement;
            while (!e.classList.contains('body')) {
                e = e.parentElement;
            }

            // adjust the body's max height to the total size of the body's content
            e.style.maxHeight = e.scrollHeight + "px";
        });
    });

    // expand/collapse cards
    queryAll(sidebar, '.header').forEach(header => {
        listen(header, click, () => {
            const body = header.nextElementSibling;

            body.classList.toggle('show');
            if (body.classList.contains('show')) {
                // set this as the limit for expansion
                body.style.maxHeight = body.scrollHeight + "px";
            } else {
                // if was expanded, reset this
                body.style.maxHeight = null;
            }
        });
    });

    // force expand the default cards
    queryAll(sidebar, '.body').forEach(body => {
        if (body.classList.contains("default")) {
            body.style.maxHeight = body.scrollHeight + "px";
            body.classList.toggle("default");
            body.classList.toggle("show");
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

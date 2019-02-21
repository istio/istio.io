"use strict";

// Attach the event handlers to support the sidebar
document.addEventListener('DOMContentLoaded', () => {
    const sidebar = document.getElementById('sidebar');

    // toggle subtree in sidebar
    sidebar.querySelectorAll('.tree-toggle').forEach(o => {
        o.addEventListener("click", () => {
            o.querySelectorAll('i.chevron').forEach(chevron => {
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
    sidebar.querySelectorAll('.header').forEach(header => {
        header.addEventListener("click", () => {
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
    sidebar.querySelectorAll('.body').forEach(body => {
        if (body.classList.contains("default")) {
            body.style.maxHeight = body.scrollHeight + "px";
            body.classList.toggle("default");
            body.classList.toggle("show");
        }
    });

    // toggle sidebar on/off
    const toggler = document.getElementById('sidebar-toggler');
    if (toggler) {
        toggler.addEventListener("click", e => {
            document.getElementById("sidebar-container").classList.toggle('active');
            e.currentTarget.querySelector('svg.icon').classList.toggle('flipped');
        });
    }
});

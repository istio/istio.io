"use strict";

// Attach the event handlers to support the sidebar
document.addEventListener('DOMContentLoaded', () => {
    // toggle subtree in sidebar
    document.querySelectorAll('.tree-toggle').forEach(o => {
        o.addEventListener("click", () => {
            o.querySelectorAll('i.chevron').forEach(chevron => {
                chevron.classList.toggle('show');
            });

            o.nextElementSibling.classList.toggle("show");
        });
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

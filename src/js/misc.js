"use strict";

document.addEventListener('DOMContentLoaded', () => {

    // Expand spans that define terms into appropriate popup markup
    function expandPopovers() {
        document.querySelectorAll('.term').forEach(term => {
            const title = document.createElement('div');
            title.className = 'title';
            title.innerText = term.dataset.title;

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
            div.addEventListener('click', e => {
                e.cancelBubble = true;
            });

            term.parentNode.insertBefore(div, term.nextSibling);
            term.removeAttribute('data-title');
            term.removeAttribute('data-body');
            term.addEventListener('click', e => {
                e.cancelBubble = true;
                toggleOverlay(div);
                attachPopper(term, div);
            });
        });
    }

    // Select the right tabs in all tabsets, based on any saved cookies
    function selectTabs() {
        document.querySelectorAll('a[data-toggle="tab"]').forEach(tab => {
            const cookieName = tab.dataset.cookieName;
            const cookieValue = tab.dataset.cookieValue;

            if (cookieName === null || cookieName === "") {
                return;
            }

            const v = readCookie(cookieName);
            if (cookieValue === v) {
                // there's gotta be a way to call the tab() function directly since I already have the
                // requisite object in hand. Alas, I can't figure it out. So query the document to find
                // the same object again, and call the tab function on the result.
                $('.nav-tabs a[href="' + tab.hash + '"]').tab('show');
            }
        });
    }

    // Attach the event handlers to support the search box
    function attachSearchHandlers() {
        // Show the navbar links, hide the search box
        function showNavBarLinks() {
            document.getElementById('search-form').classList.remove('active');
            document.getElementById('navbar-links').classList.add('active');
            document.getElementById('search-textbox').value = '';
        }

        // Show the navbar search box, hide the links
        function showSearchBox() {
            document.getElementById('search-form').classList.add('active');
            document.getElementById('navbar-links').classList.remove('active');
            document.getElementById('search-textbox').focus();
        }

        // Hide the search box when the user hits the ESC key
        document.body.addEventListener("keyup", e => {
            if (e.which === 27) {
                showNavBarLinks();
            }
        });

        // Show the search box
        document.getElementById('search-show').addEventListener("click", e => {
            e.preventDefault();
            showSearchBox();
        });

        // Hide the search box
        document.getElementById('search-close').addEventListener("click", e => {
            e.preventDefault();
            showNavBarLinks();
        });

        // When the user submits the search form, initiate a search
        document.getElementById('search-form').addEventListener("submit", e => {
            e.preventDefault();
            const textbox = document.getElementById('search-textbox');
            const searchPageUrl = document.getElementById('search-page-url');
            const url = searchPageUrl.value + '?q=' + textbox.value;
            showNavBarLinks();
            window.location.assign(url);
        });
    }

    // Attach the event handlers to support the sidebar
    function attachSidebarHandlers() {
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
    }

    let recurse = false;

    // Attach the event handlers to support tab sets
    function attachTabHandlers() {
        // Save a cookie when a user selects a tab in a tabset
        $('a[data-toggle="tab"]').on('shown.bs.tab', e => {
            if (recurse) {
                // prevent endless recursion...
                return;
            }

            const tab = e.target;
            const cookieName = tab.dataset.cookieName;
            const cookieValue = tab.dataset.cookieValue;
            if (cookieName === null || cookieName === "") {
                return;
            }

            createCookie(cookieName, cookieValue);

            document.querySelectorAll('a[data-toggle="tab"]').forEach(tab => {
                if (cookieName === tab.dataset.cookieName) {
                    if (cookieValue === tab.dataset.cookieValue) {
                        // there's gotta be a way to call the tab() function directly since I already have the
                        // DOM object in hand. Alas, I can't figure it out. So query and call the tab function on the result.
                        recurse = true;
                        $('.nav-tabs a[href="' + tab.hash + '"]').tab('show');
                        recurse = false;
                    }
                }
            });
        });
    }

    // Attach the event handlers to support menus
    function attachMenuHandlers() {
        document.querySelectorAll('.menu').forEach(menu => {
            menu.querySelector(".menu-trigger").addEventListener("click", e => {
                e.cancelBubble = true;
                toggleOverlay(menu);
            });
        });
    }

    expandPopovers();
    selectTabs();
    attachSearchHandlers();
    attachSidebarHandlers();
    attachTabHandlers();
    attachMenuHandlers();
});

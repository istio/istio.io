"use strict";

// Attach the event handlers to support the search box and hamburger
document.addEventListener('DOMContentLoaded', () => {
    // Show the header links, hide the search box
    function showNavBarLinks() {
        document.getElementById('search-form').classList.remove('show-search');
        document.getElementById('header-links').classList.remove('show-search');
        document.getElementById('search-textbox').value = '';
    }

    // Show the header search box, hide the links
    function showSearchBox() {
        document.getElementById('search-form').classList.add('show-search');
        document.getElementById('header-links').classList.add('show-search');
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

    document.getElementById('hamburger').addEventListener("click", () => {
        document.getElementById('brand').classList.toggle('open-hamburger');
        document.getElementById('header-links').classList.toggle('open-hamburger');
        document.getElementById('search-form').classList.toggle('open-hamburger');
        document.getElementById('search-textbox').focus();
    });

    window.addEventListener("resize", () => {
        document.getElementById('brand').classList.remove('open-hamburger');
        document.getElementById('header-links').classList.remove('open-hamburger');
        document.getElementById('search-form').classList.remove('open-hamburger');
    });
});

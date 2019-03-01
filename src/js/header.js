"use strict";

// Attach the event handlers to support the search box and hamburger
function handleHeader() {
    const searchForm = 'search-form';
    const headerLinks = 'header-links';
    const searchTextbox = 'search-textbox';
    const showSearch = 'show-search';
    const openHamburger = 'open-hamburger';

    // Show the header links, hide the search box
    function showNavBarLinks() {
        getById(searchForm).classList.remove(showSearch);
        getById(headerLinks).classList.remove(showSearch);
        getById(searchTextbox).value = '';
    }

    // Show the header search box, hide the links
    function showSearchBox() {
        getById(searchForm).classList.add(showSearch);
        getById(headerLinks).classList.add(showSearch);
        getById(searchTextbox).focus();
    }

    // Hide the search box when the user hits the ESC key
    listen(document.body, "keyup", e => {
        if (e.which === 27) {
            showNavBarLinks();
        }
    });

    // Show the search box
    listen(getById('search-show'), click, e => {
        e.preventDefault();
        showSearchBox();
    });

    // Hide the search box
    listen(getById('search-close'), click, e => {
        e.preventDefault();
        showNavBarLinks();
    });

    // When the user submits the search form, initiate a search
    listen(getById(searchForm), "submit", e => {
        e.preventDefault();
        const textbox = getById(searchTextbox);
        const searchPageUrl = getById('search-page-url');
        const url = searchPageUrl.value + '?q=' + textbox.value;
        showNavBarLinks();
        window.location.assign(url);
    });

    listen(getById('hamburger'), click, () => {
        getById('brand').classList.toggle(openHamburger);
        getById(headerLinks).classList.toggle(openHamburger);
        getById(searchForm).classList.toggle(openHamburger);
        getById(searchTextbox).focus();
    });

    listen(window, "resize", () => {
        getById('brand').classList.remove(openHamburger);
        getById(headerLinks).classList.remove(openHamburger);
        getById(searchForm).classList.remove(openHamburger);
    });
}

handleHeader();

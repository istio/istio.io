"use strict";

function handleLanguageSwitch() {
    const switchLangButton = getById("switch-lang");
    if (switchLangButton) {
        listen(switchLangButton, click, () => {
            const url = new URL(window.location.href);
            let path = url.pathname;
            if (path.startsWith("/zh")) {
                path = path.substr(3);
                createCookie("nf_lang", "en");
            } else {
                path = '/zh' + path;
                createCookie("nf_lang", "zh");
            }
            url.pathname = path;

            navigateToUrlOrRoot(url.toString());
            return true;
        });
    }

    listen(getById("switch-lang-en"), click, () => {
        const url = new URL(window.location.href);
        let path = url.pathname;
        if (path.startsWith("/zh")) {
            path = path.substr(3);
        }
        url.pathname = path;

        createCookie("nf_lang", "en");
        navigateToUrlOrRoot(url.toString());
    });

    listen(getById("switch-lang-zh"), click, () => {
        const url = new URL(window.location.href);
        let path = url.pathname;
        if (!path.startsWith("/zh")) {
            path = '/zh' + path;
        }
        url.pathname = path;

        createCookie("nf_lang", "zh");
        navigateToUrlOrRoot(url.toString());
    });
}

handleLanguageSwitch();
// Copyright 2019 Istio Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// The set of languages supported by the site, add new ones at the end
const languages = ["en", "zh", "pt-br"];

function handleLanguageSwitch(): void {

    function setLang(newLang: string): void {
        const url = new URL(window.location.href);

        const strippedPath = url.pathname;

        let versionString = "";
        let path = "";
        const re = /\/v\d+\.\d+\//;
        if (strippedPath.startsWith("/latest") || re.test(strippedPath)) {
            // get second slash
            const pos = strippedPath.indexOf("/", 1);
            versionString = strippedPath.substr(0, pos + 1); // include the trailing slash
            path = strippedPath.substr(pos);
        }

        for (const lang of languages) {
            if (path.startsWith("/" + lang)) {
                path = path.substr(3);
                break;
            }
        }

        if (newLang === "") {
            newLang = languages[0];
        }

        createCookie("nf_lang", newLang);

        // if english, remove the /en
        if (newLang === "en") {
            newLang = "";
            // remove the trailing slash
            versionString = versionString.substr(0, versionString.length);
        }
        url.pathname = versionString + newLang + path;

        navigateToUrlOrRoot(url.toString());
    }

    // handler for the language selector floating button
    listen(getById("switch-lang"), click, () => {
        setLang("");
        return true;
    });

    // handlers for the language-selection menu items */
    for (const lang of languages) {
        listen(getById("switch-lang-" + lang), click, () => {
            setLang(lang);
        });
    }
}

handleLanguageSwitch();

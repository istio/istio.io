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
const languages = ["en", "zh"];

function handleLanguageSwitch(): void {

    function setLang(newLang: string): void {
        const url = new URL(window.location.href);

        let strippedPath = url.pathname;
        let currentLang = 0;
        for (const lang of languages) {
            if (strippedPath.startsWith("/" + lang)) {
                strippedPath = strippedPath.substr(3);
                break;
            }
            currentLang++;
        }

        if (currentLang >= languages.length) {
            currentLang = 0;
        }

        if (newLang === "") {
            // round-robin through the languages
            let nextLang = currentLang + 1;
            if (nextLang >= languages.length) {
                nextLang = 0;
            }
            newLang = languages[nextLang];
        }

        createCookie("nf_lang", newLang);
        url.pathname = newLang + "/" + strippedPath;

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

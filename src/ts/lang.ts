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

function handleLanguageSwitch(): void {
    listen(getById("switch-lang"), click, () => {
        const url = new URL(window.location.href);
        let path = url.pathname;
        if (path.startsWith("/zh")) {
            path = path.substr(3);
            createCookie("nf_lang", "en");
        } else {
            path = "/zh" + path;
            createCookie("nf_lang", "zh");
        }
        url.pathname = path;

        navigateToUrlOrRoot(url.toString());
        return true;
    });

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
            path = "/zh" + path;
        }
        url.pathname = path;

        createCookie("nf_lang", "zh");
        navigateToUrlOrRoot(url.toString());
    });
}

handleLanguageSwitch();

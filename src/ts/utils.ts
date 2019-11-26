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

const keyCodes = Object.freeze({
    DOWN: 40,
    END: 35,
    ESC: 27,
    HOME: 36,
    LEFT: 37,
    PAGEDOWN: 34,
    PAGEUP: 33,
    RETURN: 13,
    RIGHT: 39,
    SPACE: 32,
    TAB: 9,
    UP: 38,
});

// copy the given text to the system clipboard
function copyToClipboard(str: string): void {
    const sel = document.getSelection();
    if (!sel) {
        return;
    }

    const el = document.createElement("textarea");   // Create a <textarea> element
    el.value = str;                                  // Set its value to the string that you want copied
    el.setAttribute("readonly", "");                 // Make it readonly to be tamper-proof
    el.style.position = "absolute";
    el.style.left = "-9999px";                       // Move outside the screen to make it invisible
    document.body.appendChild(el);                   // Append the <textarea> element to the HTML document

    if (sel.rangeCount > 0) {
        const oldSelection = sel.getRangeAt(0);

        el.select();                                     // Select the <textarea> content
        document.execCommand("copy");                    // Copy - only works as a result of a user action (e.g. click events)
        document.body.removeChild(el);                   // Remove the <textarea> element

        // restore the previous selection
        sel.removeAllRanges();
        sel.addRange(oldSelection);
    } else {
        el.select();                                     // Select the <textarea> content
        document.execCommand("copy");                    // Copy - only works as a result of a user action (e.g. click events)
        document.body.removeChild(el);                   // Remove the <textarea> element
    }
}

// Saves a string to a particular client-side file
function saveFile(filename: string, text: string): void {
    const element = document.createElement("a");
    element.setAttribute("href", "data:text/plain;charset=utf-8," + encodeURIComponent(text));
    element.setAttribute("download", filename);

    element.style.display = "none";
    document.body.appendChild(element);
    element.click();
    document.body.removeChild(element);
}

// Sends a string to the printer
function printText(text: string): void {
    const html = "<html><body><pre><code>" + text + "</code></pre></html>";

    const printWin = window.open("", "", "left=0,top=0,width=100,height=100,toolbar=0,scrollbars=0,status=0,location=0,menubar=0", false);
    if (printWin) {
        printWin.document.write(html);
        printWin.document.close();
        printWin.focus();
        printWin.print();
        printWin.close();
    }
}

// Navigate to the given URL if possible. If the page doesn't exist then navigate to the
// root of the target site instead.
function navigateToUrlOrRoot(url: string): void {
    const request = new XMLHttpRequest();
    request.open("GET", url, true);
    request.onreadystatechange = () => {
        if (request.readyState === 4 && request.status === 404) {
            const u = new URL(url);
            u.pathname = "";
            url = u.toString();
        }

        // go!
        window.location.href = url;
    };

    request.send();
}

function createCookie(name: string, value: string): void {
    document.cookie = name + "=" + value + "; path=/";
}

function getById(id: string): HTMLElement | null {
    return document.getElementById(id);
}

function listen(o: HTMLElement | Window | null, e: string, f: EventListenerOrEventListenerObject): void {
    if (o) {
        o.addEventListener(e, f);
    }
}

function toggleAttribute(el: HTMLElement, name: string): void {
    if (el.getAttribute(name) === "true") {
        el.setAttribute(name, "false");
    } else {
        el.setAttribute(name, "true");
    }
}

function isPrintableCharacter(str: string): boolean {
    return str.length === 1 && (str.match(/\S/) != null);
}

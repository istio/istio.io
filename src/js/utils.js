"use strict";

// Scroll the document to the top
function scrollToTop() {
    document.body.scrollTop = 0;            // for Safari
    document.documentElement.scrollTop = 0; // for Chrome, Firefox, IE and Opera
}

const escapeChars = {
    '¢': 'cent',
    '£': 'pound',
    '¥': 'yen',
    '€': 'euro',
    '©': 'copy',
    '®': 'reg',
    '<': 'lt',
    '>': 'gt',
    '"': 'quot',
    '&': 'amp',
    '\'': '#39'
};

const regex = new RegExp("[¢£¥€©®<>\"&']", 'g');

// Escapes special characters into HTML entities
function escapeHTML(str) {
    return str.replace(regex, function(m) {
        return '&' + escapeChars[m] + ';';
    });
}

// Saves a string to a particular client-side file
function saveFile(filename, text) {
    const element = document.createElement('a');
    element.setAttribute('href', 'data:text/text;charset=utf-8,' + encodeURI(text));
    element.setAttribute('download', filename);
    element.click();
}

// Sends a string to the printer
function printText(text) {
    const html = "<html><body><pre><code>" + text + "</code></pre></html>";

    const printWin = window.open('', '', 'left=0,top=0,width=100,height=100,toolbar=0,scrollbars=0,status=0,location=0,menubar=0', false);
    printWin.document.write(html);
    printWin.document.close();
    printWin.focus();
    printWin.print();
    printWin.close();
}

// Navigate to the given URL if possible. If the page doesn't exist then navigate to the
// root of the target site instead.
function navigateToUrlOrRoot(url) {
    const request = new XMLHttpRequest();
    request.open('GET', url, true);
    request.onreadystatechange = () => {
        if (request.readyState === 4 && request.status === 404) {
            const u = new URL(url);
            u.pathname = '';
            url = u.toString();
        } else {
            console.log("OK");
        }

        // go!
        window.location.href = url;
    };

    request.send();
}

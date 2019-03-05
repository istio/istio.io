"use strict";

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

// copy the given text to the system clipboard
function copyToClipboard(str) {
    const el = document.createElement('textarea');   // Create a <textarea> element
    el.value = str;                                  // Set its value to the string that you want copied
    el.setAttribute('readonly', '');                 // Make it readonly to be tamper-proof
    el.style.position = 'absolute';
    el.style.left = '-9999px';                       // Move outside the screen to make it invisible
    document.body.appendChild(el);                   // Append the <textarea> element to the HTML document
    const selected =
        document.getSelection().rangeCount > 0       // Check if there is any content selected previously
            ? document.getSelection().getRangeAt(0)  // Store selection if found
            : false;                                 // Mark as false to know no selection existed before
    el.select();                                     // Select the <textarea> content
    document.execCommand('copy');                    // Copy - only works as a result of a user action (e.g. click events)
    document.body.removeChild(el);                   // Remove the <textarea> element
    if (selected) {                                  // If a selection existed before copying
        document.getSelection().removeAllRanges();    // Unselect everything on the HTML document
        document.getSelection().addRange(selected);   // Restore the original selection
    }
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
        }

        // go!
        window.location.href = url;
    };

    request.send();
}

function createCookie(name, value, days) {
    let expires = "";
    if (days) {
        const date = new Date();
        date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
        expires = "; expires=" + date.toGMTString();
    }
    document.cookie = name + "=" + value + expires + "; path=/";
}

function getById(id) {
    return document.getElementById(id);
}

function query(o, s) {
    return o.querySelector(s);
}

function queryAll(o, s) {
    return o.querySelectorAll(s);
}

function listen(o, e, f) {
    o.addEventListener(e, f);
}

"use strict";

let syntaxColoring = true;

// All the voodoo needed to support our fancy code blocks
function handleCodeBlocks() {
    const toolbarShow = 'toolbar-show';
    const syntaxColoringCookie = 'syntax-coloring';
    const syntaxColoringItem = 'syntax-coloring-item';

    // Add a toolbar to all PRE blocks
    function attachToolbar(pre) {
        const copyButton = document.createElement(button);
        copyButton.title = buttonCopy;
        copyButton.className = "copy";
        copyButton.innerHTML = "<svg><use xlink:href='" + iconFile + "#copy'/></svg>";
        copyButton.setAttribute(ariaLabel, buttonCopy);
        listen(copyButton, mouseenter, e => e.currentTarget.classList.add(toolbarShow));
        listen(copyButton, mouseleave, e => e.currentTarget.classList.remove(toolbarShow));
        listen(copyButton, click, e => {
            const div = e.currentTarget.parentElement;
            const text = getToolbarDivText(div);
            copyToClipboard(text);
            return true;
        });

        const downloadButton = document.createElement(button);
        downloadButton.title = buttonDownload;
        downloadButton.className = "download";
        downloadButton.innerHTML = "<svg><use xlink:href='" + iconFile + "#download'/></svg>";
        downloadButton.setAttribute(ariaLabel, buttonDownload);
        listen(downloadButton, mouseenter, e => e.currentTarget.classList.add(toolbarShow));
        listen(downloadButton, mouseleave, e => e.currentTarget.classList.remove(toolbarShow));

        listen(downloadButton, click, e => {
            const div = e.currentTarget.parentElement;
            const codes = div.getElementsByTagName("code");
            if ((codes !== null) && (codes.length > 0)) {
                const code = codes[0];
                const text = getToolbarDivText(div);
                let downloadas = code.dataset.downloadas;
                if (downloadas === undefined || downloadas === null || downloadas === "") {
                    let lang = "";
                    for (let j = 0; j < code.classList.length; j++) {
                        if (code.classList.item(j).startsWith("language-")) {
                            lang = code.classList.item(j).substr(9);
                            break;
                        } else if (code.classList.item(j).startsWith("command-")) {
                            lang = "bash";
                            break;
                        }
                    }

                    if (lang === "markdown") {
                        lang = "md";
                    } else if (lang === "") {
                        lang = "txt";
                    }

                    downloadas = docTitle + "." + lang;
                }
                saveFile(downloadas, text);
            }
            return true;
        });

        const printButton = document.createElement(button);
        printButton.title = buttonPrint;
        printButton.className = "print";
        printButton.innerHTML = "<svg><use xlink:href='" + iconFile + "#printer'/></svg>";
        printButton.setAttribute(ariaLabel, buttonPrint);
        listen(printButton, mouseenter, e => e.currentTarget.classList.add(toolbarShow));
        listen(printButton, mouseleave, e => e.currentTarget.classList.remove(toolbarShow));

        listen(printButton, click, e => {
            const div = e.currentTarget.parentElement;
            const text = getToolbarDivText(div);
            printText(text);
            return true;
        });

        // wrap the PRE block in a DIV so we have a place to attach the toolbar buttons
        const div = document.createElement("div");
        div.className = "toolbar";
        pre.parentElement.insertBefore(div, pre);
        div.appendChild(pre);
        div.appendChild(printButton);
        div.appendChild(downloadButton);
        div.appendChild(copyButton);

        listen(pre, mouseenter, e => {
            e.currentTarget.nextSibling.classList.add(toolbarShow);
            e.currentTarget.nextSibling.nextSibling.classList.add(toolbarShow);
            e.currentTarget.nextSibling.nextSibling.nextSibling.classList.add(toolbarShow);
        });

        listen(pre, mouseleave, e => {
            e.currentTarget.nextSibling.classList.remove(toolbarShow);
            e.currentTarget.nextSibling.nextSibling.classList.remove(toolbarShow);
            e.currentTarget.nextSibling.nextSibling.nextSibling.classList.remove(toolbarShow);
        });
    }

    function getToolbarDivText(div) {
        const commands = div.getElementsByClassName("command");
        if ((commands !== null) && (commands.length > 0)) {
            const lines = commands[0].innerText.split("\n");
            let cmd = "";
            for (let i = 0; i < lines.length; i++) {
                if (lines[i].startsWith("$ ")) {
                    lines[i] = lines[i].substring(2);
                }

                if (cmd !== "") {
                    cmd = cmd + "\n";
                }

                cmd += lines[i];
            }

            return cmd;
        }

        return div.innerText;
    }

    function applySyntaxColoring(pre) {
        const code = pre.firstChild;

        let cl = "";
        for (let j = 0; j < code.classList.length; j++) {
            if (code.classList.item(j).startsWith("language-bash")) {
                cl = code.classList.item(j);
                break;
            }
        }

        if (cl !== "") {
            let firstLineOfOutput = 0;
            let lines = code.innerText.split("\n");
            let cmd = "";
            let escape = false;
            let escapeUntilEOF = false;
            let tmp = "";
            for (let j = 0; j < lines.length; j++) {
                const line = lines[j];

                if (line.startsWith("$ ")) {
                    if (tmp !== "") {
                        if (syntaxColoring) {
                            cmd += "$ " + Prism.highlight(tmp, Prism.languages["bash"], "bash") + "\n";
                        } else {
                            cmd += "$ " + Prism.highlight(tmp, Prism.languages["plain"], "plain") + "\n";
                        }
                    }

                    tmp = line.slice(2);

                    if (line.includes("<<EOF")) {
                        escapeUntilEOF = true;
                    }
                } else if (escape) {
                    // continuation
                    tmp += "\n" + line;

                    if (line.includes("<<EOF")) {
                        escapeUntilEOF = true;
                    }
                } else if (escapeUntilEOF) {
                    tmp += "\n" + line;
                    if (line === "EOF") {
                        escapeUntilEOF = false;
                    }
                } else {
                    firstLineOfOutput = j;
                    break;
                }

                escape = line.endsWith("\\");
            }

            if (tmp !== "") {
                if (syntaxColoring) {
                    cmd += "$ " + Prism.highlight(tmp, Prism.languages["bash"], "bash") + "\n";
                } else {
                    cmd += "$ " + Prism.highlight(tmp, Prism.languages["plain"], "plain") + "\n";
                }
            }

            if (cmd !== "") {
                if (code.dataset.expandlinks === "true") {
                    cmd = cmd.replace(/@(.*?)@/g, "<a href='https://raw.githubusercontent.com/istio/istio/" + branchName + "/$1'>$1</a>");
                }

                let html = "<div class='command'>" + cmd + "</div>";

                let output = "";
                if (firstLineOfOutput > 0) {
                    for (let j = firstLineOfOutput; j < lines.length; j++) {
                        if (output !== "") {
                            output += "\n";
                        }
                        output += lines[j];
                    }
                }

                if (output !== "") {
                    // apply formatting to the output?
                    if (code.dataset.outputis) {
                        if (syntaxColoring) {
                            output = Prism.highlight(output, Prism.languages[code.dataset.outputis], code.dataset.outputis);
                        }
                    }

                    html += "<div class='output'>" + output + "</div>";
                }

                code.innerHTML = html;
                code.classList.remove(cl);
                code.classList.add("command-output");
            } else {
                if (syntaxColoring) {
                    // someone probably forgot to start a block with $, so let's just treat the whole thing as being a `bash` block
                    Prism.highlightElement(code, false);
                }
            }
        } else {
            if (syntaxColoring) {
                // this isn't one of our special code blocks, so handle normally
                Prism.highlightElement(code, false);
            }
        }
    }

    // Load the content of any externally-hosted PRE block
    function loadExternal(pre) {
        const code = pre.firstChild;

        function fetchFile(elem, url) {
            fetch(url)
                .then(response => {
                    if (response.status !== 200) {
                        return "Unable to access " + url + ": " + response.statusText;
                    }

                    return response.text()
                })
                .catch(e => {
                    return "Unable to access " + url + ": " + e;
                })
                .then(data => {
                    if (code.dataset.snippet) {
                        const pattern = "\\n.*?\\$snippet " + code.dataset.snippet + "\\n(.+?)\\n.*?\\$endsnippet";
                        const regex = new RegExp(pattern, 'gms');

                        let buf = "";
                        let match = regex.exec(data);
                        while (match != null) {
                            buf = buf + match[1];
                            match = regex.exec(data);
                        }
                        data = buf;
                    }

                    code.textContent = data;
                    if (syntaxColoring) {
                        Prism.highlightElement(code, false);
                    }
                });
        }

        if (code.dataset.src) {
            fetchFile(code, code.dataset.src);
        }
    }

    function handleSyntaxColoring() {
        const cookieValue = readCookie(syntaxColoringCookie);
        if (cookieValue === 'true') {
            syntaxColoring = true;
        } else if (cookieValue === 'false') {
            syntaxColoring = false;
        }

        let item = document.getElementById(syntaxColoringItem);
        if (item) {
            if (syntaxColoring) {
                item.classList.add(active);
            } else {
                item.classList.remove(active);
            }
        }

        listen(getById(syntaxColoringItem), click, () => {
            createCookie(syntaxColoringCookie, !syntaxColoring);
            location.reload();
        });
    }

    handleSyntaxColoring();

    queryAll(document, 'pre').forEach(pre => {
        attachToolbar(pre);
        applySyntaxColoring(pre);
        loadExternal(pre);
    });
}

handleCodeBlocks();

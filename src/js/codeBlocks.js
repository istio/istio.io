"use strict";

// All the voodoo needed to support our fancy code blocks
function handleCodeBlocks() {
    // Add a toolbar to all PRE blocks
    function attachToolbar(pre) {
        const copyButton = document.createElement('button');
        copyButton.title = buttonCopy;
        copyButton.className = "copy";
        copyButton.innerHTML = "<svg><use xlink:href='" + iconFile + "#copy'/></svg>";
        copyButton.setAttribute("aria-label", buttonCopy);
        listen(copyButton, mouseenter, e => e.currentTarget.classList.add("toolbar-show"));
        listen(copyButton, mouseleave, e => e.currentTarget.classList.remove("toolbar-show"));
        listen(copyButton, click, e => {
            const div = e.currentTarget.parentElement;
            const text = getToolbarDivText(div);
            copyToClipboard(text);
            return true;
        });

        const downloadButton = document.createElement('button');
        downloadButton.title = buttonDownload;
        downloadButton.className = "download";
        downloadButton.innerHTML = "<svg><use xlink:href='" + iconFile + "#download'/></svg>";
        downloadButton.setAttribute("aria-label", buttonDownload);
        listen(downloadButton, mouseenter, e => e.currentTarget.classList.add("toolbar-show"));
        listen(downloadButton, mouseleave, e => e.currentTarget.classList.remove("toolbar-show"));

        listen(downloadButton, click, e => {
            const div = e.currentTarget.parentElement;
            const codes = div.getElementsByTagName("CODE");
            if ((codes !== null) && (codes.length > 0)) {
                const code = codes[0];
                const text = getToolbarDivText(div);
                let downloadas = code.dataset.downloadas;
                if (downloadas === null || downloadas === "") {
                    let lang = "";
                    for (let j = 0; j < code.classList.length; j++) {
                        if (code.classList.item(j).startsWith("language-")) {
                            lang = code.classList.item(j).substr(9);
                            break;
                        }
                    }

                    if (lang.startsWith("command")) {
                        lang = "bash";
                    } else if (lang === "markdown") {
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

        const printButton = document.createElement('button');
        printButton.title = buttonPrint;
        printButton.className = "print";
        printButton.innerHTML = "<svg><use xlink:href='" + iconFile + "#printer'/></svg>";
        printButton.setAttribute("aria-label", buttonPrint);
        listen(printButton, mouseenter, e => e.currentTarget.classList.add("toolbar-show"));
        listen(printButton, mouseleave, e => e.currentTarget.classList.remove("toolbar-show"));

        listen(printButton, click, e => {
            const div = e.currentTarget.parentElement;
            const text = getToolbarDivText(div);
            printText(text);
            return true;
        });

        // wrap the PRE block in a DIV so we have a place to attach the toolbar buttons
        const div = document.createElement("DIV");
        div.className = "toolbar";
        pre.parentElement.insertBefore(div, pre);
        div.appendChild(pre);
        div.appendChild(printButton);
        div.appendChild(downloadButton);
        div.appendChild(copyButton);

        listen(pre, mouseenter, e => {
            e.currentTarget.nextSibling.classList.add("toolbar-show");
            e.currentTarget.nextSibling.nextSibling.classList.add("toolbar-show");
            e.currentTarget.nextSibling.nextSibling.nextSibling.classList.add("toolbar-show");
        });

        listen(pre, mouseleave, e => {
            e.currentTarget.nextSibling.classList.remove("toolbar-show");
            e.currentTarget.nextSibling.nextSibling.classList.remove("toolbar-show");
            e.currentTarget.nextSibling.nextSibling.nextSibling.classList.remove("toolbar-show");
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
            if (code.classList.item(j).startsWith("language-command")) {
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
                        cmd += "$ " + Prism.highlight(tmp, Prism.languages["bash"], "bash") + "\n";
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
                cmd += "$ " + Prism.highlight(tmp, Prism.languages["bash"], "bash") + "\n";
            }

            if (cmd !== "") {
                cmd = cmd.replace(/@(.*?)@/g, "<a href='https://raw.githubusercontent.com/istio/istio/" + branchName + "/$1'>$1</a>");

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
                    let prefix = "language-command-output-as-";
                    if (cl.startsWith(prefix)) {
                        let lang = cl.substr(prefix.length);
                        output = Prism.highlight(output, Prism.languages[lang], lang);
                    } else {
                        output = escapeHTML(output);
                    }

                    html += "<div class='output'>" + output + "</div>";
                }

                code.innerHTML = html;
                code.classList.remove(cl);
                code.classList.add("command-output");
            } else {
                // someone probably forgot to start a block with $, so let's just treat the whole thing as being a `bash` block
                Prism.highlightElement(code, false);
            }
        } else {
            // this isn't one of our special code blocks, so handle normally
            Prism.highlightElement(code, false);
        }
    }

    // Load the content of any externally-hosted PRE block
    function loadExternal(pre) {

        function fetchFile(elem, url) {
            fetch(url)
                .then(response => response.text())
                .then(data => {
                    elem.firstChild.textContent = data;
                    Prism.highlightElement(elem.firstChild, false);
                });
        }

        if (pre.hasAttribute("data-src")) {
            fetchFile(pre, pre.dataset.src);
        }
    }

    queryAll(document, 'pre').forEach(pre => {
        attachToolbar(pre);
        applySyntaxColoring(pre);
        loadExternal(pre);
    });
}

handleCodeBlocks();

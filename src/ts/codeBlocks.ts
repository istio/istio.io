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

declare const buttonCopy: string;
declare const buttonDownload: string;
declare const buttonPrint: string;
declare const docTitle: string;
declare const branchName: string;
declare const Prism: any;

let syntaxColoring = true;

// All the voodoo needed to support our fancy code blocks
function handleCodeBlocks() {
    const toolbarShow = "toolbar-show";
    const syntaxColoringCookie = "syntax-coloring";
    const syntaxColoringItem = "syntax-coloring-item";

    // Add a toolbar to all PRE blocks
    function attachToolbar(pre: HTMLElement): void {
        const copyButton = document.createElement(button);
        copyButton.title = buttonCopy;
        copyButton.className = "copy";
        copyButton.innerHTML = "<svg><use xlink:href='" + iconFile + "#copy'/></svg>";
        copyButton.setAttribute(ariaLabel, buttonCopy);
        listen(copyButton, mouseenter, e => (e.currentTarget as HTMLElement).classList.add(toolbarShow));
        listen(copyButton, mouseleave, e => (e.currentTarget as HTMLElement).classList.remove(toolbarShow));
        listen(copyButton, "focus", e => (e.currentTarget as HTMLElement).classList.add(toolbarShow));
        listen(copyButton, "blur", e => (e.currentTarget as HTMLElement).classList.remove(toolbarShow));
        listen(copyButton, click, e => {
            const div = (e.currentTarget as HTMLElement).parentElement;
            if (div) {
                const text = getToolbarDivText(div);
                copyToClipboard(text);
            }
            return true;
        });

        const downloadButton = document.createElement(button);
        downloadButton.title = buttonDownload;
        downloadButton.className = "download";
        downloadButton.innerHTML = "<svg><use xlink:href='" + iconFile + "#download'/></svg>";
        downloadButton.setAttribute(ariaLabel, buttonDownload);
        listen(downloadButton, mouseenter, e => (e.currentTarget as HTMLElement).classList.add(toolbarShow));
        listen(downloadButton, mouseleave, e => (e.currentTarget as HTMLElement).classList.remove(toolbarShow));
        listen(downloadButton, "focus", e => (e.currentTarget as HTMLElement).classList.add(toolbarShow));
        listen(downloadButton, "blur", e => (e.currentTarget as HTMLElement).classList.remove(toolbarShow));

        listen(downloadButton, click, e => {
            const div = (e.currentTarget as HTMLElement).parentElement;
            if (!div) {
                return false;
            }

            const codes = div.getElementsByTagName("code");
            if ((codes !== null) && (codes.length > 0)) {
                const code = codes[0];
                if (!code) {
                    return false;
                }

                const text = getToolbarDivText(div);
                let downloadas = code.dataset.downloadas;
                if (!downloadas || downloadas === "") {
                    let lang = "";
                    for (const cl of code.classList) {
                        if (!cl) {
                            continue;
                        }

                        if (cl.startsWith("language-")) {
                            lang = cl.substr(9);
                            break;
                        } else if (cl.startsWith("command-")) {
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
        listen(printButton, mouseenter, e => (e.currentTarget as HTMLElement).classList.add(toolbarShow));
        listen(printButton, mouseleave, e => (e.currentTarget as HTMLElement).classList.remove(toolbarShow));
        listen(printButton, "focus", e => (e.currentTarget as HTMLElement).classList.add(toolbarShow));
        listen(printButton, "blur", e => (e.currentTarget as HTMLElement).classList.remove(toolbarShow));

        listen(printButton, click, e => {
            const div = (e.currentTarget as HTMLElement).parentElement;
            if (div) {
                const text = getToolbarDivText(div);
                printText(text);
            }
            return true;
        });

        // wrap the PRE block in a DIV so we have a place to attach the toolbar buttons
        const div = document.createElement("div");
        div.className = "toolbar";

        const parent = pre.parentElement;
        if (parent) {
            parent.insertBefore(div, pre);
        }
        div.appendChild(pre);
        div.appendChild(printButton);
        div.appendChild(downloadButton);
        div.appendChild(copyButton);

        listen(pre, mouseenter, o => {
            const e = o.currentTarget as HTMLElement;
            const next0 = e.nextElementSibling as HTMLElement;
            if (next0) {
                next0.classList.add(toolbarShow);
                const next1 = next0.nextElementSibling as HTMLElement;
                if (next1) {
                    next1.classList.add(toolbarShow);
                    const next2 = next1.nextElementSibling as HTMLElement;
                    if (next2) {
                        next2.classList.add(toolbarShow);
                    }
                }
            }
        });

        listen(pre, mouseleave, o => {
            const e = o.currentTarget as HTMLElement;
            const next0 = e.nextElementSibling as HTMLElement;
            if (next0) {
                next0.classList.remove(toolbarShow);
                const next1 = next0.nextElementSibling as HTMLElement;
                if (next1) {
                    next1.classList.remove(toolbarShow);
                    const next2 = next1.nextElementSibling as HTMLElement;
                    if (next2) {
                        next2.classList.remove(toolbarShow);
                    }
                }
            }
        });
    }

    function getToolbarDivText(div: HTMLElement): string {
        const commands = div.getElementsByClassName("command") as HTMLCollectionOf<HTMLElement>;
        if ((commands !== null) && (commands.length > 0)) {
            const inner = commands[0].innerText;
            const lines = inner.split("\n");
            let cmd = "";
            for (let i = 0; i < lines.length; i++) {
                if (lines[i].startsWith("$ ")) {
                    lines[i] = lines[i].substring(2);
                }

                if (cmd !== "") {
                    cmd += "\n";
                }

                cmd += lines[i];
            }

            return cmd;
        }

        return div.innerText;
    }

    function applyTransformations(pre: HTMLElement): void {
        const code = pre.firstElementChild as HTMLElement;
        if (code == null) {
            return;
        }

        let cl = "";
        for (const o of code.classList) {
            if (o && o.startsWith("language-bash")) {
                cl = o;
                break;
            }
        }

        if (cl !== "") {
            let firstLineOfOutput = 0;
            const lines = code.innerText.split("\n");
            let cmd = "";
            let escape = false;
            let escapeUntilEOF = false;
            let tmp = "";
            for (let j = 0; j < lines.length; j++) {
                const line = lines[j];

                if (line.startsWith("$ ")) {
                    if (tmp !== "") {
                        if (syntaxColoring) {
                            cmd += "$ " + Prism.highlight(tmp, Prism.languages.bash, "bash") + "\n";
                        } else {
                            cmd += "$ " + tmp + "\n";
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
                    cmd += "$ " + Prism.highlight(tmp, Prism.languages.bash, "bash") + "\n";
                } else {
                    cmd += "$ " + tmp + "\n";
                    cmd = cmd.replace(/</g, "&lt;").replace(/>/g, "&gt;");
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
                    output = output.replace(/</g, "&lt;").replace(/>/g, "&gt;");

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
            } else if (syntaxColoring) {
                // someone probably forgot to start a block with $, so let's just treat the whole thing as being a `bash` block
                Prism.highlightElement(code, false);
            }
        } else if (syntaxColoring) {
            // this isn't one of our special code blocks, so handle normally
            Prism.highlightElement(code, false);
        }
    }

    // Load the content of any externally-hosted PRE block
    function loadExternal(pre: HTMLElement): void {
        function fetchFile(elem: HTMLElement, url: string) {
            fetch(url)
                .then(response => {
                    if (response.status !== 200) {
                        return "Unable to access " + url + ": " + response.statusText;
                    }

                    return response.text();
                })
                .catch(e => {
                    return "Unable to access " + url + ": " + e;
                })
                .then(data => {
                    if (code.dataset.snippet) {
                        const pattern = "\\#.*?\\$snippet " + code.dataset.snippet + "\\n(.*?)\\n\\#.+?\\$endsnippet";
                        const regex = new RegExp(pattern, "gms");

                        let buf = "";
                        let match = regex.exec(data);
                        while (match !== null) {
                            if (buf !== "") {
                                buf += "\n";
                            }
                            buf += match[1];
                            match = regex.exec(data);
                        }
                        data = buf;
                    }

                    elem.textContent = data;
                    applyTransformations(pre);
                });
        }

        const code = pre.firstElementChild as HTMLElement;
        if (code && code.dataset.src) {
            fetchFile(code, code.dataset.src);
        }
    }

    function handleSyntaxColoringOption(): void {
        const cookieValue = readCookie(syntaxColoringCookie);
        if (cookieValue === "true") {
            syntaxColoring = true;
        } else if (cookieValue === "false") {
            syntaxColoring = false;
        }

        const item = document.getElementById(syntaxColoringItem);
        if (item) {
            if (syntaxColoring) {
                item.classList.add(active);
            } else {
                item.classList.remove(active);
            }
        }

        listen(getById(syntaxColoringItem), click, () => {
            createCookie(syntaxColoringCookie, syntaxColoring ? "false" : "true");
            location.reload();
        });
    }

    handleSyntaxColoringOption();

    document.querySelectorAll<HTMLElement>("pre").forEach(pre => {
        attachToolbar(pre);
        applyTransformations(pre);
        loadExternal(pre);
    });
}

handleCodeBlocks();

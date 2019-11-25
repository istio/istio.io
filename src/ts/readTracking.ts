// Copyright Istio Authors
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

let trackedPages: any = null;
let visitedPages: any = null;

function loadVisitedPages(): void {
    const blob = localStorage.getItem("visitedPages");
    if (blob != null) {
        visitedPages = JSON.parse(blob);
    }
}

function saveVisitedPages(): void {
    localStorage.setItem("visitedPages", JSON.stringify(visitedPages));
}

function markPagesAsVisited(prefix: string): void {
    if (trackedPages !== null) {
        let dirty = false;
        for (const trackedPage in trackedPages) {
            if (trackedPages.hasOwnProperty(trackedPage)) {
                if (trackedPage.startsWith(prefix)) {
                    visitedPages[trackedPage] = 1;
                    dirty = true;
                }
            }
        }

        if (dirty) {
            saveVisitedPages();
            setPills();
            setDots();
            setMarkAllRead();
        }
    }
}

function setPills(): void {
    document.querySelectorAll<HTMLElement>(".pill").forEach(pill => {
        const prefix = pill.dataset.prefix;
        if (prefix === undefined) {
            return;
        }

        const count = countUnvisited(prefix);
        if (count > 0) {
            pill.classList.add("visible");
            pill.innerText = count.toString();
        } else {
            pill.classList.remove("visible");
        }
    });
}

function setDots(): void {
    document.querySelectorAll<HTMLElement>(".dot").forEach(dot => {
        const prefix = dot.dataset.prefix;
        if (prefix === undefined) {
            return;
        }

        const count = countUnvisited(prefix);
        if (count > 0) {
            dot.classList.add("visible");
        } else {
            dot.classList.remove("visible");
        }
    });
}

function setMarkAllRead(): void {
    const button = getById("mark-all-read");
    if (button != null) {
        const prefix = button.dataset.prefix;
        if (prefix === undefined) {
            return;
        }

        const count = countUnvisited(prefix);
        if (count > 0) {
            button.classList.add("visible");
        } else {
            button.classList.remove("visible");
        }
    }
}

function countUnvisited(prefix: string): number {
    let count = 0;
    for (const trackedPage in trackedPages) {
        if (trackedPages.hasOwnProperty(trackedPage)) {
            if (trackedPage.startsWith(prefix)) {
                let found = false;
                for (const visitedPage in visitedPages) {
                    if (trackedPage === visitedPage) {
                        found = true;
                        break;
                    }
                }

                if (!found) {
                    count++;
                }
            }
        }
    }

    return count;
}

function handleReadTracking(): void {
    // Asynchronously loads the set of tracked pages, which are the pages we
    // consider for pills
    function fetchTrackedPagesIndex(): void {
        fetch("/_tracked_pages.json")
            .then(response => {
                if (!response.ok) {
                    throw new Error("HTTP error " + response.status);
                }
                return response.json();
            })
            .then(json => {
                trackedPages = json;

                let dirty = false;
                if (visitedPages === null) {
                    // if we didn't find any list of visited pages, initialize it to the set of tracked pages
                    visitedPages = new Map();

                    for (const trackedPage in trackedPages) {
                        if (trackedPages.hasOwnProperty(trackedPage)) {
                            visitedPages[trackedPage] = 1;
                        }
                    }
                    dirty = true;
                } else {
                    // if we did find a list of visited pages, trim it to only contain what's in the tracked pages map
                    for (const visitedPage in visitedPages) {
                        if (visitedPages.hasOwnProperty(visitedPage)) {
                            if (trackedPages[visitedPage] === undefined) {
                                visitedPages.delete(visitedPage);
                                dirty = true;
                            }
                        }
                    }
                }

                // if the current page is being tracked, record that the user has visited this page
                const page = window.location.pathname;
                if (trackedPages[page] !== undefined) {
                    if (visitedPages[page] === undefined) {
                        visitedPages[page] = 1;
                        dirty = true;
                    }
                }

                if (dirty) {
                    saveVisitedPages();
                }

                setPills();
                setDots();
                setMarkAllRead();
            });
    }

    loadVisitedPages();
    fetchTrackedPagesIndex();
}

handleReadTracking();

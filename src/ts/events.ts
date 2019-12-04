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

// Handles banners and stickers
function handleEvents(): void {
    const now = new Date().valueOf();
    let remainingEventImpressions: any = {};

    function loadRemainingEventImpressions(): void {
        const blob = readLocalStorage("remainingEventImpressions");
        if (blob != null) {
            remainingEventImpressions = JSON.parse(blob);
        }

        // if any events are past their end date, remove them
        for (const entry in remainingEventImpressions) {
            if (remainingEventImpressions.hasOwnProperty(entry)) {
                const periodEnd = parseInt(remainingEventImpressions[entry].periodEnd, 10);
                if (now > periodEnd) {
                    delete remainingEventImpressions[entry];
                }
            }
        }
    }

    function saveRemainingEventImpressions(): void {
        localStorage.setItem("remainingEventImpressions", JSON.stringify(remainingEventImpressions));
    }

    function displayEvents(event: string) {
        document.querySelectorAll<HTMLElement>("." + event).forEach(el => {
            if (!el.dataset.title || !el.dataset.periodStart || !el.dataset.periodEnd) {
                return;
            }

            const title = el.dataset.title;
            const periodStart = parseInt(el.dataset.periodStart, 10);
            const periodEnd = parseInt(el.dataset.periodEnd, 10) + 24 * 3600 * 1000 - 1; // include the final day

            let maxImpressions = 0;
            if (el.dataset.maxImpressions) {
                maxImpressions = parseInt(el.dataset.maxImpressions, 10);
            }

            if (maxImpressions === 0) {
                maxImpressions = 1000000;   // our definition of "infinite"
            }

            let timeout = 0;
            if (el.dataset.timeout) {
                timeout = parseInt(el.dataset.timeout, 10);
            }

            let display = false;
            if ((now >= periodStart) && (now <= periodEnd)) {
                if (remainingEventImpressions[title]) {
                    // an event we've seen before
                    let impr = remainingEventImpressions[title].impressions;
                    if (impr > 0) {
                        // if there are still impressions left, decrement and save the count
                        impr--;
                        remainingEventImpressions[title].impressions = impr;
                        display = true;
                    }
                } else {
                    // remember this event
                    remainingEventImpressions[title] = {};
                    remainingEventImpressions[title].impressions = maxImpressions - 1;
                    remainingEventImpressions[title].periodEnd = periodEnd;
                    display = true;
                }

                if (display) {
                    el.style.display = "block";

                    if (timeout > 0) {
                        window.setTimeout(() => el.style.display = "none", timeout * 1000);
                    }
                }

                listen(el, click, () => {
                    el.style.display = "none";
                    remainingEventImpressions[title].impressions = 0;
                    saveRemainingEventImpressions();
                });

                el.querySelectorAll<HTMLSpanElement>(".countdown").forEach(span => {
                    refreshCountdownValue(span, periodEnd);
                    window.setInterval(() => refreshCountdownValue(span, periodEnd), 1000);
                });
            }
        });
    }

    function refreshCountdownValue(span: HTMLSpanElement, periodEnd: number): void {
        const delta = periodEnd - new Date().valueOf() - (1000 * 3600 * 24);  // countdown to the start of the last day
        const numDays = Math.round(delta / (1000 * 3600 * 24));
        if (span.dataset.type === "days") {
            span.innerText = numDays.toString();
        } else if (span.dataset.type === "full") {
            if (numDays > 0) {
                span.innerText = numDays + "d " + new Date(delta).toISOString().substr(11, 8);
            } else {
                span.innerText = new Date(delta).toISOString().substr(11, 8);
            }
        }
    }

    loadRemainingEventImpressions();
    displayEvents("banner");
    displayEvents("sticker");
    saveRemainingEventImpressions();
}

handleEvents();

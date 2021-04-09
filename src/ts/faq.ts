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

const faqBlockCollapsed = "faq-block--collapsed";

function handleFaqBlocks(): void {
    const faqBlocks: Element[] = [];

    document.querySelectorAll(".faq-block").forEach(faqBlock => {
        const question = faqBlock.querySelector(".faq-block-question");
        faqBlocks.push(faqBlock);

        question?.addEventListener("click", () => {
            faqBlock.classList.toggle(faqBlockCollapsed);
        });
    });

    function dealWithHash(): void {
        const urlHash = location.hash.replace("#", "");
        const hashFaqBlock = faqBlocks.find(faqBlock => urlHash === faqBlock.id);

        if (hashFaqBlock) {
            hashFaqBlock.classList.remove(faqBlockCollapsed);
        }
    }

    // Deal with hash on the initial page load
    dealWithHash();

    // Listen to hash change to navigate to another FAQ if necessary
    listen(window, "hashchange", dealWithHash);
}

handleFaqBlocks();

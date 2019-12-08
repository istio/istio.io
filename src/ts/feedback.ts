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

declare function gtag(type: string, action: string, payload: any): void;

function sendFeedback(language: string, value: number): void {
    gtag("event", "click-" + language, {
        event_category: "Helpful",
        event_label: window.location.pathname,
        value,
    });

    const initial = getById("feedback-initial");
    if (initial) {
        initial.style.display = "none";
    }

    let next = "feedback-thankyou";
    if (value === 0) {
        next = "feedback-comment";
    }

    const ne = getById(next);
    if (ne) {
        ne.style.display = "block";
    }
}

function sendComment(language: string, value: string): void {
    gtag("event", "comment-" + language, {
        event_category: "Helpful",
        event_label: window.location.pathname,
        value,
    });

    const comment = getById("feedback-comment");
    if (comment) {
        comment.style.display = "none";
    }

    const ty = getById("feedback-thankyou");
    if (ty) {
        ty.style.display = "block";
    }
}

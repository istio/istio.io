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

    const ty = getById("feedback-thankyou");
    if (!ty) {
        return;
    }

    // say thank you and leave
    ty.style.display = "inline-block";

    /*
    TODO: this code is disabled since at the moment there isn't a good place to send any written feedback to.

    if (value === 1) {
        // say thank you and leave
        ty.style.display = "inline-block";
        return;
    }

    const cm = getById("feedback-comment");
    if (!cm) {
        return
    }

    const tb = getById("feedback-textbox");
    if (!tb) {
        return
    }

    cm.style.display = "inline-block";
    tb.focus();

    listen(tb, "keypress", o => {
        const e = o as KeyboardEvent;

        if (e.keyCode != keyCodes.RETURN) {
            return;
        }

        // TODO: send the feedback somewhere

        cm.style.display = "none";
        ty.style.display = "inline-block";
    });
     */
}

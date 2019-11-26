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

    document.querySelectorAll<HTMLButtonElement>(".feedback").forEach(button => {
        button.disabled = true;
    });
}

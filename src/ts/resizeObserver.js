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

"use strict";

function observeResize(el, callback) {
    if (window.ResizeObserver) {
       const ro = new ResizeObserver(entries => {
            for (let entry of entries) {
                callback(entry.target);
            }
       });

       ro.observe(el);
    } else {
        // simple fallback...
        listen(window, "resize", () => {
            callback(el);
        });
    }
}

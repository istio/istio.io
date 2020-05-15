// Copyright 2020 Istio Authors
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
package trafficmanagement

import (
	"testing"

	"istio.io/istio.io/pkg/test/istioio"
	"istio.io/istio/pkg/test/framework"
)

func TestCircuitBreaker(t *testing.T) {
	framework.
		NewTest(t).
		Run(istioio.NewBuilder("tasks__traffic_management__circuit_breaking").
			Add(
				istioio.Script{Input: istioio.Path("scripts/circuitbreaker_test_setup.txt")},
				istioio.MultiPodWait("istio-io-circuitbreaker"),
				istioio.Script{Input: istioio.Path("scripts/trip_circuitbreaker.txt")},
			).
			Defer(istioio.Script{Input: istioio.Path("scripts/circuitbreaker_test_cleanup.txt")}).
			Build())
}

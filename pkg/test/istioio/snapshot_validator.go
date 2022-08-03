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

package istioio

import (
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/pmezard/go-difflib/difflib"

	"istio.io/istio/pkg/test/framework"
	"istio.io/istio/pkg/test/scopes"
	"istio.io/istio/pkg/test/util/retry"
)

var (
	snapshotRetryTimeout = retry.Timeout(2 * time.Minute)
	snapshotRetryDelay   = retry.Delay(1 * time.Second)
)

var _ Step = SnapshotValidator{}

// SnapshotValidator is a Step that compares before and after snapshots. If the
// comparison fails, it will retry for up to 2 minutes.
type SnapshotValidator struct {
	Before *Snapshotter
	After  *Snapshotter
}

func (s SnapshotValidator) Name() string {
	// Use the After step name as the name of the test.
	return s.After.StepName
}

func (s SnapshotValidator) run(ctx framework.TestContext) {
	inBeforeFile := s.Before.OutputFile
	if len(inBeforeFile) == 0 {
		scopes.Framework.Warnf("begin snapshot missing, skipping snapshot validation")
		return
	}

	inBeforeBytes, err := os.ReadFile(inBeforeFile)
	if err != nil {
		ctx.Fatalf("failed reading before snapshot: %v", err)
	}
	expected := string(inBeforeBytes)

	// Copy the before file to the current working directory to aid debugging.
	inBeforeFileCopy := filepath.Join(ctx.WorkDir(), filepath.Base(inBeforeFile))
	if err := os.WriteFile(inBeforeFileCopy, inBeforeBytes, os.ModePerm); err != nil {
		ctx.Fatalf("failed copying before snapshot: %v", err)
	}

	diffFile := filepath.Join(ctx.WorkDir(), "diff.txt")

	// Retry the comparison
	if _, err = retry.UntilComplete(func() (result interface{}, completed bool, err error) {
		// Generate the new snapshot.
		s.After.run(ctx)

		actual, err := s.After.GeneratedSnapshot.ToJSON()
		if err != nil {
			// Fatal error, shouldn't happen
			return nil, true, fmt.Errorf("failed marshaling after snapshot: %v", err)
		}

		// Diff the before and after snapshots
		diff := difflib.UnifiedDiff{
			A:       difflib.SplitLines(expected),
			B:       difflib.SplitLines(actual),
			Context: 2,
		}

		diffText, err := difflib.GetUnifiedDiffString(diff)
		if err != nil {
			// Fatal error, shouldn't happen
			return nil, true, err
		}

		if err := os.WriteFile(diffFile, []byte(diffText), os.ModePerm); err != nil {
			// Fatal os.shouldn't happen
			return nil, true, err
		}

		if actual != expected {
			// Retriable error.
			return nil, false, fmt.Errorf("snapshots are different: \n%v", diffText)
		}
		return nil, true, nil
	}, snapshotRetryTimeout, snapshotRetryDelay); err != nil {
		ctx.Fatal(err)
	}
}

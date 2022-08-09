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
	"os"
	"path/filepath"

	"istio.io/istio/pkg/test/framework"
	"istio.io/istio/pkg/test/scopes"
)

var _ Step = &Snapshotter{}

// Snapshotter is a Step that captures a snapshot of the contents of a cluster.
type Snapshotter struct {
	// KubeConfig for all the clusters in the mesh.
	KubeConfig string

	// StepName used to generate the name for the output file.
	StepName string

	// GeneratedSnapshot set after this Snapshotter is successfully run.
	GeneratedSnapshot MeshSnapshot

	// OutputFile contains the full path to the generated JSON file for the snapshot.
	// Set after this Snapshotter is successfully run.
	OutputFile string
}

func (s *Snapshotter) Name() string {
	return s.StepName
}

func (s *Snapshotter) run(ctx framework.TestContext) {
	ctx.Helper()

	snapshot, err := NewMeshSnapshot(s.KubeConfig)
	if err != nil {
		ctx.Fatal(err)
	}

	snapshotJSON, err := snapshot.ToJSON()
	if err != nil {
		ctx.Fatalf("failed converting snapshot to JSON: %v", err)
	}

	outputFile := filepath.Join(ctx.WorkDir(), s.StepName+".json")
	if err := os.WriteFile(outputFile, []byte(snapshotJSON), os.ModePerm); err != nil {
		ctx.Fatal("failed writing snapshot file: %v", err)
	}

	scopes.Framework.Infof("Created mesh snapshot file %s", outputFile)
	s.GeneratedSnapshot = snapshot
	s.OutputFile = outputFile
}

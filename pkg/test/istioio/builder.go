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
	"path"

	"istio.io/istio/pkg/test/env"
	"istio.io/istio/pkg/test/framework"
	"istio.io/istio/pkg/test/scopes"
)

// Builder builds a test of a documented workflow from https://istio.io.
type Builder struct {
	steps        []Step
	cleanupSteps []Step
}

// NewBuilder returns an instance of a document test.
func NewBuilder() *Builder {
	return &Builder{}
}

// Add a step to be run.
func (b *Builder) Add(steps ...Step) *Builder {
	b.steps = append(b.steps, steps...)
	return b
}

// Defer registers a function to be executed when the test completes.
func (b *Builder) Defer(steps ...Step) *Builder {
	b.cleanupSteps = append(b.cleanupSteps, steps...)
	return b
}

// Build a run function for the test
func (b *Builder) Build() func(ctx framework.TestContext) {
	return func(ctx framework.TestContext) {
		scopes.Framework.Infof("Executing test %s (%d steps)", ctx.Name(), len(b.steps))

		// create a symbolic link to samples/, for easy access
		samplesSymlink := path.Join(ctx.WorkDir(), "samples")
		if _, err := os.Stat(samplesSymlink); os.IsNotExist(err) {
			err = os.Symlink(path.Join(env.IstioSrc, "samples"), samplesSymlink)
			if err != nil {
				scopes.Framework.Warnf("Could not create symlink to samples/ directory at %s", samplesSymlink)
			} else {
				defer func() {
					_ = os.Remove(samplesSymlink)
				}()
			}
		}

		// Run cleanup functions at the end.
		defer func() {
			for _, step := range b.cleanupSteps {
				ctx.NewSubTest(step.Name()).Run(func(ctx framework.TestContext) {
					step.run(ctx)
				})
			}
		}()

		for _, step := range b.steps {
			ctx.NewSubTest(step.Name()).Run(func(ctx framework.TestContext) {
				step.run(ctx)
			})
		}
	}
}

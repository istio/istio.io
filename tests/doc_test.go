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
//
// This is the framework for doc testing. It scans through the content
// folder and runs each matched `tesh.sh` file as a subtest.
package framework

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"istio.io/istio.io/pkg/test/istioio"
	"istio.io/istio/pkg/test/framework"
	"istio.io/istio/pkg/test/framework/components/istio"
	"istio.io/istio/pkg/test/framework/resource/environment"
)

var (
	inst istio.Instance

	testsToRun   = os.Getenv("TEST")
	testEnv      = os.Getenv("ENV")
	runAllTests  = (testsToRun == "")
	testsAsSlice = split(testsToRun)

	contentFolder = "../content"

	setupTemplate = `
		cd ${REPO_ROOT}
		source "content/%v" # snips.sh
		source "tests/util/verify.sh"
		source "tests/util/debug.sh"
		source "tests/util/helpers.sh"
	`

	snipsFileSuffix = "/snips.sh"
	testFileSuffix  = "/test.sh"
	testCleanupSep  = "# @cleanup"
)

// split breaks down the test names specified into a slice.
// It receives a comma-separated string of test names that the user has
// specified from command line, and returns a slice of separated strings.
func split(testsAsString string) []string {
	testsAsSlice := strings.Split(testsAsString, ",")

	// tweak to enforce strict equality of test names
	for idx := range testsAsSlice {
		testsAsSlice[idx] = fmt.Sprintf("/%v/", testsAsSlice[idx])
	}
	return testsAsSlice
}

// TestMain does setup for all tests
func TestMain(m *testing.M) {
	if runAllTests {
		log.Println("Starting test doc(s): all docs will be tested")
	} else {
		log.Println("Starting test doc(s):", testsToRun)
	}
	log.Println("Setting up istio for the test environment:", testEnv)

	testEnvName := environment.Name(testEnv)

	framework.
		NewSuite("doc_test", m).
		SetupOnEnv(testEnvName, istio.Setup(&inst, nil)).
		Run()
}

// TestDocs traverses through content and run each matched test
func TestDocs(t *testing.T) {
	err := filepath.Walk(
		contentFolder,
		func(path string, info os.FileInfo, walkError error) error {
			if walkError != nil {
				return walkError
			}
			// check if current file is a matched test.sh file
			checkFile := strings.HasSuffix(path, testFileSuffix) &&
				(runAllTests || matched(path, testsAsSlice))
			if checkFile {
				runTestFile(path, t)
			}
			return nil
		},
	)
	if err != nil {
		log.Fatalln("Error occurred while traversing content:", err)
	}
}

// matched checks whether a given test needs to be run according to the
// user's request. It receives two arguments: `path`, the test file to be
// checked, and `tests`, the names of the tests that should be run.
func matched(path string, tests []string) bool {
	for _, test := range tests {
		if strings.Contains(path, test) {
			return true
		}
	}
	return false
}

// runTestFile runs a subtest for the given test script file. It receives
// `path`, the test file to be run, and a (*testing.T) variable passed down
// from TestDocs to create subtests.
func runTestFile(path string, t *testing.T) {
	t.Run(path, func(t *testing.T) {
		script, err := ioutil.ReadFile(path)
		if err != nil {
			log.Println(err)
			t.FailNow()
		}

		// parse the script into test and cleanup
		splitScript := strings.Split(string(script), testCleanupSep)
		if numParts := len(splitScript); numParts != 2 {
			log.Printf(
				"Script parsing error: Expected two-part script separated by '%v', got %v part(s)",
				testCleanupSep, numParts,
			)
			t.FailNow()
		}

		setupScript := getSetupScript(path)
		testScript := splitScript[0]
		cleanupScript := splitScript[1]

		// run the scripts using the istio test framework
		// TODO: impose timeout for each subtest
		// TODO: run the subtests in parallel to reduce test time
		framework.
			NewTest(t).
			Run(istioio.NewBuilder(path).
				Add(istioio.Script{
					Input: istioio.Inline{
						FileName: "test.sh",
						Value:    setupScript + testScript,
					},
				}).
				Defer(istioio.Script{
					Input: istioio.Inline{
						FileName: "cleanup.sh",
						Value:    setupScript + cleanupScript,
					},
				}).
				Build())
	})
}

// getSetupScript returns a setup script that automatically sources the
// snippets and some test utilities. It receives `testPath`, which is the
// path of the test script file to be run.
func getSetupScript(testPath string) string {
	snipsPath := strings.ReplaceAll(testPath, testFileSuffix, snipsFileSuffix)
	return fmt.Sprintf(setupTemplate, snipsPath)
}

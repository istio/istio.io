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
package content

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

	setupTemplate = `
		source "${REPO_ROOT}/content/%v" # snips.sh
		source "${REPO_ROOT}/tests/util/verify.sh"
		cd ${REPO_ROOT}
	`

	snipsFileSuffix = "/snips.sh"
	testFileSuffix  = "/test.sh"
	testCleanupSep  = "# @cleanup"
)

func split(testsAsString string) []string {
	testsAsSlice := strings.Split(testsAsString, ",")
	for i := 0; i < len(testsAsSlice); i++ {
		test := &testsAsSlice[i]
		*test = fmt.Sprintf("/%v/", *test) // to enforce strict equality of test names
	}
	return testsAsSlice
}

// setup for all tests
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

// traverse through content and run each matched test
func TestDocs(t *testing.T) {
	err := filepath.Walk(".",
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

func matched(path string, tests []string) bool {
	for _, test := range tests {
		if strings.Contains(path, test) {
			return true
		}
	}
	return false
}

// run a subtest for the given test.sh file
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

// get setup script that sources snips.sh, test utils, etc.
func getSetupScript(testPath string) string {
	snipsPath := strings.ReplaceAll(testPath, testFileSuffix, snipsFileSuffix)
	return fmt.Sprintf(setupTemplate, snipsPath)
}

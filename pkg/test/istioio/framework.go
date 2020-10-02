// Package istioio includes the framework for doc testing. This package will
// first scan through all the docs to collect their information, and then
// setup istio as appropriate to run each test.
//
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
package istioio

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"regexp"
	"strings"

	"istio.io/istio/pkg/test/framework"
)

// TestCase is a description of a test extracted from a file
type TestCase struct {
	valid         bool   // whether it is a valid test case that can be run
	path          string // path of the test file
	config        string // setup config of the test
	testScript    string // test script to be run
	cleanupScript string // cleanup script to be run
}

var (
	testsToRun  = os.Getenv("TEST")
	runAllTests = (testsToRun == "")

	// folder location to be traversed to look for test files
	defaultPath   = "content/en/docs"
	contentFolder = fmt.Sprintf("%v/%v/", os.Getenv("REPO_ROOT"), defaultPath)

	// scripts that are sourced for all tests
	helperTemplate = `
		cd ${REPO_ROOT}
		source "%v/%v" # snips.sh
		source "tests/util/verify.sh"
		source "tests/util/debug.sh"
		source "tests/util/helpers.sh"
	`

	clusterSnapshot = `
		__cluster_snapshot
	`

	clusterCleanupCheck = `
		__cluster_cleanup_check
	`

	snipsFileSuffix = "snips.sh"
	testFileSuffix  = "test.sh"

	setupSpec      = "# @setup"
	testCleanupSep = "# @cleanup"

	// constructed test cases for the specified tests
	testCases []TestCase
)

// init constructs test cases from all specified tests
func init() {
	if runAllTests {
		log.Println("Starting test doc(s): all docs")
	} else {
		log.Println("Starting test doc(s):", testsToRun)
	}

	// scan for the test script files
	for _, testFolder := range split(testsToRun) {
		err := filepath.Walk(
			contentFolder+testFolder,
			func(path string, info os.FileInfo, walkError error) error {
				if walkError != nil {
					return walkError
				}
				// check if ends with test.sh
				if strings.HasSuffix(path, testFileSuffix) {
					if testCase, err := checkFile(path); testCase.valid {
						testCases = append(testCases, *testCase)
					} else if err != nil {
						log.Fatalf("Error occurred while processing %v: %v\n", testCase.path, err)
					}
				}
				return nil
			},
		)
		if err != nil {
			log.Fatalln("Error occurred while traversing content:", err)
		}
	}

	// in case no matched script files were found
	if len(testCases) == 0 {
		log.Printf("Warning: no test scripts are found that match '%v'", testsToRun)
	}
}

// checkFile takes a file path as the input and returns a TestCase object
// that is constructed out of the file as a file description
func checkFile(path string) (*TestCase, error) {
	shortPath := path[len(contentFolder):]
	testCase := &TestCase{path: shortPath}

	// read the script file
	script, err := ioutil.ReadFile(path)
	if err != nil {
		return testCase, err
	}

	// parse the script into test and cleanup
	splitScript := strings.Split(string(script), testCleanupSep)
	if numParts := len(splitScript); numParts != 2 {
		err := fmt.Errorf(
			"script error: expected two-part script separated by '%v', got %v part(s)",
			testCleanupSep, numParts,
		)
		return testCase, err
	}
	helperScript := getHelperScript(shortPath)
	testScript := splitScript[0]
	cleanupScript := splitScript[1]

	// copy the files sourced by test to cleanup
	re := regexp.MustCompile("(?m)^source \".*\\.sh\"$")
	sources := re.FindAllString(testScript, -1)
	cleanupScript = strings.Join(sources, "\n") + cleanupScript

	// find setup configuration
	re = regexp.MustCompile(fmt.Sprintf("(?m)^%v (.*)$", setupSpec))
	setups := re.FindAllStringSubmatch(testScript, -1)

	if numSetups := len(setups); numSetups != 1 {
		err := fmt.Errorf(
			"script error: expected one line that starts with '%v', got %v line(s)",
			setupSpec, numSetups,
		)
		return testCase, err
	}
	config := setups[0][1]

	// Check for proper test cleanup
	testScript = clusterSnapshot + testScript
	cleanupScript += clusterCleanupCheck

	testCase = &TestCase{
		valid:         true,
		path:          shortPath,
		config:        config,
		testScript:    helperScript + testScript,
		cleanupScript: helperScript + cleanupScript,
	}
	return testCase, nil
}

// NeedSetup checks if any of the test cases require the setup config
// specified by the input
func NeedSetup(config string) bool {
	for idx := range testCases {
		if testCases[idx].config == config {
			log.Printf("Setting up istio with %v", config)
			return true
		}
	}
	log.Printf("No tests need to be run with %v", config)
	return false
}

// NewTestDocsFunc returns a test function that traverses through all test
// cases and runs those that need the setup config specified by the input.
func NewTestDocsFunc(config string) func(framework.TestContext) {
	return func(ctx framework.TestContext) {
		for idx := range testCases {
			if testCase := &testCases[idx]; testCase.config == config {
				path := testCase.path
				ctx.NewSubTest(path).
					Run(NewBuilder().
						Add(Script{
							Input: Inline{
								FileName: getDebugFileName(path, "test"),
								Value:    testCase.testScript,
							},
						}).
						Defer(Script{
							Input: Inline{
								FileName: getDebugFileName(path, "cleanup"),
								Value:    testCase.cleanupScript,
							},
						}).
						Build())
			}
		}
	}
}

// Helper functions

// split breaks down the test names specified into a slice.
// It receives a comma-separated string of test names that the user has
// specified from command line, and returns a slice of separated strings.
func split(testsAsString string) []string {
	return strings.Split(testsAsString, ",")
}

// getHelperScript returns a helper script that automatically sources the
// snippets and some test utilities. It receives `testPath`, which is the
// path of the test script file to be run.
func getHelperScript(testPath string) string {
	splitPath := strings.Split(testPath, "/")
	splitPath[len(splitPath)-1] = snipsFileSuffix
	snipsPath := strings.Join(splitPath, "/")
	return fmt.Sprintf(helperTemplate, defaultPath, snipsPath)
}

// getDebugFileName returns the name of the debug file which keeps the bash
// tracing enabled by util/debug.sh. It receives `testPath`, the path of the
// test script, and a suffix to tell different output files apart.
func getDebugFileName(testPath string, debugFileSuffix string) string {
	fileName := strings.ReplaceAll(testPath, testFileSuffix, debugFileSuffix)
	fileName = strings.ReplaceAll(fileName, "/", "_")
	return fileName
}

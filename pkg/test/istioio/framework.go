// Copyright 2020 Istio Authors
//
// Package istioio includes the framework for doc testing. This package will
// first scan through all the docs to collect their information, and then
// setup istio as appropriate to run each test.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//	http://www.apache.org/licenses/LICENSE-2.0
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
	p "path"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"time"

	"istio.io/istio/pkg/test/framework"
	"istio.io/istio/pkg/test/scopes"
)

// TestCase is a description of a test extracted from a file
type TestCase struct {
	valid         bool   // whether it is a valid test case that can be run
	path          string // path of the test file
	config        string // setup config of the test
	testScript    string // test script to be run
	cleanupScript string // cleanup script to be run
	parent        string // parent id - indicates this test is a parent (optional)
	childOf       string // id of the parent set in the parent property. This is set on the child tests (optional)
	order         int    // order in which you want to run the child tests (optional)
}

var (
	testsToRun  = os.Getenv("TEST")
	runAllTests = testsToRun == ""

	// folder location to be traversed to look for test files
	defaultPath   = "content/en/docs"
	contentFolder = fmt.Sprintf("%v/%v/", os.Getenv("REPO_ROOT"), defaultPath)

	// scripts that are sourced for all tests
	scriptPrefixTemplate = `
### BEGIN INJECTED SCRIPT ###
cd ${REPO_ROOT}
source "tests/util/verify.sh"
source "tests/util/debug.sh"
source "tests/util/helpers.sh"
`
	scriptPrefixEndComment = `
### END INJECTED SCRIPT ###
`
	// command injected at start of cleanup script
	cleanupScriptPrefix = `
set +e # ignore cleanup errors
`
	snipsFileSuffix = "snips.sh"
	testFileSuffix  = "test.sh"

	setupSpec      = "# @setup"
	testCleanupSep = "# @cleanup"
	parentSpec     = "# @parent"
	childSpec      = "# @child"
	orderSpec      = "# @order"

	// constructed test cases for the specified tests
	testCases      []TestCase
	parentChildMap = make(map[string][]TestCase)
)

// init constructs test cases from all specified tests
func init() {
	seqTestCaseMap := make(map[int]TestCase)
	startTime := time.Now()
	defer func() {
		scopes.Framework.Infof("Finished initializing test doc(s). Elapsed time: %v",
			time.Since(startTime))
	}()

	if runAllTests {
		scopes.Framework.Infof("Initializing test doc(s): all docs")
	} else {
		scopes.Framework.Infof("Initializing test doc(s): %v", testsToRun)
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
					if testCase, seq, err := checkFile(path); testCase.valid {
						if seq == -1 {
							// this means the tests do not have to be run in any sequence
							testCases = append(testCases, *testCase)
						} else {
							// tests have to be run in a sequence that is set by @child tag
							seqTestCaseMap[seq] = *testCase
						}
					} else if err != nil {
						scopes.Framework.Fatalf("Error occurred while processing %v: %v", testCase.path, err)
					}
				}
				return nil
			},
		)
		if err != nil {
			scopes.Framework.Fatalf("Error occurred while traversing content: %v", err)
		}
	}

	if len(seqTestCaseMap) > 0 {

		seqKeys := make([]int, 0)
		for seq := range seqTestCaseMap {
			seqKeys = append(seqKeys, seq)
		}
		sort.Ints(seqKeys)
		for _, seq := range seqKeys {
			testCases = append(testCases, seqTestCaseMap[seq])
		}
	}

	// in case no matched script files were found
	if len(testCases) == 0 {
		scopes.Framework.Infof("Warning: no test scripts are found that match '%v'", testsToRun)
	}
}

// checkFile takes a file path as the input and returns a TestCase object
// that is constructed out of the file as a file description
func checkFile(path string) (*TestCase, int, error) {
	shortPath := path[len(contentFolder):]
	testCase := &TestCase{path: shortPath}
	var seq int = -1
	var pid string
	childOf := ""
	isParent := false
	isChild := false

	// read the script file
	script, err := os.ReadFile(path)
	if err != nil {
		return testCase, seq, err
	}

	// parse the script into test and cleanup
	splitScript := strings.Split(string(script), testCleanupSep)
	if numParts := len(splitScript); numParts != 2 {
		err := fmt.Errorf(
			"script error: expected two-part script separated by '%v', got %v part(s)",
			testCleanupSep, numParts,
		)
		return testCase, seq, err
	}
	testScript := splitScript[0]
	cleanupScript := splitScript[1]

	// copy the files sourced by test to cleanup
	re := regexp.MustCompile("(?m)^source \".*\\.sh\"$")
	sources := re.FindAllString(testScript, -1)
	cleanupScript = strings.Join(sources, "\n") + cleanupScriptPrefix + cleanupScript

	// find setup configuration
	re = regexp.MustCompile(fmt.Sprintf("(?m)^%v (.*)$", setupSpec))
	setups := re.FindAllStringSubmatch(testScript, -1)

	if numSetups := len(setups); numSetups != 1 {
		err := fmt.Errorf(
			"script error: expected one line that starts with '%v', got %v line(s)",
			setupSpec, numSetups,
		)
		return testCase, seq, err
	}
	config := setups[0][1]

	// find parent
	re = regexp.MustCompile(fmt.Sprintf("(?m)^%v (.*)$", parentSpec))
	parentSeq := re.FindAllStringSubmatch(testScript, -1)
	if numParents := len(parentSeq); numParents >= 1 {
		id := parentSeq[0][1]
		isParent = true
		parentID := strings.Split(id, "=")
		pid = parentID[1]
	}

	// find child
	re = regexp.MustCompile(fmt.Sprintf("(?m)^%v (.*)$", childSpec))
	childRel := re.FindAllStringSubmatch(testScript, -1)
	if numSequence := len(childRel); numSequence >= 1 {
		isChild = true
		childOf = childRel[0][1]
	}

	// find child sequence
	re = regexp.MustCompile(fmt.Sprintf("(?m)^%v (.*)$", orderSpec))
	childSeq := re.FindAllStringSubmatch(testScript, -1)
	if numSequence := len(childSeq); numSequence >= 1 {
		order := childSeq[0][1]
		seq, _ = strconv.Atoi(order)
	}

	// Check for proper test cleanup
	scriptPrefix := scriptPrefixTemplate
	snipsPath := p.Join(contentFolder, getSnipsPath(shortPath))
	scopes.Framework.Infof("Get snips path from %v is %v", shortPath, snipsPath)
	if _, err := os.Stat(snipsPath); os.IsNotExist(err) {
		if !isParent {
			err := fmt.Errorf(
				"script error: snips.sh is missing for %v",
				snipsPath,
			)
			return testCase, seq, err
		}
		scriptPrefix += scriptPrefixEndComment
	} else {
		// Check for proper test cleanup
		scriptPrefix += "\nsource \"%v/%v\" # snips.sh"
		scriptPrefix += scriptPrefixEndComment
		scriptPrefix = getTemplateScript(scriptPrefix, shortPath)
	}

	testScript = addScriptPrefix(scriptPrefix, testScript)
	cleanupScript = addScriptPrefix(scriptPrefix, cleanupScript)

	testCase = &TestCase{
		valid:         true,
		path:          shortPath,
		config:        config,
		testScript:    testScript,
		cleanupScript: cleanupScript,
	}

	if isParent {
		testCase.parent = pid
	} else if isChild {
		testCase.childOf = childOf
		testCase.order = seq
	}

	return testCase, seq, nil
}

func addScriptPrefix(prefix, script string) string {
	out := ""
	needToAdd := true

	// Add the prefix before the first uncommented line.
	for _, line := range strings.Split(script, "\n") {
		if needToAdd && !strings.HasPrefix(line, "#") {
			out += prefix + "\n"
			needToAdd = false
		}

		out += line + "\n"
	}

	return out
}

// NewTestDocsFunc returns a test function that traverses through all test
// cases and runs those that need the setup config specified by the input.
func NewTestDocsFunc(config string) func(framework.TestContext) {
	return func(ctx framework.TestContext) {
		testsToRun := testsForConfig(config)
		if len(testsToRun) == 0 {
			ctx.Skipf("No tests need to be run with %v", config)
		}

		scopes.Framework.Infof("Setting up istio with %v", config)

		for _, testCase := range testsToRun {
			path := testCase.path
			testScriptName := filepath.Base(path)
			cleanupScriptName := "cleanup.sh"
			builder := NewBuilder()

			// Create the mesh snapshotters
			kubeConfig := getKubeConfig(ctx)
			beforeSnapshotter := &Snapshotter{
				StepName:   "before snapshot",
				KubeConfig: kubeConfig,
			}
			afterSnapshotter := &Snapshotter{
				StepName:   "after snapshot",
				KubeConfig: kubeConfig,
			}

			builder = builder.
				Add(beforeSnapshotter).
				Add(Script{
					Input: Inline{
						FileName: testScriptName,
						Value:    testCase.testScript,
					},
				}).
				Defer(Script{
					Input: Inline{
						FileName: cleanupScriptName,
						Value:    testCase.cleanupScript,
					},
				}).
				Defer(SnapshotValidator{
					Before: beforeSnapshotter,
					After:  afterSnapshotter,
				})

			if testCase.parent != "" {
				if childList, hasChildren := parentChildMap[testCase.parent]; hasChildren {
					for _, childTestCase := range childList {
						childPath := childTestCase.path
						childTestScriptName := childPath
						parentPathName := strings.TrimSuffix(path, testScriptName)
						if strings.HasPrefix(childPath, parentPathName) {
							childTestScriptName = strings.TrimPrefix(childTestScriptName, parentPathName)
						}

						builder = builder.AddChild(Script{
							Input: Inline{
								FileName: childTestScriptName,
								Value:    childTestCase.testScript,
							},
						}).DeferChild(Script{
							Input: Inline{
								FileName: strings.TrimSuffix(childTestScriptName, "test.sh") + cleanupScriptName,
								Value:    childTestCase.cleanupScript,
							},
						})
					}
				}
			}

			ctx.NewSubTest(path).Run(builder.Build())
		}
	}
}

// Helper functions

// testsForConfig returns the tests that match the given configuration.
func testsForConfig(config string) []TestCase {
	out := make([]TestCase, 0, len(testCases))
	var childrenSlice []TestCase

	for _, testCase := range testCases {
		if testCase.config == config {
			if testCase.childOf != "" {
				parentName := testCase.childOf
				childrenSlice = parentChildMap[parentName]
				childrenSlice = append(childrenSlice, testCase)
				parentChildMap[parentName] = childrenSlice
			} else {
				out = append(out, testCase)
			}
		}
	}

	for _, childrenSlice := range parentChildMap {
		sort.Slice(childrenSlice, func(i, j int) bool { return childrenSlice[i].order < childrenSlice[j].order })
	}

	return out
}

// split breaks down the test names specified into a slice.
// It receives a comma-separated string of test names that the user has
// specified from command line, and returns a slice of separated strings.
func split(testsAsString string) []string {
	return strings.Split(testsAsString, ",")
}

// getTemplateScript returns a script that automatically sources the
// snippets and some test utilities. It receives `testPath`, which is the
// path of the test script file to be run.
func getTemplateScript(template, testPath string) string {
	// Check for proper test cleanup
	splitPath := strings.Split(testPath, "/")
	splitPath[len(splitPath)-1] = snipsFileSuffix
	snipsPath := strings.Join(splitPath, "/")
	return fmt.Sprintf(template, defaultPath, snipsPath)
}

func getSnipsPath(testPath string) string {
	splitPath := strings.Split(testPath, "/")
	splitPath[len(splitPath)-1] = snipsFileSuffix
	snipsPath := strings.Join(splitPath, "/")

	return snipsPath
}

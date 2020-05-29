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
	// "errors"
	"flag"
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

var inst istio.Instance

// command line arguments
var testsToRun = flag.String("test", "all", "tests to be run")
var testEnv = flag.String("env", "kube", "environment for test")

func TestMain(m *testing.M) {
	flag.Parse()
	log.Println("Starting test doc(s):", *testsToRun)
	log.Println("Test environment:", *testEnv)

	var env environment.Name
	switch *testEnv {
	case "kube":
		env = environment.Kube
	case "native":
		env = environment.Native
	default:
		log.Fatalf("Test environment error: expecting 'kube' or 'native', got '%v'\n", *testEnv)
	}

	framework.
		NewSuite("doc_test", m).
		SetupOnEnv(env, istio.Setup(&inst, nil)).
		RequireEnvironment(env).
		Run()
}

func TestDocs(t *testing.T) {
	// traverse through content/ to find the matched tests
	testFileSuffix := "/test.sh"
	defer log.Println("Test finished")

	err := filepath.Walk(".",
		func(path string, info os.FileInfo, walkError error) error {
			if walkError != nil {
				return walkError
			}

			checkFile := strings.HasSuffix(path, testFileSuffix) &&
				(*testsToRun == "all" || strings.Contains(path, *testsToRun))
			if checkFile {
				success, err := runTestFile(path)
				if err != nil {
					log.Println(err)

				}
				if success {

				}
			}
			return nil
		},
	)
	if err != nil {
		log.Fatalln("Error occurred while traversing the directory:", err)
	}

	// aggregate results and report
}

func runTestFile(path string) (bool, error) {
	log.Println("Running:", path)

	// for each matched test, find `test.sh`, parse it into test and cleanup, then run test
	script, err := ioutil.ReadFile(path)
	if err != nil {
		return false, err
	}

	testCleanupSep := "#! cleanup"
	splitScript := strings.Split(string(script), testCleanupSep)
	if numParts := len(splitScript); numParts != 2 {
		err := fmt.Errorf(
			"Script parsing error: Expected two-part script separated by '%v', got %v part(s)",
			testCleanupSep, numParts,
		)
		return false, err
	}

	testScript := splitScript[0]
	cleanupScript := splitScript[1]

	// TODO: locate the line of error?
	t := new(testing.T)
	framework.
		NewTest(t).
		Run(istioio.NewBuilder(path).
			Add(istioio.Script{
				Input: istioio.Inline{
					FileName: "test.sh",
					Value:    testScript,
				},
			}).
			Defer(istioio.Script{
				Input: istioio.Inline{
					FileName: "cleanup.sh",
					Value:    cleanupScript,
				},
			}).
			Build())

	// report if test succeeds or files with logs

	return true, nil
}

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
	"flag"
	"fmt"
	"io/ioutil"
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
	fmt.Println("Starting test docs: " + *testsToRun)
	fmt.Println("env:", *testEnv)

	var env environment.Name
	switch *testEnv {
	case "kube":
		env = environment.Kube
	case "native":
		env = environment.Native
	default:
		fmt.Printf("Test environment error: expecting `kube` or `native`, get `%s`\n", *testEnv)
		return
	}

	framework.
		NewSuite("doctest", m).
		SetupOnEnv(env, istio.Setup(&inst, nil)).
		RequireEnvironment(env).
		Run()
}

func TestDocs(t *testing.T) {
	// 2. traverse through content/* to match the folder to be tested (or test all folders)
	testFileSuffix := "/test.sh"

	err := filepath.Walk(".",
		func(path string, info os.FileInfo, err error) error {
			checkFile := strings.HasSuffix(path, testFileSuffix) &&
				(*testsToRun == "all" || strings.Contains(path, *testsToRun))
			if checkFile {
				runTestFile(path)
			}
			return nil
		},
	)
	if err != nil {
		fmt.Printf("Failed to execute tests: %s", err)
	}

	// 3. for each matched folder, find `test.sh`, parse it into test and cleanup, then run test

	// 4. aggregate results and report
	fmt.Println("Test finished")
}

func runTestFile(path string) (bool, error) {
	fmt.Println("Running: " + path)

	script, err := ioutil.ReadFile(path)
	if err != nil {
		return false, err
	}

	testCleanupSep := "# cleanup"
	splitScript := strings.Split(string(script), testCleanupSep)
	if len(splitScript) != 2 {
		fmt.Println("Expected two-part script")
		return false, nil
	}

	testScript := splitScript[0]
	cleanupScript := splitScript[1]
	// fmt.Println(testScript[len(testScript)-100:])
	// fmt.Println(cleanupScript)

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

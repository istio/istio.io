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
	"bytes"
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"strings"

	"istio.io/istio/pkg/test/framework/resource/environment"
	"istio.io/istio/pkg/test/scopes"
)

const (
	testOutputDirEnvVar = "TEST_OUTPUT_DIR"
	kubeConfigEnvVar    = "KUBECONFIG"
)

var _ Step = Script{}

// Script is a test Step that executes a shell script.
//
// To simplify common tasks, the following environment variables are set when the script is executed:
//
//     - TEST_OUTPUT_DIR:
//         Set to the working directory of the current test. By default, scripts are run from this
//         directory. This variable is useful for cases where the execution `WorkDir` has been set,
//         but the script needs to access files in the test working directory.
//     - KUBECONFIG:
//         Set to the value from the test framework. This is necessary to make kubectl commands execute
//         with the configuration specified on the command line.
//
type Script struct {
	// Input for the parser.
	Input InputSelector

	// Shell to use when running the command. By default "bash" will be used.
	Shell string

	// WorkDir specifies the working directory when executing the script.
	WorkDir string

	// Env user-provided environment variables for the generated Command.
	Env map[string]string
}

func (s Script) run(ctx Context) {
	input := s.Input.SelectInput(ctx)
	content, err := input.ReadAll()
	if err != nil {
		ctx.Fatalf("failed reading command input %s: %v", input.Name(), err)
	}

	// Generate the body of the command.
	commandLines := []string{"source ${REPO_ROOT}/tests/util/verify.sh"}
	lines := strings.Split(content, "\n")
	for index := 0; index < len(lines); index++ {
		commandLines = append(commandLines, lines[index])
	}

	// Merge the command lines together.
	command := strings.TrimSpace(strings.Join(commandLines, "\n"))

	// Now run the command...
	scopes.CI.Infof("Running command script %s", input.Name())

	// Copy the command to workDir.
	_, fileName := filepath.Split(input.Name())
	if err := ioutil.WriteFile(path.Join(ctx.WorkDir(), fileName), []byte(command), 0644); err != nil {
		ctx.Fatalf("failed copying command %s to workDir: %v", input.Name(), err)
	}

	// Get the shell.
	shell := s.Shell
	if shell == "" {
		shell = "bash"
	}

	// Create the command.
	cmd := exec.Command(shell)
	cmd.Dir = s.getWorkDir(ctx)
	cmd.Env = s.getEnv(ctx)
	cmd.Stdin = strings.NewReader(command)

	// Run the command and get the output.
	output, err := cmd.CombinedOutput()

	// Copy the command output from the script to workDir
	outputFileName := fileName + "_output.txt"
	if err := ioutil.WriteFile(filepath.Join(ctx.WorkDir(), outputFileName), bytes.TrimSpace(output), 0644); err != nil {
		ctx.Fatalf("failed copying output for command %s: %v", input.Name(), err)
	}

	if err != nil {
		ctx.Fatalf("script %s returned an error: %v. Output:\n%s", input.Name(), err, string(output))
	}
}

func (s Script) getWorkDir(ctx Context) string {
	if s.WorkDir != "" {
		// User-specified work dir for the script.
		return s.WorkDir
	}
	return ctx.WorkDir()
}

func (s Script) getEnv(ctx Context) []string {
	// Start with the environment for the current process.
	e := os.Environ()

	// Copy the user-specified environment (if set) and add the k8s config.
	customVars := map[string]string{
		// Set the output dir for the test.
		testOutputDirEnvVar: ctx.WorkDir(),
	}
	ctx.Environment().Case(environment.Kube, func() {
		customVars[kubeConfigEnvVar] = ctx.KubeEnv().Settings().KubeConfig[0]
	})
	for k, v := range s.Env {
		customVars[k] = v
	}

	// Append the custom vars  to the list.
	for name, value := range customVars {
		e = append(e, fmt.Sprintf("%s=%s", name, value))
	}
	return e
}

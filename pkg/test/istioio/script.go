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
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"strings"
	"time"

	"istio.io/istio/pkg/log"
	"istio.io/istio/pkg/test/framework"
	"istio.io/istio/pkg/test/scopes"
)

const (
	testOutputDirEnvVar = "TEST_OUTPUT_DIR"
	testDebugFile       = "TEST_DEBUG_FILE"
	kubeConfigEnvVar    = "KUBECONFIG"
)

// Logging scope for the script output.
var scriptLog = log.RegisterScope("script", "output of test scripts")

var _ Step = Script{}

// Script is a test Step that executes a shell script.
//
// To simplify common tasks, the following environment variables are set when the script is executed:
//
//   - TEST_OUTPUT_DIR:
//     Set to the working directory of the current test. By default, scripts are run from this
//     directory. This variable is useful for cases where the execution `WorkDir` has been set,
//     but the script needs to access files in the test working directory.
//   - TEST_DEBUG_FILE:
//     Set to the file where debugging output will be written.
//   - KUBECONFIG:
//     Set to the value from the test framework. This is necessary to make kubectl commands execute
//     with the configuration specified on the command line.
type Script struct {
	// Input for the parser.
	Input Input

	// Shell to use when running the command. By default "bash" will be used.
	Shell string

	// WorkDir specifies the working directory when executing the script.
	// By default, the test workdir will be used.
	WorkDir string

	// Env user-provided environment variables for the generated Command.
	Env map[string]string
}

func (s Script) Name() string {
	return s.Input.Name()
}

func (s Script) run(ctx framework.TestContext) {
	startTime := time.Now()
	command, err := s.Input.ReadAll()
	if err != nil {
		ctx.Fatalf("failed reading command input %s: %v", s.Name(), err)
	}

	defer func() {
		scopes.Framework.Infof("Finished running command script %s. Elapsed time: %fs",
			s.Name(), time.Since(startTime).Seconds())
	}()
	scopes.Framework.Infof("Running command script %s", s.Name())

	// Copy the command to workDir.
	_, fileName := filepath.Split(s.Name())
	if err := os.WriteFile(path.Join(ctx.WorkDir(), fileName), []byte(command), 0o644); err != nil {
		ctx.Fatalf("failed copying command %s to workDir: %v", s.Name(), err)
	}

	// Get the shell.
	shell := s.Shell
	if shell == "" {
		shell = "bash"
	}

	// Create the command.
	cmd := exec.Command(shell)
	cmd.Dir = s.getWorkDir(ctx)
	cmd.Env = s.getEnv(ctx, fileName)
	cmd.Stdin = strings.NewReader(command)

	// Output will be streamed to logs as well as to the output file (to be written to disk)
	outputFileName := filepath.Join(ctx.WorkDir(), fileName+"_output.txt")
	outputFile, err := os.Create(outputFileName)
	if err != nil {
		ctx.Fatalf("failed creating output file for command %s: %v", s.Name(), err)
	}
	writer := newWriter(outputFile)
	defer func() {
		_ = writer.Flush()
		_ = outputFile.Close()
	}()
	cmd.Stdout = writer
	cmd.Stderr = writer

	// Run the command.
	if err := cmd.Run(); err != nil {
		ctx.Fatalf("error running script %s: %v. Check output file for details: %s",
			s.Name(), err, outputFileName)
	}
}

type writer struct {
	delegate  *bufio.Writer
	logWrites bool
}

func (w *writer) Write(p []byte) (n int, err error) {
	if w.logWrites {
		scriptLog.Debug(strings.TrimSpace(string(p)))
	}
	return w.delegate.Write(p)
}

func (w *writer) Flush() error {
	return w.delegate.Flush()
}

func newWriter(outputFile *os.File) *writer {
	return &writer{
		delegate:  bufio.NewWriter(outputFile),
		logWrites: scriptLog.DebugEnabled(),
	}
}

func (s Script) getWorkDir(ctx framework.TestContext) string {
	if s.WorkDir != "" {
		// User-specified work dir for the script.
		return s.WorkDir
	}
	return ctx.WorkDir()
}

func (s Script) getEnv(ctx framework.TestContext, fileName string) []string {
	// Start with the environment for the current process.
	e := os.Environ()

	// Copy the user-specified environment (if set) and add the k8s config.
	customVars := map[string]string{
		// Set the output dir for the test.
		testOutputDirEnvVar: ctx.WorkDir(),
	}
	customVars[testDebugFile] = filepath.Join(ctx.WorkDir(), fileName+"_debug.txt")
	customVars[kubeConfigEnvVar] = getKubeConfig(ctx)

	for k, v := range s.Env {
		customVars[k] = v
	}

	// Append the custom vars  to the list.
	for name, value := range customVars {
		e = append(e, fmt.Sprintf("%s=%s", name, value))
	}
	return e
}

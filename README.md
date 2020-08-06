# 🔬 `@spec`

Simple Shell Specifications.

---

> - Small
> - Flexible
> - Simply BASH

---

Download the [latest version](https://github.com/bx-sh/spec.sh/archive/v0.2.3.tar.gz)

```sh
$ PATH="$PATH:spec/bin"

$ spec --version
spec version 0.2.3
```

---

## Shell Specifications

```sh
# [ my-file.spec.sh ]

@spec.one_equals_one() {
  [ 1 -eq 1 ]
}

@spec.one_equals_two() {
  [ 1 -eq 2 ]
}
```

```sh
$ spec my-file.spec.sh

[OK] one equals one
[FAIL] one equals two

Tests passed. 1 passed. 1 pending.
```

---

> ### Related Projects
>
> - ☑️ [`assert.sh`](https://github.com/bx-sh/assert.sh) - provides `assert [ 1 -eq 1 ]` syntax
> - 🧐 [`expect.sh`](https://github.com/bx-sh/expect.sh) - provides `expect 1 toEqual 1` syntax

---

#### Basics

- [Spec syntax](#foo)
- [Setup and teardown](#foo)
- [Pending tests](#foo)
- [Shared code](#foo)

#### Command-Line `spec`

- [Running Tests](#foo)
- [Running certain tests](#foo)
- [Printing test names](#foo)
- [Configuration files](#foo)
- [Fail fast](#foo)

#### Customization

- [Pre-defined variables](#foo)
- [Custom test definitions](#foo)
- [Custom setup and teardown](#foo)
- [Extending configuration](#foo)
- [Wrapping tests](#foo)
- [Custom test output](#foo)
- [Extending the CLI](#foo)

---

# Basics

## Spec syntax

Specs (or tests) are defined as simple BASH functions:

```sh
@spec.file_should_exist() {
  local expected_file_path="my-file.txt"
  [ -f "$expected_file_path" ]
}
```

#### ✅ Passing Specs

A spec will **`[PASS]`** when the function is run and returns a non-zero return code:

- ```sh
  @spec.this_spec_will_pass() {
    # ... something something ...
    return 0
  }
  ```

#### ❌ Failing Specs

A spec will **`[FAIL]`** when the function is run and either of these conditions occur:

- (a) The function exits with a non-zero exit code, e.g. **`exit 1`**
  ```sh
  @spec.this_spec_will_fail() {
    # ... something something ...
    exit 1
    # ... something something ...
  }
  ```
- (b) The the function returns a non-zero exit code, e.g. **`return 1`**
  ```sh
  @spec.this_spec_will_also_fail() {
    # ... something something ...
    return 1
  }
  ```

ℹ️ BASH functions implicitly return the return code of the last command run in the function:

- It is common to write specs so the final command is used to determine if the spec will pass
  ```sh
  @spec.verify_that_a_file_exists() {
    local expected_file="my-file.txt"
    [ -f "$expected_file" ]
  }
  ```
- This is functionally the same as the following example:
  ```sh
  @spec.verify_that_a_file_exists() {
    local expected_file="my-file.txt"
    [ -f "$expected_file" ]
    return $?
  }
  ```

## Setup and teardown

## Pending tests

## Shared code

---

---

# Command-Line `spec`

# Customization

---

### Supports most commonly used test vocabulary

```sh
##
# These are all supported by default
##

@setup() { :; }
@before() { :; }

@teardown() { :; }
@after() { :; }

@setupFixture() { :; }
@beforeAll() { :; }

@teardownFixture() { :; }
@afterAll() { :; }

@test.<test_name_here>() { :; }
@spec.<test_name_here>() { :; }
@it.<test_name_here>t() { :; }
@example.<test_name_here>() { :; }

@xtest.<test_name_here>() { :; }
@xspec.<test_name_here>() { :; }
@xit.<test_name_here>() { :; }
@xexample.<test_name_here>() { :; }
@pending.<test_name_here>() { :; }
```

---

### Or bring your own DSL

```sh
# spec.config.sh

spec.specFunctionPrefixes() {
  echo test
}

spec.setupFunctionNames() {
  echo config
}

spec.teardownFunctionNames() {
  echo cleanup
}
```

```sh
# my-file.spec.sh

config() {
  : # this will run before each test (like @setup does)
}

cleanup() {
  : # and this will run (like @teardown does)
}

testIChangedTheNamingConventions() {
  : # cool, any function that starts with 'test' runs now
}

testThisIsMuchMoreToMyLiking() {
  : # that sure was easy to customize
}
```

---

### Prefer tests to fail if any command returns non-zero?

```sh
# spec.config.sh

spec.runTest() {
  set -e
   ___spec___.runTest "$@"
  set +e
}
```

---

### Implement your own test output

```sh
# spec.config.sh

spec.displayTestResult() {
  local functionName="$3" # actual function name
  local name="$2"         # function name without prefix
                          # implement spec.getTestDisplayName() to generate yourself
  local status="$3"       # PASS or FAIL or PENDING
  local stdout="$4"       # STDOUT from the test (includes output from @setup and @teardown)
  local stderr="$5"       # STDERR from the test (includes output from @setup and @teardown)

  echo "[$status] $name"

  [ "$status" = "$failed" ] && [ -n "$stdout" ] && echo -e "[STDOUT]\n$stdout"
  [ "$status" = "$failed" ] && [ -n "$stderr" ] && echo -e "[STDERR]\n$stderr"
}

spec.displayTestsSummary() {
  local status="$1" # PASS or FAIL
  local total="$2"
  local passed="$3"
  local failed="$4"
  local pending="$5"

  echo "$status. $total total tests. $passed passed, $failed failed, $pending unimplemented."
}
```

### Configuration

```sh
# Given a $1 function name (without prefix)
# return a formatted name, e.g. replace _ with ' '
spec.getTestDisplayName() {
  echo "${1/_/ }"
}

# Return list of function prefixes which designate
# a function as a test that should be executed
spec.specFunctionPrefixes() {
  echo @test. test @spec.
}

##
# For all of these, if you want to call the default
# implementation, just call `___spec___.[function name]`
##

# Example showing how to *extend* existing list
spec.specFunctionPrefixes() {
  echo myPrefix $(___spec___.specFunctionPrefixes)
}

# Prefixes which designate a function as a 'pending'
# test which is not yet implemented (and is not run)
spec.pendingFunctionPrefixes

# List names of functions which will be run before
# and after each test is run (setup/teardown)
spec.setupFunctionNames
spec.teardownFunctionNames

# List names of functions which will be run before
# and after each test file is run (setupFixure/teardownFixture)
spec.setupFixtureFunctionNames
spec.teardownFixtureFunctionNames

# Return a list of filenames which will be automatically detected
# sourced. Defaults include specHelper.sh and spec.config.sh.
# The whole file tree is searched (parent directories).
spec.helperFilenames
```

### Display / Lifecycle Hooks

```
spec.loadHelpers
spec.beforeFile
  spec.displayTestsBanner
    spec.displayRunningTest
      spec.runTest
    spec.displayTestResult
  spec.displayTestsSummary
spec.afterFile
```

### Nitty Gritty

- `spec -e [regex name matcher]` will only run matching test cases (_matcher runs on function name without prefix_)
- `spec -f` or `spec --fast-fail` or `spec --fail-fast` won't run additional test files after one reports a failure
- `spec -c [config.sh]` sources provided file before test file is sourced (_runs before helper files are sourced_)
- Each individual test file provided to `spec` is sourced in a separate process
- Each test case within the file is run in a subshell and its STDOUT/STDERR recorded and exit code checked
- `setupFixture` and `teardownFixture` _do not_ run in a subshell, they run in the main process of the given test file
- To 'extend' any part of the interface, define `spec.[fn]` and use `___spec___.[fn] "$@"` to call default function
- Each test (including the test function, setup, and teardown functions) has access to the following variables:
  - `SPEC_FUNCTION` - name of the test function currently being run
  - `SPEC_NAME` - display name of current test (from getTestDisplayName)
  - `SPEC_FILE` - path of current file being run
  - `SPEC_DIR` - path of current working directory

specs._.private.init.initializeSpecs() {
  ## ### initializeSpecs
  ##
  ## 🕵️ `store private init initializeSpecs`
  ##
  ## This is the very first block of code which runs the first time the `specs`
  ## function is executed (immediately when running `specs` as a binary).
  ##
  ## - Configures default configation variables with default values (via [`loadDefaultConfigVariables`](#loadDefaultConfigVariables))
  ##   - This loads any configuration values which were provided via environment variables, including registered Extensions
  ## - Initializes all Extensions registered via environment variables.
  ## - Invokes configuration file loading (_this can be extended or overriden_)
  ##
  ## #### 👩‍💻 Implementation Details
  ##
  ## - Sets the `SPECS_INITIALIZED` variable equal to the current time when the `specs` function was first initialized.
  ## - Sets the `SPECS_VERSION` variable to the current version of `specs`
  ##
  ## | | Parameter description |
  ## |-|------------|
  ## | `$@` | _No parameters_ |
  ##
  ## | | Return value | |
  ## |-|------------|
  ## | `$?` | _No explicit return_ |
  ##
  SPECS_INITIALIZED="$(date +"%T.%3N")"
  SPECS_VERSION="0.6.0"
  specs -- private init loadDefaultConfigVariables
  # specs -- extensions initAll
  # ^--- NOTE extensions will get init called TWICE if they provided themselves as environment variables. After configFile loading, we init AGAIN
}
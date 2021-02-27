## # `caseEsacCompiler.sh`
##
## Compile multiple .sh files into a single file with a single top-level
## function and multiple commands and subcommands.
##
## - Every directory represents a `case`/`esac`
## - Every `.sh` file represents a `case` option
##
## ## Usage
##
## ```sh
## caseEsacCompiler compile myFunction output.sh my/dir/of/source/files/
## ```
##
## If the source file contains this text anywhere, it will be replaced:
##
## | Text | Replacement |
## |------|-------------|
## | `CASE_COMMAND_ESAC` | This command name, e.g. for `myFunction foo bar` this will be `bar` |
## | `CASE_FULL_COMMAND_ESAC` | The full command name, e.g. for `myFunction foo bar` this will be `myFunction foo bar` |
## | `CASE_PARENT_COMMAND_ESAC` | The parent command name, e.g. for `myFunction foo bar` this will be `myFunction foo` |
## | `CASE_FUNCTION_ESAC` | The top-level function name, e.g. for `myFunction foo bar` this will be `myFunction` |
##
caseEsacCompiler() {
  case "$1" in

    ## ## `caseEsacCompiler` `compile`
    ##
    ## | | Parameters |
    ## |-|------------|
    ## | `$1` | `compile` |
    ## | `$2` | The name of the top-level function to generate. All subcommands will be run through this top-level function. |
    ## | `$3` | The name of the source file to output. Will contain one function with any number of commands and subcommands. |
    ## | `$4` | The root path of command files. Used to determine the depth of subcommands to generate. |
    ##
    compile)
      local topLevelFunctionName="$2"
      local outputFilePath="$3"
      local commandFilesRootPath="$4"

      # Go through the commands and, for each command, find its children and generate the text for them!
      local sourceFileContent="$topLevelFunctionName() {
$( caseEsacCompiler _caseEsacForDir 1 "$commandFilesRootPath" "$commandFilesRootPath" "$topLevelFunctionName" )
}
"
      echo "$sourceFileContent" > "$outputFilePath"
      ;;

    ## ## `caseEsacCompiler` `_loadSourceFile`
    ##
    ## > 🕵️ Private
    ##
    ## Return the source code for the given source file (to put into this item's case/esac statement)
    ##
    ## | | Parameters |
    ## |-|------------|
    ## | `$1` | `_loadSourceFile` |
    ## | `$2` | Full command name associated with this source file, e.g. `theFunction subCommand thisCommand` |
    ## | `$3` | Full path to this source file |
    ##
    _loadSourceFile)
      local fullCommandName="$2"
      local commandName="${fullCommandName##* }"
      local parentCommandName="${fullCommandName% *}"
      local functionName="${fullCommandName# *}"
      local sourceFile="$3"

      local sourceFileContent="$(<"$sourceFile")"
      sourceFileContent="${sourceFileContent//CASE_COMMAND_ESAC/$commandName}"
      sourceFileContent="${sourceFileContent//CASE_FULL_COMMAND_ESAC/$fullCommandName}"
      sourceFileContent="${sourceFileContent//CASE_PARENT_COMMAND_ESAC/$parentCommandName}"
      sourceFileContent="${sourceFileContent//CASE_FUNCTION_ESAC/$functionName}"

      if echo "$sourceFileContent" | head -1 | grep "() {" &>/dev/null
      then
        sourceFileContent="$( echo -e "$sourceFileContent" | tail -n +2 | head -n -1 )"
      fi
      # Update the argument numbers based on the number of parent commands
      # $1 is expected to be the first argument
      # this will break with over 20 arguments
      # we increment the code's argument number by N where N = the parent command count (minus one - not counting the top level function which doesn't offset)
      local offset="${fullCommandName//[^ ]}"
      offset="${#offset}"
      local argumentNumber=20
      while [ $argumentNumber -gt 0 ]
      do
        local replacement="$(( $argumentNumber + $offset ))"
        sourceFileContent="${sourceFileContent//\$$argumentNumber/\$$replacement}"
        sourceFileContent="${sourceFileContent//\${$argumentNumber/\${$replacement}"
        : $(( argumentNumber -- ))
      done

      echo -e "$sourceFileContent"
      ;;

    ## ## `caseEsacCompiler` `_caseEsacForDir`
    ##
    ## > 🕵️ Private
    ##
    ## Generate and output the text for the case/esac code for the given directory of files:
    ##
    ## | | Parameters |
    ## |-|------------|
    ## | `$1` | `_caseEsacForDir` |
    ## | `$2` | Number representing the depth of this command, where the top-level function depth is 1, the next subcommand depth is 2, and so on. |
    ## | `$3` | The directory to search for files and folders to convert into `case`/`esac` cases and individiaul options. |
    ## | `$4` | The root path of command files. Used to determine the depth of subcommands to generate. |
    ## | `$5` | The name of the top-level function. |
    ##
    _caseEsacForDir)
      local commandDepth="$2"
      local commandsDirectoryPath="$3"
      local rootCommandsDirectoryPath="$4"
      local topLevelFunctionName="$5"
      local indentation=""
      local i=0
      while [ $i -lt $commandDepth ]
      do
        indentation="$indentation  "
        : $(( i++ ))
      done
      echo -e "${indentation}case \"\$$commandDepth\" in"
      local commandFileOrSubcommandDirectory
      for commandFileOrSubcommandDirectory in $commandsDirectoryPath/*
      do
        local fullCommandName="${commandFileOrSubcommandDirectory/"$rootCommandsDirectoryPath"}"
        fullCommandName="${fullCommandName#/}"
        fullCommandName="${fullCommandName%.sh}"
        fullCommandName="$topLevelFunctionName ${fullCommandName//// }"

        local commandName="${commandFileOrSubcommandDirectory##*/}"
        commandName="${commandName%.sh}"
        echo "${indentation}  $commandName)"
        if [ -d "$commandFileOrSubcommandDirectory" ]
        then
          caseEsacCompiler _caseEsacForDir "$(( $commandDepth + 1 ))" "$commandFileOrSubcommandDirectory" "$rootCommandsDirectoryPath" "$topLevelFunctionName" | sed "s/^/$indentation/"
        elif [ -f "$commandFileOrSubcommandDirectory" ]
        then
          caseEsacCompiler _loadSourceFile "$fullCommandName" "$commandFileOrSubcommandDirectory" | sed "s/^/$indentation    /"
        fi
        echo -e "\n${indentation}      ;;"
      done
      echo "  *)"
      local subCommandName="${commandsDirectoryPath/"$rootCommandsDirectoryPath"}"
      subCommandName="${subCommandName#/}"
      subCommandName="${subCommandName//// }"
      if [ $commandDepth = 1 ]
      then
        if [ -f "$commandsDirectoryPath/.index.sh" ]
        then
          caseEsacCompiler _loadSourceFile "$topLevelFunctionName" "$commandsDirectoryPath/.index.sh" | sed "s/^/$indentation    /"
        else
          echo "    echo \"Unknown '$topLevelFunctionName' command: \$$commandDepth\" >&2"
        fi
      else
        local subCommandFolder="${commandFileOrSubcommandDirectory%/*}"
        if [ -f "$subCommandFolder/.index.sh" ]
        then
          caseEsacCompiler _loadSourceFile "$topLevelFunctionName $subCommandName" "$subCommandFolder/.index.sh" | sed "s/^/$indentation    /"
        else
          echo "    echo \"Unknown '$topLevelFunctionName $subCommandName' command: \$$commandDepth\" >&2"
        fi
      fi
      echo "    return 1"
      echo "    ;;"
      echo "${indentation}esac"
      ;;

    *)
      echo "Unnknown 'caseEsacCompiler' command: '$1'" >&2
      return 1
      ;;
  esac
}
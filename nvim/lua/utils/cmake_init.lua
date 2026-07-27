local M = {}

function M.setup_project()
  local gcc_path = vim.fn.exepath "arm-none-eabi-gcc"
  if gcc_path == "" then gcc_path = "/opt/homebrew/bin/arm-none-eabi-gcc" end

  local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  local lists_file = "CMakeLists.txt"
  local presets_file = "CMakePresets.json"

  if vim.fn.filereadable(lists_file) == 0 then
    local lists_content = {
      "cmake_minimum_required(VERSION 3.20)",
      ("project(%s C ASM)"):format(project_name),
      "",
      "set(CMAKE_EXPORT_COMPILE_COMMANDS ON)",
      "",
      "if(NOT DEFINED MSPM0_SDK_PATH)",
      "    if(DEFINED ENV{MSPM0_SDK_PATH})",
      "        set(MSPM0_SDK_PATH $ENV{MSPM0_SDK_PATH})",
      "    else()",
      '        message(FATAL_ERROR "MSPM0_SDK_PATH target variable is missing.")',
      "    endif()",
      "endif()",
      "",
      "include_directories(",
      "    ${MSPM0_SDK_PATH}/source",
      "    ${MSPM0_SDK_PATH}/source/third_party/CMSIS/Core/Include",
      "    ${MSPM0_SDK_PATH}/source/ti/devices/msp/mspm0g1x0x_g3x0x",
      "    ./firmware/inc",
      ")",
    }
    vim.fn.writefile(lists_content, lists_file)
    vim.notify("Generated " .. lists_file, vim.log.levels.INFO)
  end

  if vim.fn.filereadable(presets_file) == 0 then
    local presets_content = {
      "{",
      '  "version": 3,',
      '  "configurePresets": [',
      "    {",
      '      "name": "default",',
      '      "displayName": "Default Config",',
      '      "binaryDir": "${sourceDir}/build",',
      '      "generator": "Ninja",',
      '      "cacheVariables": {',
      '        "CMAKE_BUILD_TYPE": "Debug",',
      ('        "CMAKE_C_COMPILER": "%s"'):format(gcc_path),
      "      }",
      "    }",
      "  ]",
      "}",
    }
    vim.fn.writefile(presets_content, presets_file)
    vim.notify("Generated " .. presets_file, vim.log.levels.INFO)
  end

  vim.cmd "terminal cmake -B build"
end

return M

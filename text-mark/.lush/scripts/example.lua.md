# .lush/scripts/example.lua

```lua
--[[
Copyright (c) 2024, Lance Borden
All rights reserved.

This software is licensed under the BSD 3-Clause License.
You may obtain a copy of the license at:
https://opensource.org/licenses/BSD-3-Clause

Redistribution and use in source and binary forms, with or without
modification, are permitted under the conditions stated in the BSD 3-Clause
License.

THIS SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY WARRANTIES,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
]]

-- This file is a demo of all of the commands Lunar Shell has in its Lua API
-- the Lua file itself is the executable unit so all code is run line by line

-- All Lua specific tools still work here too. Functions, loops, conditionals,
-- tables, Lua's standard library, etc are all available to integrate with Lunar Shell

print("Welcome to Lunar Shell scripting")

-- command line args can be passed to lua programs
-- done like so: example.lua arg1 arg2 ...
-- args can be read using the global args tables
if args ~= nil then
	print("Printing args:")
	for i = 1, #args do
		print(args[i])
	end
end

-- exec can be used to run any command line prompt
-- this method is much more native than using os.execute and is the recommended function
-- it also returns a boolean on if the command executed successfully
if lush.exec('echo "hello world"\n') then
	print("echo worked properly")
end

-- debug mode can be used to log execution of commands
lush.debug(true) -- enters debug
lush.exec('echo "echo in debug mode"')
lush.debug(false) -- exits debug

-- getcwd returns the current working directory
local cwd = lush.getcwd()
print(cwd)

-- exec also supports piping
-- this comment will get grepped since it says hello
lush.cd("~/.lush/scripts")
lush.exec('cat "example.lua" | grep "hello" | sort | uniq')
lush.cd(cwd)

-- exists allows you to check if a file or directory exists
if lush.exists("~/.lush/scripts/example.lua") then
	print("example.lua exists")
end

-- isFile and isDir check if a path points to a file or a directory
if lush.isFile("~/.lush/scripts/example.lua") then
	print("example.lua is a file")
end

if not lush.isDirectory("~/.lush/scripts/example.lua") then
	print("example.lua is not a directory")
end

-- you can also check if a file is readable/writeable
if lush.isReadable("~/.lush/scripts/example.lua") then
	print("example.lua is readable")
end
if lush.isWriteable("~/.lush/scripts/example.lua") then
	print("example.lua is writeable")
end

-- you can fetch the most recently executed command in history
print("Most recent history: " .. lush.lastHistory())

-- you can also fetch history at a certain index in the past (1 being most recent)
print("Most recent history indexed: " .. lush.getHistory(1))

-- you can set environment variables using putenv
lush.setenv("EXAMPLE", "Lunar Shell Example")

-- you can get an environment variable using getenv
print("Value of EXAMPLE: " .. lush.getenv("EXAMPLE"))

-- you can unset an environment variable with unsetenv
lush.unsetenv("EXAMPLE")

-- you can get the current terminal width(cols) and height(rows)
-- this function is very useful if you want to make certain kinds of custom prompts in your init.lua
print("Terminal Columns: " .. lush.termCols())
print("Terminal Rows: " .. lush.termRows())

-- the glob function scans the current working directory for files with the given extension and returns
-- them as an array of strings
local textFiles = lush.glob("txt")
if textFiles ~= nil then
	print("Printing txt files:")
	for i = 1, #textFiles do
		print(textFiles[i])
	end
end

-- the exit function is used to make the program quit in the case of an error
print("making an error with lush.exit()")
lush.exit()

```

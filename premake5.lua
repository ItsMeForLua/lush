workspace("lush")
configurations({ "Debug", "Release" })

project("lush")
kind("ConsoleApp")
language("C")
targetdir("bin/%{cfg.buildcfg}/lush")

local lua_inc_path = "/usr/include"
local lua_lib_path = "/usr/lib"

-- Check for specific Lua versions if needed, common on Arch
if os.findlib("lua5.4") then
    lua_inc_path = "/usr/include/lua5.4"
    links({ "lua5.4" })
elseif os.findlib("lua5.3") then
    lua_inc_path = "/usr/include/lua5.3"
    links({ "lua5.3" })
else
    links({ "lua" })
end

-- Ensure all necessary include directories are present.
-- This tells the compiler where to find "compat-5.3.h".
includedirs({
    lua_inc_path,
    "lib/hashmap",
    "lib/compat53/c-api"
})

libdirs({ lua_lib_path })

-- Compile all necessary source files, including compat-5.3.c
files({
    "src/**.h",
    "src/**.c",
    "lib/hashmap/**.h",
    "lib/hashmap/**.c",
    "lib/compat53/c-api/**.h",
    "lib/compat53/c-api/**.c"
})

-- Define LUA_COMPAT53_LIB for the whole project. This is the correct
-- way to ensure the function prototype is visible AND the function
-- implementation is not static.
defines({ 'LUSH_VERSION="0.3.2"', "LUA_COMPAT53_LIB" })

filter("configurations:Debug")
defines({ "DEBUG" })
symbols("On")

filter("configurations:Release")
defines({ "NDEBUG" })
optimize("On")

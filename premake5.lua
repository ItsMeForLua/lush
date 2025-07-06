workspace("lush")
configurations({ "Debug", "Release" })

project("lush")
kind("ConsoleApp")
language("C")
targetdir("bin/%{cfg.buildcfg}/lush")

local lua_inc_path = "/usr/include"
local lua_lib_path = "/usr/lib"

if os.findlib("lua5.4") then
    lua_inc_path = "/usr/include/lua5.4"
    lua_lib_path = "/usr/lib/5.4"
    links({ "lua5.4" })
else
    links({ "lua" })
end

-- This tells the compiler where to find the header.
includedirs({ lua_inc_path, "lib/hashmap", "lib/compat53/c-api" })
libdirs({ lua_lib_path })

-- *** THE FIX ***
-- We are removing the compat-5.3 files from this list because we will
-- now include the .c file directly inside lush.c. This avoids all
-- the complex linker and preprocessor definition issues.
files({
    "src/**.h",
    "src/**.c",
    "lib/hashmap/**.h",
    "lib/hashmap/**.c"
})

-- We only need the basic version define now.
defines({ 'LUSH_VERSION="0.3.2"' })


filter("configurations:Debug")
defines({ "DEBUG" })
symbols("On")

filter("configurations:Release")
defines({ "NDEBUG" })
optimize("On")

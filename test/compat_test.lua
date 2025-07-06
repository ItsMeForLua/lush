-- test/compat_test.lua
print("--- Testing Lua 5.1 compatibility ---")

local my_table = { "a", "b", "c" }

-- This will FAIL on a standard Lua 5.2+ interpreter without the compat layer.
-- It should PASS now that luaopen_compat53(L) is being called.
local x, y, z = unpack(my_table)

assert(x == "a", "unpack failed for first element")
assert(y == "b", "unpack failed for second element")
assert(z == "c", "unpack failed for third element")

print("Global 'unpack' function works correctly. Compatibility layer is active!")
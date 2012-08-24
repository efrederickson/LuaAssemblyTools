These are the tests for Lua Assembly Toolkit.

They won't run out-of-box.
Add this to make them run (To your interpreter/test runner):
package.path = "../src/?;../src/?.lua;" .. package.path
#!/usr/bin/env luajit
local util = require "libs.util"
log = require "libs.logger"
json = require "libs.JSON"()

local version = "0.0.1-1"

local stringarg = ""
for i = 1, #arg do -- A hacky way to avoid executable name
    stringarg = stringarg .. " " .. arg[i]
end
stringarg = string.sub(stringarg, 2)
local args, values = util.argparse(stringarg)

log:init(true, true, true, table.hasleftinright({"d", "debug"}, args), table.hasleftinright({"v", "verbose"}, args))
log:d("Logger", "Debug log enabled")
log:v("Logger", "Verbose log enabled")
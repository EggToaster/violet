#!/usr/bin/env luajit
---@diagnostic disable: need-check-nil
local util = require "libs.util"
json = require "libs.JSON"()
http = require "socket.http"
local version = "0.0.1-1"
local violetdir = "/var/violet"
local softwaredir = "/"

local stringarg = ""
for i = 1, #arg do -- A hacky way to avoid executable name
    stringarg = stringarg .. " " .. arg[i]
end
stringarg = string.sub(stringarg, 2)
local args, values = util.argparse(stringarg)

log = {}
function log.v(_, _, _) end -- Dirty fix to disable JSON errors

function os.capture(cmd, raw)
    local f = assert(io.popen(cmd, 'r'))
    local s = assert(f:read('*a'))
    f:close()
    if raw then return s end
    s = string.gsub(s, '^%s+', '')
    s = string.gsub(s, '%s+$', '')
    s = string.gsub(s, '[\n\r]+', ' ')
    return s
end

if table.haskey(args, "cfgdir") then
    violetdir = args["cfgdir"]
end
if table.haskey(args, "installdir") then
    softwaredir = args["installdir"]
end

local perms = false
if os.capture("whoami") == "root" then
    perms = true
end

if not perms then
    print "No right to execute commands"
    --os.exit(1, true)
    print "Continuing"
end

function download(url, path)
    local body, code = http.request(url)
    if not body then return false end
    local f = assert(io.open(path, "wb"))
    f:write(body)
    f:close()
    return true
end

function exists(file)
    local status, err, code = os.rename(file, file)
    if not status then
       if code == 13 then -- Permission denied
          return true
       end
    end
    return status, err
 end

-- Init
if not exists(violetdir) then
    os.execute("mkdir "..violetdir)
end
if not exists(violetdir.."/repo") then
    os.execute("mkdir "..violetdir.."/repo")
end
if not exists(violetdir.."/data") then
    os.execute("mkdir "..violetdir.."/data")
end
if not exists(violetdir.."/repo/cache") then
    os.execute("mkdir "..violetdir.."/repo/cache")
end

if values[1] == "repo" then
    if values[2] == "add" then
        local name = values[3]
        local url = values[4]
        local f = io.open(violetdir.."/repo/"..name, "w")
        f:write(url.." enabled")
        f:close()
    elseif table.hasleftinright({"delete", "remove"}, values[2]) then
        if values[3] then
            os.remove(violetdir.."/repo/cache/"..values[3])
            
        else
            print("repo remove/delete [repo/file name]")
        end
    end
end

--download("http://pbs.twimg.com/media/CCROQ8vUEAEgFke.jpg", softwaredir.."/test.jpg")

local f, err = io.open("/unopenable", "r")

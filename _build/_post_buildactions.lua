-- Author: Alan Litz
-- GitHub: https://github.com/Dangleworks/Unified-Modules
-- Workshop: n/a
--
-- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--      By Nameous Changey (Please retain this notice at the top of the file as a courtesy; a lot of effort went into the creation of these tools.)

-- This file is called after the build process finished
-- Can be used to copy data into the game, trigger deployments, etc.
-- Regular lua - you have access to the filesystem etc. via LBFilesystem
-- Recommend using LBFilepath for paths, to keep things easy

require("script")
require("_build.lib.stringutil")
require("_build.lib.fsutil")
local xml2lua = require("_build.lib.xml2lua")
local handler_factory = require("_build.lib.xmlhandler.tree")

local vehicles = {}
local playlists = {}
local loc_count = 0
local com_count = 0

-- XML Parsing
function ParseXMLFile(file)
    local handler = handler_factory:new()
    local parser = xml2lua.parser(handler)
    parser:parse(file:read("a"))
    return handler
end

function loadComponentVehicle(module_name, c)
    if c._attr.component_type == '3' then
        io.write("\n")
        local orig_file_name = c._attr.vehicle_file_name
        -- get file name from component
        local pathparts = string.split(orig_file_name, "/")
        local filename = pathparts[#pathparts]
        print("--> attempting to load "..module_name.." vehicle "..filename)
        filename = string.gsub(filename, "vehicle", module_name)

        local file = io.open(string.format("./vehicle_xml/%s", filename), "r")
        if file ~= nil then
            table.insert(vehicles, ParseXMLFile(file))
            c._attr.vehicle_file_name = string.format("vehicle_%d.xml", #vehicles)
            print("--> loaded "..filename)
        else
            print("--> unable to load "..filename)
        end
    end
end

-- Load base XML Template
io.write("[INFO] loading base XML template...")
local basefile = io.open("./_build/lib/playlist_template.xml", "r")
local playlist_base = ParseXMLFile(basefile).root
io.write(" Done\n")

function processModuleLocation(module_name, location)
    loc_count = loc_count + 1
    location._attr.id = loc_count

    if location.components and location.components.c then
        if location.components.c[1] then

            for idx, c in ipairs(location.components.c) do
                com_count = com_count + 1
                c._attr.id = com_count
                loadComponentVehicle(module_name, c)
            end
        else
            com_count = com_count + 1
            location.components.c._attr.id = com_count
            loadComponentVehicle(module_name, location.components.c)
        end
    end

    table.insert(playlist_base.playlist.locations.locations.l, location)
end

function writeXMLFile(file_path, table_data)
    local xml = xml2lua.toXml(table_data)
    local file = io.open(file_path, "w")
    
    if not file then
        print(string.format("[ERROR] failed to open %s for writing", file_path))
        return
    end

    file:write(xml)
    file:close()
end

-- Load module XML Files
for k, _ in pairs(modules) do
    local file = io.open(string.format("./playlist_xml/%s.xml", k), "r")
    if file ~= nil then
        io.write("[INFO] loading playlist "..k..".xml...")
        playlists[k] = ParseXMLFile(file)
        io.write(" Done\n")
    else
        print("[INFO] no playlist file found for "..k)
    end
end

playlist_base.playlist.locations.locations.l = {}

for mod, plist in pairs(playlists) do
    io.write("[INFO] processing "..mod.." XML data...")
    if plist.root.playlist.locations.locations.l[1] then
        for _, l in ipairs(plist.root.playlist.locations.locations.l) do
            processModuleLocation(mod, l)
        end
    else
        processModuleLocation(mod, plist.root.playlist.locations.locations.l)
    end
    io.write(" Done\n")
end

print("[INFO] packaging addon")
-- create packaging folder
fsutil.removeDirectory("out/_intermediate/packaged")
fsutil.createDirectory("out/_intermediate/packaged")
-- copy in final script.lua
fsutil.copy("out/_intermediate/script.lua", "out/_intermediate/packaged")
-- write playlist.xml and all vehicle_N.xml files
writeXMLFile("out/_intermediate/packaged/playlist.xml", playlist_base)

-- repeat for release
fsutil.removeDirectory("out/release/packaged")
fsutil.createDirectory("out/release/packaged")
fsutil.copy("out/release/script.lua", "out/release/packaged")
writeXMLFile("out/release/packaged/playlist.xml", playlist_base)

xml2lua.printable(playlist_base)

print(string.format("[INFO] Consolidated %d locations, %d components, and %d vehicles", loc_count, com_count, #vehicles))
print("Post build steps complete")

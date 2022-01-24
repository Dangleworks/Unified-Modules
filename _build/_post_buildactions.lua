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
local inspect = require("_build.lib.inspect")
local slaxml = require("_build.lib.slaxdom")

local playlists = {}
local loc_count = 0
local com_count = 0
local vehicles = {}

-- XML Parsing
function ParseXMLFile(file)
    return slaxml:dom(file:read("a"), { simple = true })
end

function getFirstMatchingElement(doc, elname)
    -- loop through each element in the doc
    for idx, kid in ipairs(doc.kids) do
        -- return firt matching element
        if kid.type == 'element' and kid.name == elname then
            return kid
        end
    end
end

function getFirstMatchingAttribute(attr_name, el)
    for idx, attr in ipairs(el.attr) do
        if attr.name == attr_name then
            return attr
        end
    end
end

function processLocationVehicles(module_name, l)
    local components = getFirstMatchingElement(l, "components")
    local vehicle_components = {}
    for idx, kid in ipairs(components.kids) do
        if kid.type=="element" and kid.name=="c" then
            local ctype = getFirstMatchingAttribute("component_type", kid)
            if ctype.value == "3" then
                local vehicle_file_name = getFirstMatchingAttribute("vehicle_file_name", kid)
                -- get file name from component
                local pathparts = string.split(vehicle_file_name.value, "/")
                local filename = pathparts[#pathparts]
                -- filename will be "moduleName_#.xml" when looking for module vehicle file
                filename = string.gsub(filename, "vehicle", module_name)

                -- make sure the file exists
                local file = io.open(string.format("./vehicle_xml/%s", filename), "r")
                if file ~= nil then
                    io.close(file)
                    -- update the component and add it to the list for later copy
                    table.insert(vehicles, filename)
                    vehicle_file_name.value = string.format("vehicle_%d.xml", #vehicles)
                end
            end
        end
    end
end

function processModuleLocation(module_name, l, locations)
    loc_count = loc_count + 1
    local idattr = getFirstMatchingAttribute("id", l)
    idattr.value = loc_count
    processLocationVehicles(module_name, l)
    table.insert(locations.kids, l)
end

function writeXMLFile(file_path, table_data)
    --local xml = xml2lua.toXml(table_data)
    local xml = slaxml:xml(table_data)
    local file = io.open(file_path, "w")
    
    if not file then
        print(string.format("[ERROR] failed to open %s for writing", file_path))
        return
    end

    file:write(xml)
    file:close()
end

-- Load base XML Template
io.write("[INFO] loading base XML template...")
local basefile = io.open("./_build/lib/playlist_template.xml", "r")
local playlist_base = ParseXMLFile(basefile)
local playlist_base_playlist = getFirstMatchingElement(playlist_base, "playlist")
local playlist_base_locations1 = getFirstMatchingElement(playlist_base_playlist, "locations")
local playlist_base_locations2 = getFirstMatchingElement(playlist_base_locations1, "locations")
io.write(" Done\n")

-- Load module XML Files
for idx, mod in ipairs(modules) do
    for k, _ in pairs(mod) do
        local file = io.open(string.format("./playlist_xml/%s.xml", k), "r")
        if file ~= nil then
            io.write("[INFO] loading playlist "..k..".xml...")
            playlists[k] = ParseXMLFile(file)
            io.write(" Done\n")
        else
            print("[INFO] no playlist file found for "..k)
        end
    end
end

for mod, plist in pairs(playlists) do
    io.write("[INFO] processing "..mod.." XML data...")
    local playlist = getFirstMatchingElement(plist, 'playlist')
    local loc1 = getFirstMatchingElement(playlist, 'locations')
    local loc2 = getFirstMatchingElement(loc1, 'locations')

    for idx, kid in ipairs(loc2.kids) do
        if kid.name == 'l' and kid.type =='element' then
            processModuleLocation(mod, kid, playlist_base_locations2)
        end
    end
    io.write(" Done\n")
end

-- Package intermediate
print("[INFO] packaging addon")
fsutil.removeDirectory("out/_intermediate/packaged")
fsutil.createDirectory("out/_intermediate/packaged")
fsutil.copy("out/_intermediate/script.lua", "out/_intermediate/packaged")
writeXMLFile("out/_intermediate/packaged/playlist.xml", playlist_base)

-- Package release
fsutil.removeDirectory("out/release/packaged")
fsutil.createDirectory("out/release/packaged")
fsutil.copy("out/release/script.lua", "out/release/packaged")
writeXMLFile("out/release/packaged/playlist.xml", playlist_base)

-- Package vehicles
for idx, filename in ipairs(vehicles) do
    -- _intermediate
    fsutil.copy(string.format("vehicle_xml/%s", filename), "out/_intermediate/packaged/")
    fsutil.rename(string.format("out/_intermediate/packaged/%s", filename), string.format("vehicle_%d.xml", idx))
    -- release
    fsutil.copy(string.format("vehicle_xml/%s", filename), "out/release/packaged/")
    fsutil.rename(string.format("out/release/packaged/%s", filename), string.format("vehicle_%d.xml", idx))
end

--print(inspect.inspect(playlist_base, {depth=10}))

print(string.format("[INFO] Consolidated %d locations, %d components, and %d vehicles", loc_count, com_count, #vehicles))
print("Post build steps complete")

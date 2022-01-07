-- Author: <Authorname> (Please change this in user settings, Ctrl+Comma)
-- GitHub: <GithubLink>
-- Workshop: <WorkshopLink>
--
-- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--      By Nameous Changey (Please retain this notice at the top of the file as a courtesy; a lot of effort went into the creation of these tools.)

-- This file is called after the build process finished
-- Can be used to copy data into the game, trigger deployments, etc.
-- Regular lua - you have access to the filesystem etc. via LBFilesystem
-- Recommend using LBFilepath for paths, to keep things easy


require("script")
local xml2lua = require("_build.lib.xml2lua")
local handler_factory = require("_build.lib.xmlhandler.tree")

-- XML Parsing


function ParseXMLFile(file)
    local handler = handler_factory:new()
    local parser = xml2lua.parser(handler)
    parser:parse(file:read("a"))
    return handler
end

local playlists = {}

-- Load base XML Template
io.write("[INFO] loading base XML template...")
local basefile = io.open("./_build/lib/playlist_template.xml", "r")
local playlist_base = ParseXMLFile(basefile).root
io.write(" Done\n")

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

local loc_count = 0
local com_count = 0
for mod, plist in pairs(playlists) do
    io.write("[INFO] processing "..mod.." XML data...")
    for idx, l in ipairs(plist.root.playlist.locations.locations.l) do
        loc_count = loc_count + 1
        l._attr.id = loc_count
        if l.components and l.components.c then
            -- c will be an array if there are multiple components
            if l.components.c[1] then
                for idx, c in ipairs(l.components.c) do
                    com_count = com_count + 1
                    c._attr.id = com_count 
                end
            else
                com_count = com_count + 1
                l.components.c._attr.id = com_count 
            end
        end
        table.insert(playlist_base.playlist.locations.locations.l, l)
    end
    io.write(" Done\n")
end

print(string.format("Consolidated %d locations and %d components", loc_count, com_count))
xml2lua.printable(playlist_base)

--TODO: process component vehicles (component_type=3) vehicle_file_name
-- this probably requires that vehicles are processed first so final file names are already
-- created before the playlist xml is generated
--TODO: write consolidated playlist.xml
print("Post build steps complete")



--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey
-- Callbacks for handling the build process
-- Allows for running external processes, or customising the build output to how you prefer
-- Recommend using LifeBoatAPI.Tools.FileSystemUtils to simplify life
--- Runs when the build process is triggered, before any file has been built
--- Provides an opportunity for any code-generation etc.
---@param builder Builder           builder object that will be used to build each file
---@param params MinimizerParams    params that the build process usees to control minification settings
---@param workspaceRoot Filepath    filepath to the root folder of the project
function onLBBuildStarted(builder, params, workspaceRoot)
    print("Build started - see the build actions in _build/_buildactions.lua")
end

--- Runs just before each file is built
---@param builder Builder           builder object that will be used to build each file
---@param params MinimizerParams    params that the build process usees to control minification settings
---@param workspaceRoot Filepath    filepath to the root folder of the project
---@param name string               "require"-style name of the script that's about to be built
---@param inputFile Filepath        filepath to the file that is about to be built
function onLBBuildFileStarted(builder, params, workspaceRoot, name, inputFile)

end

--- Runs after each file has been combined and minimized
--- Provides a chance to use the output, e.g. sending files into vehicle XML or similar
---@param builder Builder           builder object that will be used to build each file
---@param params MinimizerParams    params that the build process usees to control minification settings
---@param workspaceRoot Filepath    filepath to the root folder of the project
---@param name string               "require"-style name of the script that's been built
---@param inputFile Filepath        filepath to the file that was just built
---@param outputFile Filepath       filepath to the output minimized file
---@param combinedText string       text generated by the require-resolution process (pre-minified)
---@param minimizedText string      final text output by the process, ready to go in game (post-minified)
function onLBBuildFileComplete(builder, params, workspaceRoot, name, inputFile, outputFile, originalText, combinedText,
    minimizedText)
    -- Example: copy MyScript.lua into the game addon folder
    -- if name == "MyScript" then
    --     local missionScriptPath = LifeBoatAPI.Tools.Filepath:new("C:/Users/.../Stormworks/missions/MyMission/script.lua")
    --     LifeBoatAPI.Tools.FileSystemUtils.writeAllText(missionScriptPath, minimizedText)
    -- end
end

--- Runs after the build process has finished for this project 
--- Provides a chance to do any final build steps, such as moving files around
---@param builder Builder           builder object that will be used to build each file
---@param params MinimizerParams    params that the build process usees to control minification settings
---@param workspaceRoot Filepath    filepath to the root folder of the project
function onLBBuildComplete(builder, params, workspaceRoot)
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
        return slaxml:dom(file:read("a"), {
            simple = true
        })
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
            if kid.type == "element" and kid.name == "c" then
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
        -- local xml = xml2lua.toXml(table_data)
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
                io.write("[INFO] loading playlist " .. k .. ".xml...")
                playlists[k] = ParseXMLFile(file)
                io.write(" Done\n")
            else
                print("[INFO] no playlist file found for " .. k)
            end
        end
    end

    for mod, plist in pairs(playlists) do
        io.write("[INFO] processing " .. mod .. " XML data...")
        local playlist = getFirstMatchingElement(plist, 'playlist')
        local loc1 = getFirstMatchingElement(playlist, 'locations')
        local loc2 = getFirstMatchingElement(loc1, 'locations')

        for idx, kid in ipairs(loc2.kids) do
            if kid.name == 'l' and kid.type == 'element' then
                processModuleLocation(mod, kid, playlist_base_locations2)
            end
        end
        io.write(" Done\n")
    end

    -- Package intermediate
    print("[INFO] packaging addon")
    fsutil.removeDirectory("_build/out/_intermediate/packaged")
    fsutil.createDirectory("_build/out/_intermediate/packaged")
    fsutil.copy("_build/out/_intermediate/script.lua", "_build/out/_intermediate/packaged")
    writeXMLFile("_build/out/_intermediate/packaged/playlist.xml", playlist_base)

    -- Package release
    fsutil.removeDirectory("_build/out/release/packaged")
    fsutil.createDirectory("_build/out/release/packaged")
    fsutil.copy("_build/out/release/script.lua", "_build/out/release/packaged")
    writeXMLFile("_build/out/release/packaged/playlist.xml", playlist_base)

    -- Package vehicles
    for idx, filename in ipairs(vehicles) do
        -- _intermediate
        fsutil.copy(string.format("vehicle_xml/%s", filename), "_build/out/_intermediate/packaged/")
        fsutil.rename(string.format("_build/out/_intermediate/packaged/%s", filename), string.format("vehicle_%d.xml", idx))
        -- release
        fsutil.copy(string.format("vehicle_xml/%s", filename), "_build/out/release/packaged/")
        fsutil.rename(string.format("_build/out/release/packaged/%s", filename), string.format("vehicle_%d.xml", idx))
    end

    -- print(inspect.inspect(playlist_base, {depth=10}))

    print(string.format("[INFO] Consolidated %d locations, %d components, and %d vehicles", loc_count, com_count,
        #vehicles))
    print("Post build steps complete")

    print("Build Success")
    print("See the _build/out/release/ folder for your minimized code")

    -- Copy packaged files to the addon folder
    fsutil.copy("_build/out/release/packaged/*", "C:/Users/Alan/AppData/Roaming/Stormworks/data/missions/UnifiedModules/")
end


fsutil = {}
fsutil.isWindows = function()
    if package.config:sub(1,1) == "\\" then
        return true
    end

    return false
end

fsutil.createDirectory = function(path)
    if fsutil.isWindows() then
        path = string.gsub(path, "/", "\\")
        os.execute(string.format('mkdir "%s"', path))
    else
        os.execute(string.format('mkdir -p "%s"', path))
    end
end

fsutil.copy = function(filepath, newpath)
    if fsutil.isWindows() then
        filepath = string.gsub(filepath, "/", "\\")
        newpath = string.gsub(newpath, "/", "\\")
        os.execute(string.format('xcopy "%s" "%s" /Y', filepath, newpath))
    else
        os.execute(string.format('cp "%s" "%s"', filepath, newpath))
    end
end

fsutil.removeDirectory = function(path, recursive)
    if fsutil.isWindows() then
        path = string.gsub(path, "/", "\\")
        os.execute(string.format('rmdir "%s" /s /q', path))
    else
        os.execute(string.format('rm -r "%s"', path))
    end
end

fsutil.rename = function(filepath, newname)
    if fsutil.isWindows() then
        filepath = string.gsub(filepath, "/", "\\")
        os.execute(string.format('rename %s %s', filepath, newname))
    else
        error("Not implemented")
    end
end
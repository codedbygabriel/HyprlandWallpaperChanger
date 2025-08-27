local lfs = require("lfs")
local path = string.format("/home/%s/Wallpapers", os.getenv("USER"))

local wallpapersList = {}

local function getLoadedWallpapers()
	-- uses the output of hyprctl do define the initial table
	local cmd = "hyprctl hyprpaper listloaded"
	local res = io.popen(cmd, "r")
	for line in res:lines("l") do
		table.insert(wallpapersList, line)
	end
end

local function isInTheTable(wallpaperTable, value)
	-- Lua does not have a freaking not in operator :P
	for key, valueTable in pairs(wallpaperTable) do
		if valueTable == value then
			return true
		end
	end
	return false
end

local function loadWallpapers(wallpaperTable)
	-- Final step, loads wallpaper to memory
	for value, wallpaper in pairs(wallpaperTable) do
		local cmd = string.format("hyprctl hyprpaper preload %s", wallpaper)
		local res = os.execute(cmd)
	end
end

local function getWallpapersFromDir()
	-- gets wallpaper from dir and compares them to the already loaded (avoids duplicates)
	for fileName in lfs.dir(path) do
		if fileName ~= "." and fileName ~= ".." then
			local newPath = path .. "/" .. fileName
			if isInTheTable(wallpapersList, newPath) == false then
				local cmd = string.format("echo 'preloading file... %s'", fileName)
				os.execute(cmd)
				table.insert(wallpapersList, newPath)
			end
		end
	end
end

local function setWallpaper(pathToWallpaper)
	local cmd = string.format('hyprctl hyprpaper wallpaper "eDP-1,%s"', pathToWallpaper)
	os.execute(cmd)
end

local function randomizeWallpaper(wallpaperTable)
	local index = math.random(1, #wallpaperTable)
	local selectedWallpaper = wallpaperTable[index]
	setWallpaper(selectedWallpaper)
end

local function selectWallpaper(wallpaperTable)
	for index, value in pairs(wallpaperTable) do
		io.write(index .. ")" .. " - " .. value .. "\n")
	end
	io.write("Feeling Lucky? Go with a 'random' then.\n")

	io.write("From 1 - " .. #wallpaperTable .. " select your wallpaper! => ")
	local indexSelected = io.read()
	if indexSelected == "random" then
		randomizeWallpaper(wallpaperTable)
	else
		setWallpaper(wallpaperTable[indexSelected])
	end
end

getLoadedWallpapers()
getWallpapersFromDir()
loadWallpapers(wallpapersList)
selectWallpaper(wallpapersList)

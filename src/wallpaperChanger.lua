local lfs = require("lfs")
local path = string.format("/home/%s/Wallpapers", os.getenv("USER"))

local wallpapersList = {}
local monitorList = {}

local function findMonitor()
	-- As it says, finds the correct nomenclature to the monitors, and adds them to monitorList.
	local cmd = "hyprctl monitors all"
	local res = io.popen(cmd)

	for output in res:lines("l") do
		local startIndex, _ = string.find(output, "Monitor")

		if startIndex ~= nil then
			local dump = {} -- dump array, for sake of my sanity
			for line in string.gmatch(output, "%S+") do -- equivalent of split i guess
				table.insert(dump, line)
			end
			table.insert(monitorList, dump[2]) -- Gets the hdmi/edpi/etc
		end
	end
end

local function getLoadedWallpapers()
	-- Gets already loaded in memory wallpapers and inserts them into the list
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

local function setWallpaper(pathToWallpaper, isOnDaemon)
	if isOnDaemon == nil then
		isOnDaemon = false
	end

	local cmd = ""
	if #monitorList > 1 then
		for index, currentMonitor in ipairs(monitorList) do
			if not isOnDaemon then
				io.write(string.format("Apply %s to %s? (y/n) =>", pathToWallpaper, currentMonitor))
				local res = io.read()

				if res == "y" then
					cmd = string.format('hyprctl hyprpaper wallpaper "%s,%s"', currentMonitor, pathToWallpaper)
					os.execute(cmd)
				end
			else
				cmd = string.format('hyprctl hyprpaper wallpaper "%s,%s"', currentMonitor, pathToWallpaper)
				os.execute(cmd)
			end
		end
	else
		cmd = string.format('hyprctl hyprpaper wallpaper "%s,%s"', monitorList[1], pathToWallpaper)
		os.execute(cmd)
	end
end

local function randomizeWallpaper(wallpaperTable, isOnDaemon)
	local index = math.random(1, #wallpaperTable)
	local selectedWallpaper = wallpaperTable[index]
	if not isOnDaemon then
		setWallpaper(selectedWallpaper, isOnDaemon)
	else
		setWallpaper(selectedWallpaper)
	end
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
		setWallpaper(wallpaperTable[tonumber(indexSelected)])
	end
end

local function switchWallpaperDaemon(wallpaperTable, time)
	local startTime = os.clock()
	local timer = time
	randomizeWallpaper(wallpaperTable, true)

	while true do
		local passedTime = os.clock() - startTime
		if passedTime > timer then
			print(passedTime)
			startTime = os.clock()
			passedTime = 0
			randomizeWallpaper(wallpaperTable, true)
		end
	end
end

findMonitor()
getLoadedWallpapers()
getWallpapersFromDir()
loadWallpapers(wallpapersList)
--selectWallpaper(wallpapersList)
switchWallpaperDaemon(wallpapersList, 20)

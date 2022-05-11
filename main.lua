local unpack = table.unpack or unpack
local Map = require("map")

local waitForInput = true
local status = ""

local function sleep(s)
	local ntime = os.clock() + s
	repeat until os.clock() > ntime
end

local function setStatus( txt )
	status = txt
	dump()
end

function init()
	local seed = os.time()
	math.randomseed(seed)
	-- print("seed: "..seed)
	
	map = Map.new(10,10)
	map:randomize() -- generate a random map

	mix()  -- check if any moves available
	dump() -- draw initial map state
	tick() -- wait for an input from user
end

-- parses input string
function parseInput( inputstr )
	if inputstr == "q" then
		os.exit()
	end

	local args = {}
	for str in string.gmatch(inputstr, "([^%s*]+)") do
		table.insert(args, str)
	end

	local _, tx,ty, dir = unpack(args)
	tx = tonumber(tx) 	-- if tx is nil still got nil
	ty = tonumber(ty) 	-- if ty is nil still got nil
	dir = tostring(dir) -- if dir is nil still got nil

	if tx and ty and dir then
		-- make cell coords valid for table indices
		tx = tx + 1
		ty = ty + 1

		-- get secod coordinates
		local nx = tx + ((dir == "r") and 1 or (dir == "l") and -1 or 0)
		local ny = ty + ((dir == "d") and 1 or (dir == "u") and -1 or 0)
		
		move( nx,ny, tx,ty )
		return
	end

	waitForInput = true
	setStatus("Wrong command! Try again")
	tick()
end

sleepTime = 0.5
function tick()
	if waitForInput then
		io.write("Make your turn: ")

		local var = io.read()
		if var then
			parseInput( var )
			waitForInput = false
		end

	else -- process game update
		local finished = map:collapse()
		if finished then
			local matches = {}
			map:getMatches(matches)

			-- clear matches if there any
			for i=1, #matches do
				map:clear( unpack(matches[i]) )
			end

			if #matches == 0 then
				-- setStatus("")
				waitForInput = true
			end
		else
			-- sleep for animation purposes
			sleep(sleepTime)
		end

		dump()
		tick()
	end
end

function move( x1,y1, x2,y2 )
	local success = map:swap(x1,y1, x2,y2)
	if success then
		local matches = {}
		map:getMatches(matches)

		if #matches > 0 then
			waitForInput = false
			setStatus( "Nice move! Processing it..." )
		else
			-- swap back because no new matches generated
			map:swap(x1,y1, x2,y2)
			setStatus("No new matches so try again!")
		end
	else
		-- user trying to switch same type of pieces
		-- or move piece out if bounds
		waitForInput = true
		setStatus("Can't move piece here! Try again")
	end
	mix()
	tick()
end

function mix()
	-- check for possible moves
	local count = map:getPossibleMatches()
	if count == 0 then
		print("Wow! There is no possible moves. Shuffling...")
		map:randomize()
	end
end

function dump()
	print("")
	-- os.execute("cls") -- clear console on Windows
	-- os.execute("clear") -- clear console on Unix

	local w,h = map:getDimensions()

	local header = "   "
	for i=0, w-1 do
		header = header .. " "..i
	end
	print(header)

	header = "  " .. string.rep("-", #header-1)
	print(header)

	local row_shape = "%d |" .. string.rep(" %s", w)
	for row=0, w-1 do
		print( string.format(row_shape, row, unpack(map:dumprow( row+1 ))) )
	end

	print(status)
end

init()
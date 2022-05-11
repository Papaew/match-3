local random = math.random
local unpack = table.unpack or unpack
local match_checks = require("checks")

local Map = {}
function Map.new( w,h )
	local self = {}

	-- returns new random ASCII character
	local function getNewChar()
		return string.char(math.random(65, 70))
	end

	-- checks if given coordinates are in range from 1 to mapsize
	local function is_coords_valid( x,y )
		return (x > 0 and x <= w) and (y > 0 and y <= h)
	end

	-- internal swap function
	local function swap( x1,y1, x2,y2 )
		if is_coords_valid(x1,y1) and is_coords_valid(x2,y2) then
			self[x1][y1], self[x2][y2] = self[x2][y2], self[x1][y1]
			return true
		end
		return false
	end

	-- clears certain area from x1,y1 to x2,y2
	function self:clear( x1,y1, x2,y2 )
		for x=x1, x2 do
			for y=y1, y2 do
				self[x][y] = 0
			end
		end
	end

	-- sets piece at coords
	function self:set( x,y, val )
		if not is_coords_valid(x,y) then return end
		self[x][y] = val
	end

	-- returns piece at given coors
	function self:get( x,y )
		if not is_coords_valid(x,y) then return -1 end -- out of bounds
		return self[x][y]
	end

	-- swaps two pieces
	function self:swap( x1,y1, x2,y2 )
		local v1 = self:get(x1,y1)
		local v2 = self:get(x2,y2)

		-- pieces are the same - no need to swap
		if v1 == v2 then return false end
		return swap( x1,y1, x2,y2 )
	end

	-- returns table of characters from a given row
	function self:dumprow( index )
		local row = {}
		for col=1, w do
			local char = self[col][index]
			table.insert(row, char == 0 and " " or char)
		end

		return row
	end

	-- refills the map with random characters
	-- checks that there are initial no matches
	function self:randomize()
		for col=1, w do
			self[col] = {}
			for row=1, h do
				local c3 = self:get(col, row-2)
				local c2 = self:get(col, row-1)

				local r3 = self:get(col-2, row)
				local r2 = self:get(col-1, row)

				local char
				local same = true
				while same do
					char = getNewChar() -- fill with ASCII char form A to F
					same = (char == c2 and char == c3) or (char == r2 and char == r3)
				end

				self[col][row] = char
			end
		end
	end

	-- collapses pieces hanging in air
	-- refills empty areas with new 
	-- returns state
	function self:collapse( )
		local counter = 0
		for col=1, w do

			local buff = {}
			local needToCollapse = false
			for row=1, h do

				local curr = self:get(col, row)
				if curr == 0 then
					-- fill an empty block with random char
					self:set( col, row, getNewChar() )
					counter = counter + 1; break

				else
					-- add full block in a buffer
					table.insert(buff, row)

					-- check if bottom block is empty
					local next = self:get(col, row+1)
					if next == 0 then
						needToCollapse = true
						counter = counter + 1; break
					end

				end
			end

			-- move down all blocks from the buffer
			if needToCollapse then
				for i=#buff, 1, -1 do
					swap(col, buff[i], col, buff[i]+1)
				end

				-- fill top empty cell that appears with a random character
				self:set(col, 1, getNewChar() )
			end
		end

		-- if counter more than 0 then there is still pieces potentially hangin on air
		-- in that case need to collapse again
		return counter == 0 
	end

	-- finds any matches
	-- returns table of rect coordinates (x1,y1, x2,y2)
	function self:getMatches( match_table )
		-- possible optimization: collect matches in table
		-- in one single pass instead of two

		local buff = {}
		for col = 1, w do
			for row=1, h do
				local v = self:get(col, row)
				local d = self:get(col, row+1)
				table.insert(buff, row)

				if v ~= d then
					if #buff >= 3 then
						local x1,y1 = col, buff[1]
						local x2,y2 = col, buff[#buff]
						table.insert(match_table, { x1,y1, x2,y2 })
					end
					buff = {}
				end
			end
		end

		for row=1, h do
			for col=1, w do
				local v = self:get(col, row)
				local d = self:get(col+1, row)
				table.insert(buff, col)

				if v ~= d then
					if #buff >= 3 then
						local x1,y1 = buff[1], row
						local x2,y2 = buff[#buff], row
						table.insert(match_table, { x1,y1, x2,y2 })
					end
					buff = {}
				end
			end
		end

		return match_table
	end

	-- returns possible match count
	function self:getPossibleMatches()
		local counter = 0

		for col = 1, w do
			for row=1, h do

				local curr = self:get(col, row)
				for i=1, #match_checks do
					local x1,y1, x2,y2 = unpack( match_checks[i] )

					local p1 = self:get(col + x1, row + y1)
					local p2 = self:get(col + x2, row + y2)

					-- we don't really need to check for all possible matches
					-- just add the first found match and break
					if curr == p1 and curr == p2 then
						counter = counter + 1; break
					end
				end
			end
		end

		return counter
	end

	-- returns map size
	function self:getDimensions()
		return w,h
	end

	return self
end

return Map
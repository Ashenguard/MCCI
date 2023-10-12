local utils = {}

function utils.file_exists(name)
	local f = io.open(name, "r")
	return f ~= nil and io.close(f)
 end
 

function utils.distance(pos1, pos2)
	local x = pos1.x - pos2.x
	local y = pos1.y - pos2.y
	local z = pos1.z - pos2.z

	return math.sqrt(math.pow(x, 2) + math.pow(y, 2) + math.pow(z, 2))
end

function utils.format_number(num)
    if num < 1000 then return num .. " " end
	
	num = math.floor(num / 100) / 10
	if num < 1000 then return num .. "K" end
	
	num = math.floor(num / 100) / 10
	if num < 1000 then return num .. "M" end
	
	num = math.floor(num / 100) / 10
	if num < 1000 then return num .. "B" end
	
	num = math.floor(num / 100) / 10
	return num .. "Q"
end

return utils
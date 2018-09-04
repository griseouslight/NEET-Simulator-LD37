
function minigame_load(x, y)
	-- minigameGroup = 0x10
	
	--GRAPHICS
	gameBG = love.graphics.newImage("assets/miniBG.png")
	gameCarImage = love.graphics.newImage("assets/miniCAR.png")
	gameObstacleImage = love.graphics.newImage("assets/miniOBST.png")


	minigame = {}
	minigame.x = x
	minigame.y = y
	minigame.width = gameBG:getWidth()
	minigame.height = gameBG:getHeight()
	minigame.speed = 150
	minigame.lose = false
	minigame.world = love.physics.newWorld(0, 0, false)

    minigame.world:setCallbacks(minigame_contact, minigame_endcontact, minigame_presolve, minigame_postsolve)

	row = {}
	row[1] = minigame.height/6
	row[2] = minigame.height/2
	row[3] = minigame.height - minigame.height/6


	--PHYSICS

	carBody = love.physics.newBody(minigame.world, minigame.width/3,row[2], "dynamic")
	carShape = love.physics.newRectangleShape(0, 0, gameCarImage:getWidth(), gameCarImage:getHeight())
	carFixture = love.physics.newFixture(carBody, carShape)
	carFixture:setUserData("car")

	obstacles = {}

	--SOUND
	moveSound = love.audio.newSource("assets/miniMOV.wav","static")
	miniDieSound = love.audio.newSource("assets/miniDIE.wav","static")


end
--[[
PATTERNS
001
010
011
100
101
110

]]

function minigame_draw()
	--SETUP ORIGIN
	love.graphics.push()
	love.graphics.translate(minigame.x, minigame.y)

	love.graphics.draw(gameBG, 0, 0)
	love.graphics.draw(gameCarImage, carBody:getX(),carBody:getY(), 0, 1, 1, gameCarImage:getWidth()/2, gameCarImage:getHeight()/2)

	if debug then 
		love.graphics.polygon("line", carBody:getWorldPoints(carShape:getPoints()))
	end

	for i,fixture in ipairs(obstacles) do
		local body = fixture:getBody()
		if debug then love.graphics.polygon("line", body:getWorldPoints(fixture:getShape():getPoints())) end 
		love.graphics.draw(gameObstacleImage, body:getX(), body:getY(), body:getAngle(), 1, 1,gameObstacleImage:getWidth()/2,gameObstacleImage:getHeight()/2)

	end

	--REVERT ORIGIN
	love.graphics.pop()
end

count = 0
function minigame_update(dt)
	count = count + dt
	minigame.world:update(dt)
	if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
	    carBody:setY(row[1])
	elseif love.keyboard.isDown("down") or love.keyboard.isDown("s") then
		carBody:setY(row[3])
	else
		carBody:setY(row[2])
	end


	for i, fixture in ipairs(obstacles) do
		local body = fixture:getBody()
		body:setX(body:getX() - (minigame.speed *dt))
		if body:getX() < 0 then
			table.remove(obstacles, i)
			fixture:destroy()
		end
	end


	if count > 2 then 
		spawnObst(math.random(1,6))
		count = 0
	end
end


function spawnObst(num)
	-- if debug then print("Spawning "..num) end
	if num == 1 then -- 001
		table.insert(obstacles,createObstacle(minigame.width,row[3]))
	elseif num == 2 then -- 010
		table.insert(obstacles,createObstacle(minigame.width,row[2]))
	elseif num == 3 then -- 011
		table.insert(obstacles,createObstacle(minigame.width,row[2]))
		table.insert(obstacles,createObstacle(minigame.width,row[3]))
	elseif num == 4 then -- 100
		table.insert(obstacles,createObstacle(minigame.width,row[1]))
	elseif num == 5 then -- 101
		table.insert(obstacles,createObstacle(minigame.width,row[1]))
		table.insert(obstacles,createObstacle(minigame.width,row[3]))
	elseif num == 6 then -- 110 
		table.insert(obstacles,createObstacle(minigame.width,row[1]))
		table.insert(obstacles,createObstacle(minigame.width,row[2]))

	end
end

function createObstacle(x, y)
	local body = love.physics.newBody(minigame.world,x,y, "dynamic")
	local shape = love.physics.newRectangleShape(0, 0, gameObstacleImage:getWidth(), gameObstacleImage:getHeight())
	local fixture = love.physics.newFixture(body, shape)

	fixture:setUserData("obstacle")

	return fixture
end


function minigame_contact(a, b,coll)
	item1 = a:getUserData()
	item2 = b:getUserData()
	-- print(item1 .. " " .. (item2 and item2 or "nil"))
	if (item1 == "car" and item2 == "obstacle") or (item2 == "car" and item1 == "obstacle") then 
		if debug then print(":C") end
		minigame.lose = true
		love.audio.play(miniDieSound)
	end
end

keys = {"w", "up", "s", "down"}
function minigame_keypressed(key, scancode, isrepeat)
	if minigame.lose then return end
	-- print('pressed'..key)
	for i, v in ipairs(keys) do
		if key == v then
			love.audio.play(moveSound)
		end
	end

end

function minigame_keyreleased(key, scancode)
	if minigame.lose then return end
	for i,v in ipairs(keys) do
		if key == v then
			love.audio.play(moveSound)
		end
	end

end

-- A "completely realistic" NEET Simulation game!
--
-- Written by Talon "griseouslight"
--


winWidth = 1280
winHeight = 720
debug = false

function love.load()
	require "minigame"

	pizzaScale = 10
	playerScale = 5
	doorScale = 20
	


	--WINDOW
	love.window.setMode(winWidth, winHeight)
	love.window.setTitle("NEET Simulator")

	math.randomseed(os.time())


	--GRAPHICS
	local font = love.graphics.newFont(8)
	font:setFilter("nearest", "nearest", 0)
	love.graphics.setFont(font)


	love.graphics.setDefaultFilter("nearest")
	
	pizzaImage = love.graphics.newImage("assets/pizza.png")
	pizzaEatenImage = love.graphics.newImage("assets/pizza_eaten.png")
	-- pizzaImage = pizzaEatenImage

	floorImage = love.graphics.newImage("assets/floorboard.png")
	doorImage = love.graphics.newImage("assets/door.png")

	playerImage = love.graphics.newImage("assets/player.png")
	tvImage = love.graphics.newImage("assets/TV.png")

	loseImage = love.graphics.newImage("assets/noob.png")

	--PHYSICS
	buildWorld()
	

	--SOUND
	dieSound = love.audio.newSource("assets/die.wav", "static")
	collideSound = love.audio.newSource("assets/collide.wav", "static")
	eatSound = love.audio.newSource("assets/eat.wav", "static")
	pickupSound = love.audio.newSource("assets/pickup.wav", "static")

	bgm = love.audio.newSource("assets/bgm.ogg")
	bgm:setLooping(true)
	bgm:play()
	musicplaying = true

end



function buildWorld()
	love.physics.setMeter(60)
	world  = love.physics.newWorld(0, 20*love.physics.getMeter(), true)
    world:setCallbacks(beginContact, endContact, preSolve, postSolve)
    world:setContactFilter(contactFilter)

	minigame_load(920,310)


	ground = love.physics.newBody(world, 0, 0, 'static')
	groundShape = love.physics.newRectangleShape(winWidth/2, winHeight, winWidth, 75)
	groundFixture = love.physics.newFixture( ground, groundShape)
	groundFixture:setUserData("boundary")

	leftwall = love.physics.newBody(world, 0, 0, 'static')
	leftShape = love.physics.newRectangleShape(0, 0,20,10000)
	leftFixture = love.physics.newFixture(leftwall, leftShape)
	leftFixture:setUserData("boundary")

	rightwall = love.physics.newBody(world, 0, 0, 'static')
	rightShape = love.physics.newRectangleShape(winWidth, 0,20,10000)
	rightFixture = love.physics.newFixture(rightwall, rightShape)
	rightFixture:setUserData("boundary")


	playerBody = love.physics.newBody(world, 1000, 520, "kinematic")
	playerShape = love.physics.newRectangleShape(0, 0, playerImage:getWidth()*playerScale/1.5, playerImage:getWidth()*playerScale/2) 
	playerFixture = love.physics.newFixture(playerBody, playerShape)
	playerFixture:setUserData("face")
	
	doorRect = love.physics.newRectangleShape(300+(doorImage:getWidth()*20)/2,500-(doorImage:getHeight()*20)/2, doorImage:getWidth()*20,doorImage:getHeight()*20)

	pizzaTable = {}
	pizzaTable2 = {}
	openDoor = false
	eaten = false
	holding = false
	lose = false
	score = 0
	doorTimer = 0
	loseString = ""

end


function reset()
	world:destroy()
	minigame.world:destroy()
	love.mouse.setGrabbed(false)
	love.mouse.setVisible(true)
	buildWorld()

end


function love.draw()
	--reset the color
	love.graphics.setColor(255, 255, 255)
	
	if lose then 

		
		love.graphics.setBackgroundColor(255, 255, 255)
		local loseScale = 5
		love.graphics.draw(loseImage, (winWidth/2) - (loseImage:getWidth()) * loseScale,  (winHeight/2) - (loseImage:getHeight()) * loseScale, 0, 5, 5)
		love.graphics.setColor(0, 0, 0)
		love.graphics.print("SCORE: "..score, 0, 0, 0, 10, 10)
		love.graphics.printf("Cause of Death:\n"..loseString.."\n(SPACE for another chance)",0, winHeight/2+10,winWidth/10 ,"center",0, 10, 10)

		return
	end



	love.graphics.setBackgroundColor(0, 0, 0)


	love.graphics.setColor(64, 128, 192)
	love.graphics.rectangle("fill", 0, 500, 1280, 720)

	love.graphics.setColor(64, 64, 96)
	love.graphics.rectangle("fill", 0, 0, 1280, 500)


	love.graphics.setColor(255, 255, 255)

	love.graphics.draw(floorImage,0,500,0,10,10)

	--debug
	if debug then
		love.graphics.polygon("line", ground:getWorldPoints(groundShape:getPoints()))
		love.graphics.polygon("line", ground:getWorldPoints(leftShape:getPoints()))
		love.graphics.polygon("line", ground:getWorldPoints(rightShape:getPoints()))
		love.graphics.polygon("line", playerBody:getWorldPoints(playerShape:getPoints()))	
	end



	--door
	if openDoor then love.graphics.setColor(0,0,0) end
	love.graphics.draw(doorImage, 300, 500, 0, 20, 20,0,10)
	if debug then love.graphics.polygon("line", doorRect:getPoints()) end
	-- love.graphics.draw(doorImage, doorShape:getX())

	love.graphics.setColor(255, 255, 255)

	--GAME
	minigame_draw()

	--TV
	love.graphics.draw(tvImage, 800, 550, 0, 10, 10, 0, tvImage:getHeight())

	--player
	love.graphics.draw(playerImage, playerBody:getX(), playerBody:getY(), playerBody:getAngle(), playerScale, playerScale, playerImage:getWidth()/2,playerImage:getWidth()/2)


	--pizzas
	for i,body in ipairs(pizzaTable) do
		if debug then love.graphics.polygon("line", body:getWorldPoints(pizzaTable2[i]:getPoints())) end

		love.graphics.draw(pizzaEatenImage, body:getX(), body:getY(), body:getAngle(), pizzaScale, pizzaScale,pizzaEatenImage:getWidth()/2,pizzaEatenImage:getHeight()/2)
	end

	if openDoor then
		love.graphics.setColor(0,0,0)
		love.graphics.polygon("line", doorRect:getPoints())
		local x1, y1, x2, y2 = doorRect:getPoints()

		if doorTimer > 6 then
			lose = true
			loseString = "Lack of Pizza"
		elseif doorTimer > 5 then
			love.graphics.print("(click)\n\t...", x1, 200, 0, 5, 5)
		elseif doorTimer > 4 then
			love.graphics.print("(click)\n\t..", x1, 200, 0, 5, 5)
		elseif doorTimer > 3 then
			love.graphics.print("(click)\n\t.", x1, 200, 0, 5, 5)
		end

		love.graphics.setColor(255,255,255)

	end
	--held pizza
	if newPizzaBody and not newPizzaBody:isDestroyed() then
		love.graphics.draw(eaten and pizzaEatenImage or pizzaImage, newPizzaBody:getX(), newPizzaBody:getY(), newPizzaBody:getAngle(), pizzaScale, pizzaScale,pizzaImage:getWidth()/2,pizzaImage:getHeight()/2)
		local x = playerBody:getX() - 20
		local y = playerBody:getY() + 20
		love.graphics.print(eaten and "outta my face." or "feed me!" , x, y, 0, 5, 5)
	end

	love.graphics.setColor(0, 0, 0)
	love.graphics.print("SCORE: "..score, 0, 0, 0, 10, 10)
end


lastMouse = {dt = 0, x = 0, y = 0}
mouseVX = 0
mouseVY = 0
function love.update(dt)
	if lose then
		love.mouse.setGrabbed(false)
		love.mouse.setVisible(true)
		openDoor = false
		eaten = false
		holding = false
		if love.keyboard.isDown("space") then reset() end
		if love.keyboard.isDown("escape") then love.event.push("quit") end 
		return
	end

	world:update(dt)
	doorTimer = doorTimer + dt
	if doorTimer > 3 then openDoor = true end

	if holding then
		newPizzaBody:setPosition(love.mouse.getX(), love.mouse.getY())
	end


	mouseVX = love.mouse.getX() - lastMouse.x
	mouseVY = love.mouse.getY() - lastMouse.y

	lastMouse.dt = dt
	lastMouse.x = love.mouse.getX()
	lastMouse.y = love.mouse.getY()

	if not lose then minigame_update(dt) end

	if minigame.lose then
		loseString = "Bad at Video Games"
		lose = true
	end

end

function love.mousepressed(x, y, button, istouch)
	if lose then return end
	if openDoor and not holding then
		if button == 1 then
			-- print("attempt to click")
			if doorRect:testPoint(0,0,0,x,y) then
				-- makePizza(x,y)
				newPizza()
				love.audio.play(pickupSound)
				love.mouse.setGrabbed(true)
				love.mouse.setVisible(false)
				openDoor = false
				doorTimer = 0
			end
		end
	end

end
function love.mousereleased(x, y, button, istouch)
	if lose then return end
	if holding then
		if eaten then
			love.mouse.setGrabbed(false)
			love.mouse.setVisible(true)
			makePizza()

			holding = false
		end

	end
end

function love.keypressed(key, scancode, isrepeat)
	minigame_keypressed(key, scancode, isrepeat)
end

function love.keyreleased(key, scancode)
	minigame_keyreleased(key, scancode)
end





-- COLLISION
function contactFilter(a, b)
	-- if item1 == "newPizza" or item2 == "newPizza" then return true end
	-- return false
	return true
end


function beginContact(a, b, coll)
	item1 = a:getUserData()
	item2 = b:getUserData()

 	if item1 == "face" or item2 == "face" then
 		if item1 == "newPizza" or item2 == "newPizza" then 
 			love.audio.play(eatSound)
 			eaten = true
 			return 
 		end
 		loseString = "Cardboard Asphyxiation"
 		lose = true
 	else
 		love.audio.play(collideSound)
 	end

end
 
function endContact(a, b, coll)
 
end
 
function preSolve(a, b, coll)
 
end
 
function postSolve(a, b, coll, normalimpulse, tangentimpulse)
 
end




function makePizza()

	table.insert(pizzaTable, newPizzaBody)
	if debug then table.insert(pizzaTable2, newPizzaShape) end

	newPizzaBody:setLinearVelocity(0,0)
	newPizzaBody:applyLinearImpulse(mouseVX*love.physics.getMeter(), mouseVY*love.physics.getMeter())

	newPizzaFixture:setUserData("pizza")
	--globals are ugly but whatever
	score = score + 1

	newPizzaBody = nil
	newPizzaShape = nil
	newPizzaFixture = nil

end

function newPizza()
	newPizzaBody = love.physics.newBody(world,love.mouse.getX(),love.mouse.getY(),"dynamic")
	newPizzaShape = love.physics.newRectangleShape(0, 0, pizzaImage:getWidth()*pizzaScale, pizzaImage:getHeight()*pizzaScale)
	newPizzaFixture = love.physics.newFixture(newPizzaBody, newPizzaShape)
	newPizzaFixture:setFriction(0.57)
	newPizzaFixture:setUserData("newPizza")
	newPizzaBody:setMassData(newPizzaShape:computeMass(1))
	eaten = false
	holding = true
end

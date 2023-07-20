pico-8 cartridge // http://www.pico-8.com
version 41
__lua__


function coll_tile(...)
	return false
end

function coll_leftwall(xoffset,y)
	for br in all(bricks) do
		if(br.x+br.width > 59+xoffset+bugtest) and (br.x+br.width < 67+xoffset) and br.infront then
			if(br.y > y-7 and br.y <= y) then --minus 1 fixes slides down walls
				br.canbecollider = true
				return true
			end
		end
	end
	return false
end

function coll_rightwall(xoffset,y)
	for br in all(bricks) do
		if(br.x > (64+xoffset)) and (br.x < (67+xoffset)) and br.infront then
			if(br.y >= y and br.y <= y+7) then 
				br.canbecollider = true
				return true
			end
		end
	end
	return false
end

function coll_floor(y)
	for br in all(bricks) do
		if(br.x+br.width > 60) and (br.x < 66) and br.infront then
			if(br.y > y+4 and br.y < y+8) then --if this isn't 8 then the side colliders dont work.
				br.canbecollider = true
				return true
			end
		end
	end
	return false
end

function coll_ceiling(y)
	for br in all(bricks) do
		if(br.x + br.width >= 60) and (br.x <= 66) and br.infront then
			if(br.y >= y-8 and br.y < y) then
				br.canbecollider = true
				return true
			end
		end
	end
	return false
end


function cameraheight(player)
	if(player.y+worldy <= 30) then
		worldy += flr(abs(player.y+30-worldy)/100)
	end

	if(player.y+worldy >= 80) then
		worldy -= flr(abs(player.y+80-worldy+128)/100)
	end
end

function createcharacter(x0, y0)
 local player = {
  -----------------------------
  --player starting variables--
  -----------------------------
  x = x0 or 60, --starting x coordinate
  y = y0 or 60, --startomg y coordinate
  framecounter = 0, --counter for animations
  speed = 0.4, --runspeed
  normalspeed = 0.2, --defines normal running speed
  runspeed = 0.3, --defines max run speed while holding run button
  rateofacceleration = 0.1, --determines how quickly to change between normal and run speed
  maxspeed = 0.2, -- max run speed used to calculate movement
  jumpingspeed = 3, --initial jumping speed
  velx = 0, --current speed on x axis
  vely = 0, --current speed on y axis
  jumping = false, --has the player started jumping (moving up)
  falling = false, --is the player falling (moving down)
  sprite = 144, --start sprite number
  moving = false, --is the player moving on x axis
  jumpreset = true, --lock to stop jumping again until ready
  stick = false, -- is the player sliding down a wall
  dontteleport = false,
  timer = 0, --general timer, used for pauses like on death or level complete
  removecontrol = false, --used to stop player input, like on level complete or death
  facing = "right",
  unstickcounter = 0, --used for the pause when pushing the opposite direction while stuck to a wall before falling off
  
  --------------------
  --player functions--
  --------------------

	--slows down the player to a stop
	stopping = function(self)
		if(not self.jumping and not self.falling) then
			self.velx /= 1.5
		else
			self.velx /= 1.2 --less drag if in air
		end
	 
		if ((self.velx > -0.05) and (self.velx < 0.05)) then
			self.velx = 0
		end
	end,

	----------------------------------
	-- function that governs all the player movement--
	-- starting with some controls, then dealing with y-axis
	-- then x-axis movement
	---------------------------------

	move = function(self)

		--check to see if you should be falling
		if(not self.jumping and not coll_floor(self.y+1)) then
			self.falling = true
		else
			self.stick = false --stops stick when hitting the ground
		end

		--move sideways
		if btn(1) or btn(0) and (not self.removecontrol) then
	    
		   	if(self.stick and (self.unstickcounter < 15)) then
		   		--code to delay your falling off the wall while walljumping if you push the opposite direction
		   		if self.facing == "left" then
			   		if(btn(1)) then
			   			self.unstickcounter += 1
			   		else
			   			self.unstickcounter = 0
			   		end
		   		else
			   		if(btn(0)) then
			   			self.unstickcounter += 1
			   		else
			   			self.unstickcounter = 0
			   		end
		   		end
		   		--if(not coll_rightwall(bugtest,self.y) and not coll_leftwall(bugtest,self.y)) self.stick = false
		   	else
		   		--reset
		   		self.stick = false
		   		self.unstickcounter = 0

			    --move right
			    if btn(1) and not btn(0) then 
			     self.facing = "right"
			     self.velx += self.speed
			    end

			    --move left
			    if btn(0) and not btn(1) then
			     self.facing = "left"
			     self.velx -= self.speed
			    end
			    
			    --speed limit
			    if (self.velx > self.maxspeed) then
			     self.velx = self.velx - (self.velx - self.maxspeed)/2
			    elseif (self.velx < -self.maxspeed) then
			     self.velx = self.velx + (abs(self.velx) - self.maxspeed )/2
			    end
			end
		else
			self:stopping()
		end
	  
		if(self.velx > 0) or (self.velx < 0)then
			self.moving = true
			--self.sprite = 1
		else
			self.moving = false
			--self.sprite = 1
		end

		--undo stick if falled off edge of wall
		--if(not coll_rightwall(bugtest,self.y) and not coll_leftwall(bugtest,self.y)) self.stick = false

		if (self.moving == true) then
			local newx = self.x + self.velx

			--(if moving right)
			if (newx > self.x) then 
				if(coll_rightwall(0, self.y)) then
					local fix = -1
					while coll_rightwall(fix, self.y) do
						fix -= 1
						correction = fix
					end
					self.x = ceil(newx + fix)
					self.velx = 0
				else
					self.x = ceil(newx)
				end

					--sticking to wall
				if self.falling and coll_rightwall(1, self.y) then
					self.stick = true
					--check to see if hit ground doesn't work
					if(coll_floor(self.y+8)) then
						self.falling = false
						self.stick = false
					end
				else
					self.stick = false
				end

		    -- if moving left
		    elseif (newx < self.x) then
			    if(coll_leftwall(0, self.y)) then
			     local fix = 1
			     while coll_leftwall(fix, self.y) do
			      fix += 1  
			     end
			     self.x = flr(newx + fix)
			     self.velx = 0
			    else
			     self.x = flr(newx)
			    end

			    --sticking to wall
			    if self.falling and coll_leftwall(-1, self.y) then
			     self.stick = true
			     --check to see if hit ground doesn't work
			     if(coll_floor(self.y+8)) then
			      self.falling = false
			      self.stick = false
			     end
			    else
			     self.stick = false
			    end
		    end
		end



		--run button (needs to check if falling first or it can be set when bumping your head)
		--[[
		if(btn(4) and (not self.jumping) and (not self.falling)) then --cant change in midair
			if(self.maxspeed < self.runspeed) then
				self.maxspeed += self.rateofacceleration
			end
			--self.jumpingspeed = 9
		elseif ((self.jumping == false) and (self.falling == false)) then
			if (self.maxspeed > self.normalspeed) then
				self.maxspeed -= self.rateofacceleration
			end
			--self.jumpingspeed = 8
		end
		]]


		--jump
		if(not btn(5)) then -- stops holding the jump button down
			self.jumpreset = true
		end

		if(not self.jumping) and ((not self.falling) or self.stick) and self.jumpreset and btn(5) then
			self.jumping = true
	    
			self.falling = false --fixes stick jump thinking your falling and jumping at the same time
			self.jumpreset = false

			self.vely = 0 -- reset vely - important if jumping from stick
			if self.stick then
	     
				if( self.facing == 'left') then
					self.velx += self.speed*20 --move away from the wall
				else
					self.velx -= self.speed*20
				end

				self.vely = 0 --fixes bug that causes a jump from a large fall to have huge velocity
				self.vely += self.jumpingspeed/2 --smaller jump from stick
	     
			else
				self.vely += self.jumpingspeed --normal jump
			end
			--sfx(1) --play jump sound
		end

		if self.jumping and (not self.removecontrol) then
			local newy = self.y - self.vely
			self.vely -= gravity
	    
			if(newy >= self.y) then -- check to see if reached top of jump
				self.jumping = false
				self.falling = true
			end

			if(coll_floor(newy)) then
				local fix = 1
				while coll_floor(newy + fix) do
					fix += 1  
				end
				self.y = newy + fix
				--self.falling = true
				self.jumping = false
				self.vely = 0
			elseif(coll_ceiling(newy)) then
				local fix = -1
				while coll_floor(newy + fix) do
					fix -= 1  
				end
				self.y = newy + fix
				--self.falling = true
				self.jumping = false
				self.vely = 0
		    else
		    	self.y = newy
		    end
		end


		if self.falling then
			if(self.stick) then
				self.vely += gravity/6
			else
				self.vely += gravity
			end

			local newy = self.y + self.vely
		    if(coll_floor(newy)) then
		    	--backtrack until not colliding
				local fix = 1
				while (coll_floor(newy - fix)) do
					fix += 1  
				end
				self.y = ceil(newy - fix) -- 'ceil' important for making sure feet are on ground
				self.falling = false
				self.vely = 0
		    else
				self.y = newy
		    end
		end


		

		return -self.x%352 --send to worldx coordinate
	end,

  draw=function(self)
   if (self.jumping == true) then
    self.sprite = 146
   elseif (self.stick == true) then
    self.sprite = 147
   elseif (self.moving == true) then
   --animate walking
    self.sprite = 144+(self.framecounter/3)%2
    self.framecounter +=1
    if(self.framecounter >= 1000) self.framecounter = 0
   else
    self.sprite = 144 -- stationary
   end
   --draw the player facing the correct way
   if(self.facing == "right") then
    spr(self.sprite, 60, self.y+worldy)
   else
    spr(self.sprite, 60, self.y+worldy,1,1,true) 
   end
  end,

 }
 return player
end

function flattocylinder(x,radius0)
	local radius = radius0 or 50
	return 64+sin(x/352)*radius
end

function createledge(x0,y0)
end

function ledgefwidth(x)
	--print(cos((x-180)/360)*16)
	return ceil(cos((x-180)/352)*16)+0.5
end

function ledgesidewidth(x)
	return sin((x-180)/352)*4
end

function brickslice(x0,y0,offset0)
	local slice = {
		x=x0,
		y=y0,
		offset=offset0,
		
		move = function(self)
			self.offset = worldx
		end,
		
		draw = function(self)
			spr((flr(self.offset%8))*16,self.x,self.y+worldy,13,1)
		end,
	}
	return slice
end

function drawhills(height, xscale, yscale, offset, colour, highlight, highlightcolour)
	local lastheight = height+sin(((worldx)/1000)*xscale+offset)*yscale
	for x = 0,127 do
		local hillheight = height+sin(((worldx+x)/1000)*xscale+offset)*yscale
		line(x,127, x,hillheight ,colour) 
		if hillheight-0.01 <= lastheight and highlight then
	 		pset(x,hillheight, highlightcolour)
  		end
		lastheight = hillheight
		--if(x == 0) ?hillheight

		--poke(0x5f38,2)
		--poke(0x5f39,2)
		--for x = 0, 127 do
		 --tline(x,0,x,127,(x%16)/8,(x%16)/8)
		--lend
	end
end

function brick(x0,y0,connected)
	local singlebrick = {
		x0 = x0,
		x = flattocylinder(x0 +worldx),
		y = y0,
		thickness = 8,
		infront = false,
		canider = false,
		width = 0,

		move = function(self)
			self.x = flattocylinder(x0 + worldx,54)
		end,

		draw = function(self)
			if(self.canbecollider == true ) pal(8,7)
			local rotationposition = (x0+worldx)%352
			local leftsidefix = 4-((rotationposition-90)/90)*4
			local rightsideface = ledgefwidth(rotationposition)-0.5
			self.width = ledgefwidth(rotationposition)
			if(rightsideface) <0.5 rightsideface = 0.5
			if rotationposition > 90 and rotationposition <180 then 
				self.infront = true
				sspr(0,64,16,8,flr(self.x+0.5),self.y+worldy,self.width+leftsidefix,8)
			else
				self.infront = false
			end

			if connected == "right" or connected == "none" then 
				if rotationposition > 180 and rotationposition < 280 then
					sspr(24,64,8,8,flr(self.x+0.5),self.y+worldy,ledgesidewidth(rotationposition),8)
				end
			end

			if rotationposition >= 180 and rotationposition <280 then 
				sspr(0,64,16,8,flr(self.x+0.5),self.y+worldy,self.width,8)
			end

			if connected == "left" or connected == "none" then 
				if rotationposition < 180 and rotationposition > 80 then
					sspr(16,64,8,8,flr(self.x+0.5+rightsideface),self.y+worldy,ledgesidewidth(rotationposition),8)
				end
			end

			
			--print(self.x)
			pal()
			--if(self.canbecollider == true ) print("x: "..self.x.." y: "..self.y.." w: "..self.width)
			self.canbecollider = false
		end,
	}
	return singlebrick
end

--[[function createlevel(levelsource)
	local counter = 0
	for square in all(levelsource) do
		if(square == 1) then

			add(bricks, brick((counter%22)*16,flr(counter/22)*8))
		end
		counter += 1
	end
end]]

function createlevel(levelsource)
	for i = 1, #levelsource do
		local sides = "none"
		if(levelsource[i] == 1) then
			if(i > 1 and i < #levelsource-1) then
				if(levelsource[i+1] == 1) sides = "right"
				if(levelsource[i-1] == 1) sides = "left"
				if((levelsource[i+1] == 1) and (levelsource[i-1] == 1)) sides = "both"
			end

			add(bricks, brick((i%22)*16,ceil(i/22)*8,sides))
		end
	end
end


function myfirstsort(mytable)
	for i = 1, #mytable-1 do
		for j = 1, #mytable-1 do
			if(mytable[j].closenesstocenter > mytable[j+1].closenesstocenter) then
				mytable[j],mytable[j+1] = mytable[j+1], mytable[j]
			end
		end
	end
end

function _init()
	slices ={}
	bricks = {}

	xspeed = 1
	gravity = 0.2

	for i = -20,30 do
		add(slices,brickslice(14,i*8,flr(i%2)*4))
	end

	correction = 0
	collisiontiles = 0

	testoffset = 0
	backgroundx = 0
	worldx = 0
	worldy = 0
	player = createcharacter(60,10)

	bugtest = 0
	
	--add(bricks, testbrick(0,40))

	level = {
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,1,1,0,0,0,1,0,1,1,1,0,0,0,0,0,0,0,0,
		0,0,0,0,0,1,1,0,0,1,0,0,0,1,1,1,1,1,1,1,1,0,
		1,0,0,0,0,0,1,1,0,0,0,0,0,1,0,0,0,0,0,0,0,1,
		0,1,1,0,1,0,0,0,1,1,1,1,1,1.0,0,0,0,0,0,0,0,
		0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		1,1,1,1,1,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,
		0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,
		0,0,1,1,0,0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,
		1,1,0,0,0,0,0,1,1,0,0,0,1,1,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,1,1,0,0,1,1,1,1,0,0,0,0,0,0,0,0,0,
		0,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
		0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,1,
		0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
		0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0,0,
		1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
	}
	createlevel(level)
end

function _update60()

	for sl in all(slices) do
		sl:move()
	end


	collisiontiles = 0
	for br in all(bricks) do
		br:move()
		if(br.canbecollider) collisiontiles += 1 
	end

	worldx = flr(player:move())

	cameraheight(player)
	--myfirstsort(bricks)

	--if(btn(0)) worldx += xspeed
	--if(btn(1)) worldx -= xspeed

	if (btnp(2)) bugtest += 1
	if (btnp(3)) bugtest -= 1

end

function _draw()
	cls(12)
	
	drawhills(50,20,5,worldx/1000+0.6,13,true,6)
	drawhills(64,10,10,worldx/1000,3,true,11)

	for sl in all(slices) do
		sl:draw()
		--?sl.offset
	end

	for br in all(bricks) do
		br:draw()
	end

	player:draw()

	--[[if(worldx>800 and worldx<3400) then
		--rect(flattocylinder(worldx)-8,64,flattocylinder(worldx)+8,72,7)
		if(worldx>1000 and worldx <3000) sspr(0,64,16,8,flattocylinder(worldx,2)+2,64,ledgefwidth(worldx),8)
		if(worldx<2000) sspr(16,64,8,8,flattocylinder(worldx)+2,64,ledgesidewidth(worldx),8)
		if(worldx>2000) sspr(24,64,8,8,flattocylinder(worldx-200)+1.9,64,ledgesidewidth(worldx),8)
	end]]

	--pset(67, player.y+worldy,7)

	?bugtest
	?worldx
	--?player.stick
	--?player.unstickcounter
	--?player.facing
	

end
__gfx__
d6666666666666d66666dd666666dd666666dd6d6666d5ddddd6dd5ddddddd5ddddddd5dddddd55ddddd55dddd55ddd5dd500000000000000000000000000000
ddd6dd66dd6666dd6666dd666666dd6dd6d655ddddddd5dd5dddd55d55dddd5555555d1155555515555511555511111111110000000000000000000000000000
dddddddd6ddd66dddd6d6ddddddddddddddddd5d5dddd55555d55555555555555555555515555551111111111111111111110000000000000000000000000000
ddddd6dd666dd66d6ddddd66ddddddddddddddddd5dd55d5d5555555555555555555555555515155511115111111111111110000000000000000000000000000
ddddddd66d6d66dd6dd66dd6dd66dddddddddddd55ddd55d5555d555555555555555555555115551111111111111111111110000000000000000000000000000
dddddddd6d66d6dd66dd6dd6ddd6dddddddddddddd5dd5ddd555d555555555555555555555515555111111111111111111110000000000000000000000000000
dddddd6dd6d66d66d66dd66dd6ddd6ddddddddd5ddd55dd5555555dd555555555555511551551155111115111111111111110000000000000000000000000000
0555dd5d5d55d5dd55d55dd55d515d5515515d511551155111511155111511151111111511111155111115111111111111110000000000000000000000000000
d6d66d666d66666d66666dd6d6666dddddd66ddddddddd5dddddddd5ddddddd55dddddd55ddddd55dd5dd55ddd5555d555500000000000000000000000000000
ddd66d666d66666d66666dd666666dd6dd66655ddddddd55dddddd55dd5dddd55555d5d555555551555551155551115111110000000000000000000000000000
dddd6ddd6ddd666dddd6d6dddddddddddddddd55d5dddd5555555555555555555555555551555515111111111111111111110000000000000000000000000000
ddddd66d6666dd6666ddddd66ddddddddddddddddd5dd55dd5555555555555555555555555551515511111511111111111110000000000000000000000000000
dddddddd6dd6d66dd6dd66dd6ddd6ddddddddd5dd55ddd55d5555555555555555555555555511515111111111111111111110000000000000000000000000000
dddddd6dd6d6dd6dd66dd6dddddd6dddddd5ddddddd5dd5555555555555555555555555555551511511111111111111111110000000000000000000000000000
ddddddd6d66d6dd66d66dd66ddddddddddddd5dd5ddd555d55555555d5555515d515551155155115511111511111111111110000000000000000000000000000
05555d5d5dd55d5dd55d55dd51dd15d5115515d51115115511115115511151115111111151111115511111111111111111110000000000000000000000000000
d6dd6dd666d66666d6d666dd6d6666dddddd66d5ddddd6d5dddddddd5ddddddd55dddddd55ddddd555d5dd55d5d5555555500000000000000000000000000000
d6d66dd666d66666d666666d666666dd6dd666d5ddddddd55ddddddd55d5dddd55555d5d51555555155555111551111111110000000000000000000000000000
ddddddddd6dddd66dddd6d6dddddddddddddddd5555dd5d555555555555555555555555555115511511111111111111111110000000000000000000000000000
dddddd6dd6666d66d66dddddddddddddddddddddddd55d55dd555555555555555555555555555111551111111111111111110000000000000000000000000000
ddddddddd6d66d66dd6dd66dd6ddd6ddddddddd5dd555dd55d555555555555555555555555551155511111111111111111110000000000000000000000000000
ddddddd6dddd6dd6dd66dd6ddddddddddddd5dd5dddd55d55d555555555555555555551555555111151111111111111111110000000000000000000000000000
dddddd666d66d6dd66d66dd66ddddddddddddd5dd5ddd555dd5555555d5555555551555115511511551111111111111111110000000000000000000000000000
05555dd5d5dd5dd5dd55d55dd515d15d5515511d5111511151111511551111111511111115111111551111111111111111110000000000000000000000000000
d6dd66d6666d66666d6d666ddddd666dddddd66d5dddddddd5ddddddd55dddddd55dddddd55ddddd55dd5dd55d5d555555500000000000000000000000000000
d6dd66d6666d66666d66666dd666666dd6dd6d6d5ddddddd55dd5dddd55d55ddd55555d5d5555555515555511155111111110000000000000000000000000000
ddddd6ddd66dddd66dddd6dddddddddddddddddd55555d5555555555555555555555555555511151151111111111111111110000000000000000000000000000
dddddd66dd6666d6d666dddddddddddddddddddddddd55d55dd55555555555555555551555555511155111111111111111110000000000000000000000000000
ddddd66dd66d6dd66d66dd6ddd6ddddddddddddd5ddd55dd55555555555555555555551555555115111111111111111111110000000000000000000000000000
ddd6dd666d6d66dd6dd66dddddddddddddddd5dd5dddd55d55555555555555555555555155555511111111111111111111110000000000000000000000000000
dddddd6d6dd6666dd66d66ddd6ddddddddddddd5dd55dd555dd5555555d515555155155511551151155111111111111111110000000000000000000000000000
05d555d55d5dd5dd5dd55d55dd555d55d51155115511151115511151115111111155111111511111151111111111111111110000000000000000000000000000
dddd66dd666dd6666dd6d666dddddd66ddddddd6d5dddddddd5ddddddd55dddddd55dddddd55ddddd55dd5dd555dd55555500000000000000000000000000000
d66d666d6666d66666d666666d66d666d5ddd66dd5ddddddd55dd5dddd55d55ddd55555d55515555551555551155511111110000000000000000000000000000
dddddd6ddd66dddd66dddddddddddddddd5ddddddd5555d555555555555555555555555555551115115111111111111111110000000000000000000000000000
ddddddd66dd666dddd666dddddddddddddddddddd5ddd555555d5555555555555555555555155551115511111111111111110000000000000000000000000000
dddddd6d6d66d6dd66d66dd66dddddddddddd5ddd55dd555d5555555555555555555555155555511511111111111111111110000000000000000000000000000
dddddddd6dd6d66dd6d666dd6ddddddddddddd5dd5dddd55d5555555555555555555555515555551111111111111111111110000000000000000000000000000
ddddddd6d6dd6d66dd66d66ddd6ddddddddddddd55dd555d555d5555555d51555515515555155115115511111111111111110000000000000000000000000000
055d555d5dd5dd5dd5dd55d55dd555d51d51115115d1111511551115111511115115511111151111111111111111111111110000000000000000000000000000
dd6dd66d6666dd6666dd6d6666ddddd66ddddddd665dddddddd5ddddddd55ddddddd55dd5dd55ddddd55dd5d5555d55555500000000000000000000000000000
dd6dd66d6666dd66666d666666dd6d666d5dddd6dd55ddddddd55dddddd555d5ddd5555555551555555155555115511111110000000000000000000000000000
dddddd6dddd66ddddd6dddddddddddddddd5ddddddd55555d5555555555555555555551555555111511511111111111111110000000000000000000000000000
dddd6dd666d6666dd6dd66dddddddddddddddddddd5dddd55555d555555555555555555511515555111551111111111111110000000000000000000000000000
dddddd6dddd66d6dd66d66dd66dddddddddddd5ddd55dd555d555555555555555555555515555511111111111111111111110000000000000000000000000000
dddd6dd6d6dd6d66dd6dd6ddddddddddddddddd55d55dd5555d55555555555555555555551555555111111111111111111110000000000000000000000000000
ddddd6d66d6dd6d66dd66d66ddd6ddddd5ddddddd55dd5555555d555555555155551551155115511111511111111111111110000000000000000000000000000
055d555dd5d5dd55d55dd55d55dd555d51dd1115511d511151155111111155111111551111115511111511111111111111110000000000000000000000000000
d66dd666d6666d66666dd6d6666ddddd6665ddddd66d5ddddddd55ddddddd5ddddddd55ddddd55dd5dd55dd5d5555d5555500000000000000000000000000000
dd66d666d6666dd66666d666666dd6d66665dddd6dd55ddddddd55dd5ddd55555dddd55555555155555515555111551111110000000000000000000000000000
ddddddd6dddd6dddddd6dddddddddddddddd5dd5dddd55555d555555555555555555555155555511551111111111111111110000000000000000000000000000
dddd6dd6666d6666ddddd66ddddddddddddddddd5dd5dddd55555d55555555555555555555151555111151111111111111110000000000000000000000000000
dddd6dd6d6dd6dd6dd66d66dd66dddddddddddd5ddd55dd555dd5555555555555555555551155511111111111111111111110000000000000000000000000000
ddddd6ddd66dd6d66dd6dd66dd6ddddddddddddd55d55ddd555d5555555555555555555555155155111111111111111111110000000000000000000000000000
dddddd6d6d66dd6d66dd66dd6ddddddddd5ddddddd55dd5555555d55555515d55555155115511551111151111111111111110000000000000000000000000000
0555d5d5dd5d5dd55d55dd55d55dd555d515d1115511d51115111511111115511111115111111551111151111111111111110000000000000000000000000000
d6d6dd66dd6666dd6666dd6d6666dddddd66ddddddd6d5ddddddd55ddddddd55dddddd55dd5dd55dd5dd55d5dd555d5555500000000000000000000000000000
dd66dd66dd6666d666666d666666dd6d66665dddd6ddd5ddddddd55dd5dddd55555d5d1555555515555551555511111111110000000000000000000000000000
dddddddd6ddd66dddd6d6ddddddddddddddddd5d5dddd55555d55555555555555555555515555551111111111111111111110000000000000000000000000000
ddddd6dd666dd66d6dddddd6ddddddddddddddddd5dd55d5d5555555555555555555555555515155511115111111111111110000000000000000000000000000
ddddddd66d6d66dd6dd66dd6dd66dddddddddddd55ddd55d5555d555555555555555555555115551111111111111111111110000000000000000000000000000
dddddddd6d66d6dd66dd6dd6ddd6dddddddddddddd5dd5ddd555d555555555555555555555515555111111111111111111110000000000000000000000000000
dd6dd666d6666d66d66dd66d66ddd6ddddddddddddd55dd5555555dd5555555d5555515551555155111115111111111111110000000000000000000000000000
0555d55d5d55d5dd55d55d555d55dd5515515d111551155111511155111111551111111511111151111115111111111111110000000000000000000000000000
88228888888882229959888811111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22888222882222829899888811111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22288882822228889889988888111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88882882125222228999988811111118000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22822282222222288888888811111118000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
28228888222222218888888811111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88288118222222288999989811111888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222111122222229899989911111888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09999990099999900999999000099900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
92222229922222299222222900922290000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
92292929922929299229292909292229000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
92222229922222299222222992922290000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
92222229922222299222222992222999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09999990099999900999999009229909000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00900900099009090090090000990999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00990990090000900900900000000009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444cccccccc0555555555555550051111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444cccccccc5666666666666665059999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44544444cccccccc000000000000000005bbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444544cccccccc000000000000000005aaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444cccccccc000000000000000005eeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444cccccccc0000000000000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444cccccccc0000000000000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
54444444cccccccc0000000000000000555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd00000000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddddd5d500000000dd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dd5ddddd00000000dd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5ddddddd000000005dd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddd5ddd000dd000dddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd00dddd00d5dddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d5dd5ddd0dddd5d0ddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddddddd5dd5dddddddd5dddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
77cc777c7c7ccccc777d777d77767d7666dd6d6666ddddd66ddddddd665dddddddd5ddddddd55ddddddd55dd5dd55ddddd55dd5d5555d555555ccccccccccccc
c7cc7c7c7c7ccccc7d7d767d76767d76666d666666dd6d666d5dddd6dd55ddddddd55dddddd555d5ddd555555555155555515555511551111111cccccccccccc
c7cc7c7c777ccccc777d777d7776777ddd6dddddddddddddddd5ddddddd55555d555555555555555555555155555511151151111111111111111cccccccccccc
c7cc7c7ccc7cccccdd7d6d766676667dd6dd66dddddddddddddddddddd5dddd55555d55555555555555555551151555511155111111111111111cccccccccccc
777c777ccc7cc7ccdd7ddd7ddd766d7dd66d66dd66dddddddddddd5ddd55dd555d55555555555555555555551555551111111111111111111111cccccccccccc
ccccccccccccccccdddd6dd6d6dd6d66dd6dd6ddddddddddddddddd55d55dd5555d5555555555555555555555155555511111111111111111111cccccccccccc
ccccccccccccccccddddd6d66d6dd6d66dd66d66ddd6ddddd5ddddddd55dd5555555d55555555515555155115511551111151111111111111111cccccccccccc
ccccccccccccccccc55d555dd5d5dd55d55dd55d55dd555d51dd1115511d51115115511111115511111155111111551111151111111111111111cccccccccccc
ccccccccccccccccd6d66d666d66666d66666dd6d6666dddddd66ddddddddd5dddddddd5ddddddd55dddddd55ddddd55dd5dd55ddd5555d5555ccccccccccccc
ccccccccccccccccddd66d666d66666d66666dd666666dd6dd66655ddddddd55dddddd55dd5dddd55555d5d55555555155555115555111511111cccccccccccc
ccccccccccccccccdddd6ddd6ddd666dddd6d6dddddddddddddddd55d5dddd555555555555555555555555555155551511111111111111111111cccccccccccc
ccccccccccccccccddddd66d6666dd6666ddddd66ddddddddddddddddd5dd55dd555555555555555555555555555151551111151111111111111cccccccccccc
ccccccccccccccccdddddddd6dd6d66dd6dd66dd6ddd6ddddddddd5dd55ddd55d555555555555555555555555551151511111111111111111111cccccccccccc
ccccccccccccccccdddddd6dd6d6dd6dd66dd6dddddd6dddddd5ddddddd5dd555555555555555555555555555555151151111111111111111111cccccccccccc
ccccccccccccccccddddddd6d66d6dd66d66dd66ddddddddddddd5dd5ddd555d55555555d5555515d51555115515511551111151111111111111cccccccccccc
ccccccccccccccccc5555d5d5dd55d5dd55d55dd51dd15d5115515d5111511551111511551115111511111115111111551111111111111111111cccccccccccc
ccccccccccccccccdd6dd66d6666dd6666dd6d6666ddddd66ddddddd665dddddddd5ddddddd55ddddddd55dd5dd55ddddd55dd5d5555d555555ccccccccccccc
ccccccccccccccccdd6dd66d6666dd66666d666666dd6d666d5dddd6dd55ddddddd55dddddd555d5ddd555555555155555515555511551111111cccccccccccc
ccccccccccccccccdddddd6dddd66ddddd6dddddddddddddddd5ddddddd55555d555555555555555555555155555511151151111111111111111cccccccccccc
ccccccccccccccccdddd6dd666d6666dd6dd66dddddddddddddddddddd5dddd55555d55555555555555555551151555511155111111111111111cccccccccccc
ccccccccccccccccdddddd6dddd66d6dd66d66dd66dddddddddddd5ddd55dd555d55555555555555555555551555551111111111111111111111cccccccccccc
ccccccccccccccccdddd6dd6d6dd6d66dd6dd6ddddddddddddddddd55d55dd5555d5555555555555555555555155555511111111111111111111cccccccccccc
ccccccccccccccccddddd6d66d6dd6d66dd66d66ddd6ddddd5ddddddd55dd5555555d55555555515555155115511551111151111111111111111cccccccccccc
ccccccccccccccccc55d555dd5d5dd55d55dd55d55dd555d51dd1115511d51115115511111115511111155111111551111151111111111111111cccccccccccc
ccccccccccccccccd6d66d666d66666d66666dd6d6666dddddd66ddddddddd5dddddddd5ddddddd55dddddd55ddddd55dd5dd55ddd5555d5555ccccccccccccc
ccccccccccccccccddd66d666d66666d66666dd666666dd6dd66655ddddddd55dddddd55dd5dddd55555d5d55555555155555115555111511111cccccccccccc
ccccccccccccccccdddd6ddd6ddd666dddd6d6dddddddddddddddd55d5dddd555555555555555555555555555155551511111111111111111111cccccccccccc
ccccccccccccccccddddd66d6666dd6666ddddd66ddddddddddddddddd5dd55dd555555555555555555555555555151551111151111111111111cccccccccccc
ccccccccccccccccdddddddd6dd6d66dd6dd66dd6ddd6ddddddddd5dd55ddd55d555555555555555555555555551151511111111111111111111cccccccccccc
ccccccccccccccccdddddd6dd6d6dd6dd66dd6dddddd6dddddd5ddddddd5dd555555555555555555555555555555151151111111111111111111cccccccccccc
ccccccccccccccccddddddd6d66d6dd66d66dd66ddddddddddddd5dd5ddd555d55555555d5555515d51555115515511551111151111111111111cccccccccccc
ccccccccccccccccc5555d5d5dd55d5dd55d55dd51dd15d5115515d5111511551111511551115111511111115111111551111111111111111111cccccccccccc
ccccccccccccccccdd6dd66d6666dd6666dd6d6666ddddd66ddddddd665dddddddd5ddddddd55ddddddd55dd5dd55ddddd55dd5d5555d555555ccccccccccccc
ccccccccccccccccdd6dd66d6666dd66666d666666dd6d666d5dddd6dd55ddddddd55dddddd555d5ddd555555555155555515555511551111111cccccccccccc
ccccccccccccccccdddddd6dddd66ddddd6dddddddddddddddd5ddddddd55555d555555555555555555555155555511151151111111111111111cccccccccccc
ccccccccccccccccdddd6dd666d6666dd6dd66dddddddddddddddddddd5dddd55555d55555555555555555551151555511155111111111111111cccccccccccc
ccccccccccccccccdddddd6dddd66d6dd66d66dd66dddddddddddd5ddd55dd555d55555555555555555555551555551111111111111111111111cccccccccccc
ccccccccccccccccdddd6dd6d6dd6d66dd6dd6ddddddddddddddddd55d55dd5555d5555555555555555555555155555511111111111111111111cccccccccccc
ccccccccccccccccddddd6d66d6dd6d66dd66d66ddd6ddddd5ddddddd55dd5555555d55555555515555155115511551111151111111111111111cccccccccccc
ccccccccccccccccc55d555dd5d5dd55d55dd55d55dd555d51dd1115511d51115115511111115511111155111111551111151111111111111111cccccccccccc
ccccccccccccccccd6d66d666d66666d66666dd6d6666dddddd66ddddddddd5dddddddd5ddddddd55dddddd55ddddd55dd5dd55ddd5555d5555ccccccccccccc
ccccccccccccccccddd66d666d66666d66666dd666666dd6dd66655ddddddd55dddddd55dd5dddd55555d5d55555555155555115555111511111cccccccccccc
ccccccccccccccccdddd6ddd6ddd666dddd6d6dddddddddddddddd55d5dddd555555555555555555555555555155551511111111111111111111cccccccccccc
ccccccccccccccccddddd66d6666dd6666ddddd66ddddddddddddddddd5dd55dd555555555555555555555555555151551111151111111111111cccccccccccc
ccccccccccccccccdddddddd6dd6d66dd6dd66dd6ddd6ddddddddd5dd55ddd55d555555555555555555555555551151511111111111111111111cccccccccccc
ccccccccccccccccdddddd6dd6d6dd6dd66dd6dddddd6dddddd5ddddddd5dd555555555555555555555555555555151151111111111111111111dddccccccccc
ccccccccccccccccddddddd6d66d6dd66d66dd66ddddddddddddd5dd5ddd555d55555555d5555515d51555115515511551111151111111111111ddddddcccccc
ccccccccccccccccc5555d5d5dd55d5dd55d55dd51dd15d5115515d5111511551111511551115111511111115111111551111111111111111111ddddddddcccc
ccccccccccccccccdd6dd66d6666dd6666dd6d6666ddddd66ddddddd665dddddddd5ddddddd55ddddddd55dd5dd55ddddd55dd5d5555d555555dddddddddddcc
dcccccccccccccccdd6dd66d6666dd66666d666666dd6d666d5dddd6dd55ddddddd55dddddd555d5ddd555555555155555515555511551111111dddddddddddd
dddcccccccccccccdddddd6dddd66ddddd6dddddddddddddddd5ddddddd55555d555555555555555555555155555511151151111111111111111dddddddddddd
ddddddccccccccccdddd6dd666d6666dd6dd66dddddddddddddddddddd5dddd55555d55555555555555555551151555511155111111111111111dddddddddddd
ddddddddccccccccdddddd6dddd66d6dd66d66dd66dddddddddddd5ddd55dd555d55555555555555555555551555551111111111111111111111dddddddddddd
dddddddddddcccccdddd6dd6d6dd6d66dd6dd6ddddddddddddddddd55d55dd5555d5555555555555555555555155555511111111111111111111dddddddddddd
ddddddddddddddddddddd6d66d6dd6d66dd66d66ddd6ddddd5ddddddd55dd5555555d55555555515555155115511551111151111111111111111dddddddddddd
ddddddddddddddddd55d555dd5d5dd55d55dd55d55dd555d51dd1115511d51115115511111115511111155111111551111151111111111111111dddddddddddd
ddddddddddddddddd6d66d666d66666d66666dd6d6666dddddd66ddddddddd5dddddddd5ddddddd55dddddd55ddddd55dd5dd55ddd5555d5555ddddddddddddd
dddddddddddddddbddd66d666d66666d66666dd666666dd6dd66655ddddddd55dddddd55dd5dddd55555d5d55555555155555115555111511111dddddddddddd
dddddddddddddbb3dddd6ddd6ddd666dddd6d6dddddddddddddddd55d5dddd555555555555555555555555555155551511111111111111111111dddddddddddd
dddddddddddbb333ddddd66d6666dd6666ddddd66ddddddddddddddddd5dd55dd555555555555555555555555555151551111151111111111111dddddddddddd
dddddddddbb33333dddddddd6dd6d66dd6dd66dd6ddd6ddddddddd5dd55ddd55d555555555555555555555555551151511111111111111111111dddddddddddd
ddddddbbb3333333dddddd6dd6d6dd6dd66dd6dddddd6dddddd5ddddddd5dd555555555555555555555555555555151151111111111111111111dddddddddddd
ddddbb3333333333ddddddd6d66d6dd66d66dd66ddddddddddddd5dd5ddd555d55555555d5555515d51555115515511551111151111111111111dddddddddddd
ddbb33333333333335555d5d5dd55d5dd55d55dd51dd15d5115515d5111511551111511551115111511111115111111551111111111111111111dddddddddddd
bb33333333333333dd6dd66d6666dd6666dd6d6666ddddd677777777777777777dd5ddddddd55ddddddd55dd5dd55ddddd55dd5d5555d555555ddddddddddddb
3333333333333333dd6dd66d6666dd66666d666666dd6d667d5dddd6dd55dddd7dd55dddddd555d5ddd555555555155555515555511551111111dddddddddbb3
3333333333333333dddddd6dddd66ddddd6ddddddddddddd7dd5ddddddd555557555555555555555555555155555511151151111111111111111dddddddbb333
3333333333333333dddd6dd666d6666dd6dd66dddddddddd7ddddddddd5dddd57555d55555555555555555551151555511155111111111111111dddddbb33333
3333333333333333dddddd6dddd66d6dd66d66dd66dddddd7ddddd5ddd55dd557d55555555555555555555551555551111111111111111111111dddbb3333333
3333333333333333dddd6dd6d6dd6d66dd6dd6dddddddddd7dddddd55d55dd5575d5555555555555555555555155555511111111111111111111bbb333333333
3333333333333333ddddd6d66d6dd6d66dd66d66ddd6dddd75ddddddd55dd5557555d55555555515555155115511551111151111111111111111333333333333
3333333333333333355d555dd5d5dd55d55dd55d55dd555d71dd1115511d51117115511111115511111155111111551111151111111111111111333333333333
3333333333333333d6d66d666d66666d66666dd6d6666ddd77777777777777777dddddd5ddddddd55dddddd55ddddd55dd5dd55ddd5555d55553333333333333
3333333333333333ddd66d666d66666d66666dd666666dd6dd66655ddddddd55dddddd55dd5dddd55555d5d55555555155555115555111511111333333333333
3333333333333333dddd6ddd6ddd666dddd6d6dddddddddddddddd55d5dddd555555555555555555555555555155551511111111111111111111333333333333
3333333333333333ddddd66d6666dd6666ddddd66ddddddddddddddddd5dd55dd555555555555555555555555555151551111151111111111111333333333333
3333333333333333dddddddd6dd6d66dd6dd66dd6ddd6ddddddddd5dd55ddd55d555555555555555555555555551151511111111111111111111333333333333
3333333333333333dddddd6dd6d6dd6dd66dd6dddddd6dddddd5ddddddd5dd555555555555555555555555555555151151111111111111111111333333333333
3333333333333333ddddddd6d66d6dd66d66dd66ddddddddddddd5dd5ddd555d55555555d5555515d51555115515511551111151111111111111333333333333
333333333333333335555d5d5dd55d5dd55d55dd51dd15d5115515d5111511551111511551115111511111115111111551111111111111111111333333333333
3333333333333333dd6dd66d6666dd6666dd6d6666ddddd66ddddddd665dddddddd5ddddddd55ddddddd55dd5dd55ddddd55dd5d5555d5555553333333333333
3333333333333333dd6dd66d6666dd66666d666666dd6d666d5dddd6dd55ddddddd55dddddd555d5ddd555555555155555515555511551111111333333333333
3333333333333333dddddd6dddd66ddddd6dddddddddddddddd5ddddddd55555d555555555555555555555155555511151151111111111111111333333333333
3333333333333333dddd6dd666d6666dd6dd66dddddddddddddddddddd5dddd55555d55555555555555555551151555511155111111111111111333333333333
3333333333333333dddddd6dddd66d6dd66d66dd66dddddddddddd5ddd55dd555d55555555555555555555551555551111111111111111111111333333333333
3333333333333333dddd6dd6d6dd6d66dd6dd6ddddddddddddddddd55d55dd5555d5555555555555555555555155555511111111111111111111333333333333
3333333333333333ddddd6d66d6dd6d66dd66d66ddd6ddddd5ddddddd55dd5555555d55555555515555155115511551111151111111111111111333333333333
3333333333333333355d555dd5d5dd55d55dd55d55dd555d51dd1115511d51115115511111115511111155111111551111151111111111111111333333333333
3333333333333333d6d66d666d66666d66666dd6d6666dddddd66ddddddddd5dddddddd5ddddddd55dddddd55ddddd55dd5dd55ddd5555d55553333333333333
3333333333333333ddd66d666d66666d66666dd666666dd6dd66655ddddddd55dddddd55dd5dddd55555d5d55555555155555115555111511111333333333333
3333333333333333dddd6ddd6ddd666dddd6d6dddddddddddddddd55d5dddd555555555555555555555555555155551511111111111111111111333333333333
3333333333333333ddddd66d6666dd6666ddddd66ddddddddddddddddd5dd55dd555555555555555555555555555151551111151111111111111333333333333
3333333333333333dddddddd6dd6d66dd6dd66dd6ddd6ddddddddd5dd55ddd55d555555555555555555555555551151511111111111111111111333333333333
3333333333333333dddddd6dd6d6dd6dd66dd6dddddd6dddddd5ddddddd5dd555555555555555555555555555555151151111111111111111111333333333333
3333333333333333ddddddd6d66d6dd66d66dd66ddddddddddddd5dd5ddd555d55555555d5555515d51555115515511551111151111111111111333333333333
333333333333333335555d5d5dd55d5dd55d55dd51dd15d5115515d5111511551111511551115111511111115111111551111111111111111111333333333333
3333333333333333dd6dd66d6666dd6666dd6d6666ddddd66ddddddd665dddddddd5ddddddd55ddddddd55dd5dd55ddddd55dd5d5555d5555553333333333333
3333333333333333dd6dd66d6666dd66666d666666dd6d666d5dddd6dd55ddddddd55dddddd555d5ddd555555555155555515555511551111111333333333333
3333333333333333dddddd6dddd66ddddd6dddddddddddddddd5ddddddd55555d555555555555555555555155555511151151111111111111111333333333333
3333333333333333dddd6dd666d6666dd6dd66dddddddddddddddddddd5dddd55555d55555555555555555551151555511155111111111111111333333333333
3333333333333333dddddd6dddd66d6dd66d66dd66dddddddddddd5ddd55dd555d55555555555555555555551555551111111111111111111111333333333333
3333333333333333dddd6dd6d6dd6d66dd6dd6ddddddddddddddddd55d55dd5555d5555555555555555555555155555511111111111111111111333333333333
3333333333333333ddddd6d66d6dd6d66dd66d66ddd6ddddd5ddddddd55dd5555555d55555555515555155115511551111151111111111111111333333333333
3333333333333333355d555dd5d5dd55d55dd55d55dd555d51dd1115511d51115115511111115511111155111111551111151111111111111111333333333333
3333333333333333d6d66d666d66666d66666dd6d6666dddddd66ddddddddd5dddddddd5ddddddd55dddddd55ddddd55dd5dd55ddd5555d55553333333333333
3333333333333333ddd66d666d66666d66666dd666666dd6dd66655ddddddd55dddddd55dd5dddd55555d5d55555555155555115555111511111333333333333
3333333333333333dddd6ddd6ddd666dddd6d6dddddddddddddddd55d5dddd555555555555555555555555555155551511111111111111111111333333333333
3333333333333333ddddd66d6666dd6666ddddd66ddddddddddddddddd5dd55dd555555555555555555555555555151551111151111111111111333333333333
3333333333333333dddddddd6dd6d66dd6dd66dd6ddd6ddddddddd5dd55ddd55d555555555555555555555555551151511111111111111111111333333333333
3333333333333333dddddd6dd6d6dd6dd66dd6dddddd6dddddd5ddddddd5dd555555555555555555555555555555151151111111111111111111333333333333
3333333333333333ddddddd6d66d6dd66d66dd66ddddddddddddd5dd5ddd555d55555555d5555515d51555115515511551111151111111111111333333333333
333333333333333335555d5d5dd55d5dd55d55dd51dd15d5115515d5111511551111511551115111511111115111111551111111111111111111333333333333
3333333333333333dd6dd66d6666dd6666dd6d6666ddddd66ddddddd665dddddddd5ddddddd55ddddddd55dd5dd55ddddd55dd5d5555d5555553333333333333
3333333333333333dd6dd66d6666dd66666d666666dd6d666d5dddd6dd55ddddddd55dddddd555d5ddd555555555155555515555511551111111333333333333
3333333333333333dddddd6dddd66ddddd6dddddddddddddddd5ddddddd55555d555555555555555555555155555511151151111111111111111333333333333
3333333333333333dddd6dd666d6666dd6dd66dddddddddddddddddddd5dddd55555d55555555555555555551151555511155111111111111111333333333333
3333333333333333dddddd6dddd66d6dd66d66dd66dddddddddddd5ddd55dd555d55555555555555555555551555551111111111111111111111333333333333
3333333333333333dddd6dd6d6dd6d66dd6dd6ddddddddddddddddd55d55dd5555d5555555555555555555555155555511111111111111111111333333333333
3333333333333333ddddd6d66d6dd6d66dd66d66ddd6ddddd5ddddddd55dd5555555d55555555515555155115511551111151111111111111111333333333333
3333333333333333355d555dd5d5dd55d55dd55d55dd555d51dd1115511d51115115511111115511111155111111551111151111111111111111333333333333
3333333333333333d6d66d666d66666d66666dd6d6666dddddd66ddddddddd5dddddddd5ddddddd55dddddd55ddddd55dd5dd55ddd5555d55553333333333333
3333333333333333ddd66d666d66666d66666dd666666dd6dd66655ddddddd55dddddd55dd5dddd55555d5d55555555155555115555111511111333333333333
3333333333333333dddd6ddd6ddd666dddd6d6dddddddddddddddd55d5dddd555555555555555555555555555155551511111111111111111111333333333333
3333333333333333ddddd66d6666dd6666ddddd66ddddddddddddddddd5dd55dd555555555555555555555555555151551111151111111111111333333333333
3333333333333333dddddddd6dd6d66dd6dd66dd6ddd6ddddddddd5dd55ddd55d555555555555555555555555551151511111111111111111111333333333333
3333333333333333dddddd6dd6d6dd6dd66dd6dddddd6dddddd5ddddddd5dd555555555555555555555555555555151151111111111111111111333333333333
3333333333333333ddddddd6d66d6dd66d66dd66ddddddddddddd5dd5ddd555d55555555d5555515d51555115515511551111151111111111111333333333333
333333333333333335555d5d5dd55d5dd55d55dd51dd15d5115515d5111511551111511551115111511111115111111551111111111111111111333333333333

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000010002020400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

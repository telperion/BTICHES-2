-------------------------------------------------------------------------------
--
--		The Avatar State
--		
--		Author: 	Telperion
--		Date: 		2016-11-25
--
-------------------------------------------------------------------------------

local sw = SCREEN_WIDTH;
local sh = SCREEN_HEIGHT;
local BPS = GAMESTATE:GetSongBPS();	
local overtime = 0;
local bpm = 140;
local ofs = 0.000;	-- TODO
local plr = {nil, nil};
local curmessage = 0;
local fgcurcommand = 0;
local checked = false;
local screen;
local nextbeat = 0;
local DEG_TO_RAD = math.pi / 180.0;



local theBoys = Def.ActorFrame {
	InitCommand = function(self)
		self:fov(70)
			:vanishpoint(sw/2, sh/4)			
			:SetDrawByZPosition(true);
	end,
	OnCommand = function(self)
		plr[1] = SCREENMAN:GetTopScreen():GetChild('PlayerP1');
		plr[2] = SCREENMAN:GetTopScreen():GetChild('PlayerP2');
		SCREENMAN:GetTopScreen():SetDrawByZPosition(true);
		self:sleep(1000);
	end
};


--
-- 		some funktion !
--
local BTIUtil_SideSign = function(i) return (i == 2) and 1 or -1; end

local BTIUtil_Scale = function(t, inLower, inUpper, outLower, outUpper)
	local ti = (t - inLower) / (inUpper - inLower);
	return outLower + ti * (outUpper - outLower);
end

-- I grabbed this out of ScreenTestInput underlay #codereuseboys
local function input(event)
	if not event.PlayerNumber or not event.button then
		return false
	end
	
	local state = "Off"
	if event.type ~= "InputEventType_Release" then
		state = "On"		
	end
		
	MESSAGEMAN:Broadcast(ToEnumShortString(event.PlayerNumber) .. event.button .. state)
	return false
end


-------------------------------------------------------------------------------
--
-- 		BUZZIBEE no jutsu
--
local totalAttempts = 16;				-- Length of game, in shots
local takenAttempts = 0;				-- Shots taken (ping pong balls, I mean)
local resultRowLength = 8;				-- Break up the Xs and Os for cleaner viewing
local lineWidth = 6;					-- Trajectory AMV line width
local inputPersistenceFactor = 0.8;		-- Dampening factor for arrow inputs (the closer to 1.0, the slower the game responds to user directions)
local inputPerturbanceFactor = 0;		-- Initial velocity perturbance factor (you can't just let the player sit still!!)
local inputStrengthX = 50;				-- Units per beat
local inputStrengthY = 200;				-- Units per beat
local inSession = false;				-- Game active?
local DEBUG_firstVerts = true;			-- List out the initial trajectory in Trace statements

local BZBFrame = Def.ActorFrame {
	Name = "bzbFrame",
	OnCommand = function(self)
		self:diffusealpha(0.0)
			:x(SCREEN_CENTER_X)
			:visible(false);
	end,
	BZBStartMessageCommand = function(self)
		self:visible(true)
			:decelerate(16.0 / BPS)
			:diffusealpha(1.0)
			:queuecommand("BZBReady");
	end,
	BZBReadyCommand = function(self)
		Trace("BZB is in session!");
		inSession = true;
	end,
	BZBEndMessageCommand = function(self)
		self:visible(true)
			:decelerate(4.0 / BPS)
			:diffusealpha(0.0)
			:queuecommand("BZBFinished");
	end,
	BZBFinishedCommand = function(self)
		Trace("BZB is over!");
		inSession = false;
		self:hibernate(1573);
	end,
	BZBAllVibrateMessageCommand = function(self)
		self:vibrate()
			:effectmagnitude(15, 15, 0);
	end,
	BZBAllVibrateStopMessageCommand = function(self)
		self:stopeffect();
	end,
};

local BZBData = {};
local BZBInput = {};
for i = 1,2 do
	local s = (i == 2) and 1 or -1;
	BZBData[i] = {
		vx = -33*s,						-- **	**	Initial horizontal velocity
		vy =   0,						-- 		**	Initial vertical velocity
		
		x_throw 	= 288*s,			-- (const)	Horizontal position from which ball is thrown
		x_bounce 	= nil,				-- (calc)	Horizontal position at which ball bounces first time
		x_rebounce 	= nil,				-- (calc)	Horizontal position at which ball bounces second time
		x_end	 	= nil,				-- (calc)	Horizontal position at which ball would peak on the /third/ bounce
		x_near 		= 104*s,			-- (const)	Horizontal position of left side of cup
		x_far	 	=  24*s,			-- (const)	Horizontal position of right side of cup
		x_edge 		= nil,				-- (calc)	Horizontal position of ball meeting edge
		
		y_throw 	=  84,				-- **		Vertical position from which ball is thrown
		y_bounce	= nil,				-- (calc)	Vertical extent of first bounce
		y_rebounce	= nil,				-- (calc)	Vertical extent of second bounce
		y_end		= nil,				-- (calc)	Vertical extent of third bounce
		y_table 	= 360,				-- (const)	Vertical position of table surface, ball bounces, and base of cup
		y_edge 		= 252,				-- (const)	Vertical position of cup edge

		succ 		= false,			-- Would currently make the shot
		
		elasticity = 0.9,				-- Ball bounce elasticity
		acceleration = 50,				-- Ball acceleration due to gravity (in pixels per beat squared!)

		totalSucc = 0,					-- Successes
	};
	BZBInput[i] = {
		{false, false, false, false},	-- State of input
		{0, 0, 0, 0},					-- Persistence factor of input
	};
end

local BZBRateMyProfessor = function(succ)
		if totalAttempts - succ < 3  then do return 0 end		-- why are spritesheets of all things zero-indexed??
	elseif totalAttempts - succ < 5  then do return 1 end
	elseif totalAttempts - succ < 8  then do return 2 end
	elseif totalAttempts - succ < 11 then do return 3 end
	else 								  do return 4 end
	end
end	

local BZBAllowMove = function(pn)
	-- Constrain the range of player throws by making sure the ball bounces only once.
	-- Zero times, or twice, is not allowed. This is MLG beer pong rules yo
	-- (Well, that was the original intent of this function, but allowing the player to
	-- fix their aim after reaching the zero/twice limits wasn't trivial enough to
	-- get rolling in time for the tourney. The game certainly requires /some/ sort of
	-- bounding though, to prevent unrecoverable aiming mistakes! So that's here now.)
	
	local allowMove = {true, true, true, true};
	local bd = BZBData[pn];
	
	if not bd.x_bounce   then do return allowMove end end
	if not bd.x_rebounce then do return allowMove end end	
	
	if pn == 1 then
		if bd.vx <= 1 then
			allowMove[1] = false;
		end
		if bd.vx > 100 then
			allowMove[4] = false;
		end
	else
		if bd.vx >= -1 then
			allowMove[4] = false;
		end
		if bd.vx < -100 then
			allowMove[1] = false;
		end
	end
	
	if bd.vy < -100 then 
		allowMove[3] = false;
	end
	if bd.vy >  100 then 
		allowMove[2] = false;
	end
	
	return allowMove;
end

local BZBPush = function(pn, throwing, overtime, timestep)
	-- just rough 'em up a bit. so they don't get too complacent.
	if not inSession then do return end end
	
	inputStates = BZBInput[pn][1];
	inputPersist = BZBInput[pn][2];
	
	for rcpi = 1,4 do
		inputPersist[rcpi] = inputPersist[rcpi] * inputPersistenceFactor + (inputStates[rcpi] and (1-inputPersistenceFactor) or 0);
	end
	
	local ax = (inputPersist[4] - inputPersist[1]);
	local ay = (inputPersist[3] - inputPersist[2]);
	local allowMove = BZBAllowMove(pn);
	
	-- Push the player's aim around in a circle.
	local axPerturb = inputPerturbanceFactor * math.cos(overtime * math.pi / 13.0) * (pn == 2 and 1 or -1);
	local ayPerturb = inputPerturbanceFactor * math.sin(overtime * math.pi / 13.0);	
	ax = ax + axPerturb;
	ay = ay + ayPerturb;	
	
	-- Perturbance shouldn't take effect if the player's aim is about to be out of range.
	if throwing == 0 then
		if (ax < 0 and allowMove[1]) or (ax > 0 and allowMove[4]) then
			BZBData[pn].vx = BZBData[pn].vx + ax * inputStrengthX * timestep;
		end
		if (ay < 0 and allowMove[3]) or (ay > 0 and allowMove[2]) then
			BZBData[pn].vy = BZBData[pn].vy + ay * inputStrengthY * timestep;
		end
	end
end

local BZBUpdateDataModel = function(pn, timestep)
	-- Generate linestrip vertices from player data index pn with the given timestep (time is in beats).
	-- Those good ol' kinematic equations. Hello high-school physics. OK, maybe college physics.
	
	local bd = BZBData[pn];
	local xn = bd.x_throw;
	local yn = bd.y_throw;
	
	local verts = {
		{{xn, yn, 0}, Color.White}
	};
	
	local squarelastic = bd.elasticity * bd.elasticity;
	
	local vb1 = math.sqrt(bd.vy * bd.vy - 4 * bd.acceleration * (bd.y_throw - bd.y_table));		-- vertical velocity on bounce 1
	local tb1 = 0.5 * (bd.vy + vb1) / bd.acceleration;									-- time at bounce 1
	local tb2 = bd.elasticity * vb1 / bd.acceleration;									-- time at bounce 2 (relative to bounce 1)
	local tb3 = squarelastic  * vb1 / bd.acceleration;									-- time at bounce 3 (relative to bounce 2)
	
	local tce = 0.5 * (squarelastic * vb1 - math.sqrt(squarelastic * squarelastic * vb1 * vb1 - 4 * bd.acceleration * (bd.y_table - bd.y_edge))) / bd.acceleration;
	
	-- time ball would reach height of cup edge on second bounce (relative to bounce 2)
	local t_total = math.min(0.8 * (bd.x_near - bd.x_throw) / bd.vx, tb1 + tb2 + tce);
	
	bd.x_bounce 	= bd.x_throw 	+ bd.vx * tb1;
	bd.x_rebounce 	= bd.x_bounce 	+ bd.vx * tb2;
	bd.x_end		= bd.x_rebounce	+ bd.vx * tb3 * 0.5;
	bd.y_bounce 	= bd.y_table 	- 0.25 * vb1 * vb1 * squarelastic 				 				/ bd.acceleration;
	bd.y_rebounce 	= bd.y_table 	- 0.25 * vb1 * vb1 * squarelastic * squarelastic				/ bd.acceleration;
	bd.y_end	 	= bd.y_table 	- 0.25 * vb1 * vb1 * squarelastic * squarelastic * squarelastic / bd.acceleration;

	-- time ball would come down to height of cup edge on first bounce (relative to first bounce)	
	local tss = 0.5 * (bd.elasticity * vb1 + math.sqrt(squarelastic * vb1 * vb1 - 4 * bd.acceleration * (bd.y_table - bd.y_edge))) / bd.acceleration;

	bd.x_edge		= bd.x_bounce	+ bd.vx * tss;
	
	if pn == 1 then
		bd.succ = (bd.x_edge >= bd.x_near) and (bd.x_edge <= bd.x_far);
	else
		bd.succ = (bd.x_edge <= bd.x_near) and (bd.x_edge >= bd.x_far);
	end
	
	
	if DEBUG_firstVerts then
		Trace("pn = "..pn..", xn = "..xn..", yn = "..yn);
		Trace("vb1 = "..vb1..", tb1 = "..tb1..", tb2 = "..tb2..", tce = "..tce..", tss = "..tss..", t_total = "..t_total);
	end
	
	-- Check when the ball will hit the edge of the cup.
	-- TODO; can just go behind the cup for now :)
	
	for t = 0,t_total,timestep do
		-- Don't draw into the other player's field.
		if (pn == 1 and (xn > 0 or xn > bd.x_end)) or
		   (pn == 2 and (xn < 0 or xn < bd.x_end)) then
			break
		end
		-- Don't overdraw if we already made it.
--		if bd.succ and t > tss then
--			break
--		end
		
		local xm = xn;
		local ym = yn;
		local tt = t;
		local colorator = {
			BTIUtil_Scale(t, 0, t_total, 1.0, 0.0),
			1.0,
			1.0,
			BTIUtil_Scale(t, 0, t_total, 1.0, 0.2),
		};
		
		-- Oh, down is up. Gross
		if t < tb1 then
			tt = t;

			local an = bd.acceleration;
			local bn = -bd.vy;
			local cn = bd.y_throw;
			verts[#verts + 1] = {{bd.x_throw + bd.vx * tt, an*tt*tt + bn*tt + cn, 0}, colorator};
			
			-- Make sure the bounce contacts the table!
			if tt + timestep > tb1 then
				verts[#verts + 1] = {{bd.x_bounce, 	 bd.y_table, 0}, colorator};
			end
		elseif t < tb1 + tb2 then
			tt = t - tb1;

			local an = bd.acceleration;
			local bn = -vb1 * bd.elasticity;
			local cn = bd.y_table;
			verts[#verts + 1] = {{bd.x_bounce + bd.vx * tt, an*tt*tt + bn*tt + cn, 0}, colorator};			
						
			-- Make sure the bounce contacts the table!
			if tt + timestep > tb2 then
				verts[#verts + 1] = {{bd.x_rebounce, bd.y_table, 0}, colorator};
			end
		else
			tt = t - tb1 - tb2;

			local an = bd.acceleration;
			local bn = -vb1 * squarelastic;
			local cn = bd.y_table;
			verts[#verts + 1] = {{bd.x_rebounce + bd.vx * tt, an*tt*tt + bn*tt + cn, 0}, colorator};
			
		end
		
		if DEBUG_firstVerts then
			Trace("BZB: vertex "..#verts.." @ ("..verts[#verts][1][1]..", "..verts[#verts][1][2]..")!");
		end
	end
	
	DEBUG_firstVerts = false;
	return verts;	
end



BZBFrame[#BZBFrame + 1] = Def.Sprite {
	Name = "bzbTable",
	Texture = "table2-cy144.png",
	InitCommand = function(self)
		self:aux(0)				-- are we throwing right now or not?
			:xy(0, 591)
			:z(0.0);
	end,
	BZBThrowMessageCommand = function(self)
		Trace("Table heard a throw");
		
		self:sleep(3.95 / BPS)		-- countdown
			:queuecommand("BZBRegisterAttempt");	
	end,
	BZBRegisterAttemptCommand = function(self)		
		self:aux(1);
			
		self:sleep(2.05 / BPS)		-- throw
			:queuecommand("BZBReflectAttempt");
	end,
	BZBReflectAttemptCommand = function(self)		
		takenAttempts = takenAttempts + 1;
		
		for pn = 1,2 do
			local bd = BZBData[pn];		
			if bd.succ then
				MESSAGEMAN:Broadcast("P"..pn.."RecordSucc"..takenAttempts);
				bd.totalSucc = bd.totalSucc + 1;	
			else			
				MESSAGEMAN:Broadcast("P"..pn.."RecordFail"..takenAttempts);
			end
		end
		
		self:aux(0);
	end,
}
BZBFrame[#BZBFrame + 1] = Def.Quad {
	Name = "bzbPerturbance",
	InitCommand = function(self)
		self:aux(0)				-- are we throwing right now or not?
			:xy(-sw, -sh)
			:SetWidth(6)
			:SetHeight(6)
			:z(0.0);
	end,
	BZBThrowMessageCommand = function(self)
		Trace("Perturbance heard a throw");
		
		self:linear(8.0 / BPS):aux( self:getaux() + 0.02 );					-- Increase the perturbance.
		inputPersistenceFactor = inputPersistenceFactor * 0.8 + 0.2;		-- Make it harder to control.
	end,
}
for i = 1,2 do
	BZBFrame[#BZBFrame + 1] = Def.Sprite {
		Name = "bzbRSCBack"..i,
		Texture = "rsc.png",
		InitCommand = function(self)
			self:aux( tonumber(string.match(self:GetName(), "([0-9]+)")) )
				:xy(BTIUtil_SideSign(i) * 64, 313)
				:zoom(0.75)
				:z(0.2);
		end,
	}
	BZBFrame[#BZBFrame + 1] = Def.Sprite {
		Name = "bzbHand"..i,
		Texture = "hand.png",
		InitCommand = function(self)
			self:aux( tonumber(string.match(self:GetName(), "([0-9]+)")) )
				:xy(BTIUtil_SideSign(i) * 308,  84)
				:z(0.1)
				:zoomx(BTIUtil_SideSign(i));
		end,
		BZBUpdateMessageCommand = function(self)
			self:y( BZBData[self:getaux()].y_throw );
		end,
		BZBVibrateMessageCommand = function(self)
			self:vibrate()
				:effectmagnitude(15, 15, 0);
		end,
		BZBVibrateStopMessageCommand = function(self)
			self:stopeffect();
		end,
	}
	BZBFrame[#BZBFrame + 1] = Def.ActorFrame {
		-- You can think of the ball as moving in a horizontal [Actor]Frame of reference
		-- while bouncing straight up and down.
		-- Nesting the sprite inside an ActorFrame allows us to tween both directions natively.
		Name = "bzbBall"..i,
		Def.Sprite {
			Name = "bzbBallInner"..i,
			Texture = "ball.png",
			InitCommand = function(self)
				--TODO: follow splines
				self:aux( tonumber(string.match(self:GetName(), "([0-9]+)")) )
					:xy(BTIUtil_SideSign(i) * 288, 0)
					:z(0);
			end,
			BZBThrowMessageCommand = function(self)
				self:stoptweening()
					:sleep(4 / BPS)
					:queuecommand("BZBDrop");
			end,
			BZBDropCommand = function(self)
				local bd = BZBData[self:getaux()];
				
				if bd.succ then
					local t_bounce 	 = 0.75;	-- 			(bd.x_bounce 	- bd.x_throw)	 / bd.vx;
					local t_rebounce = 0.75;	-- 0.5 * 	(bd.x_rebounce 	- bd.x_bounce)	 / bd.vx;
					local t_edge 	 = 0.5;		-- 			(bd.x_edge 		- bd.x_rebounce) / bd.vx;
					self:x( bd.x_throw )
						:linear( t_bounce / BPS )
						:x( bd.x_bounce )
						:linear( t_rebounce / BPS )
						:x((bd.x_bounce + bd.x_rebounce) / 2)
						:linear( t_edge / BPS )
						:x( bd.x_edge )
						:sleep(0.5 / BPS)
						:queuecommand("BZBReset")
						:x( bd.x_throw );
				else
					local t_bounce 	 = 0.75;	--			(bd.x_bounce 	- bd.x_throw)	 / bd.vx;
					local t_rebounce = 0.375;	-- 0.5 *	(bd.x_rebounce 	- bd.x_bounce)	 / bd.vx;
					local t_end 	 = 0.5;		--			(bd.x_end 		- bd.x_rebounce) / bd.vx;
					self:x( bd.x_throw )
						:linear( t_bounce / BPS )
						:x( bd.x_bounce )
						:linear( t_rebounce / BPS )
						:x((bd.x_bounce + bd.x_rebounce) / 2)
						:linear( t_rebounce / BPS )
						:x( bd.x_rebounce )
						:linear( t_end / BPS )
						:x( bd.x_end )
						:sleep(0.5 / BPS)
						:queuecommand("BZBReset");
				end
			end,
			BZBResetMessageCommand = function(self)
				local bd = BZBData[self:getaux()];
				self:stoptweening()
					:x( bd.x_throw );
			end,
		},
		InitCommand = function(self)
			--TODO: follow splines
			self:aux( tonumber(string.match(self:GetName(), "([0-9]+)")) )
				:xy(0, 84)
				:z(0.3);
		end,
		BZBUpdateMessageCommand = function(self)
			self:y( BZBData[self:getaux()].y_throw );
		end,
		BZBThrowMessageCommand = function(self)
			self:stoptweening()
				:sleep(4 / BPS)
				:queuecommand("BZBDrop");
		end,
		BZBDropCommand = function(self)
			local bd = BZBData[self:getaux()];
			
			if bd.succ then
				local t_bounce 	 = 0.75;	-- 			(bd.x_bounce 	- bd.x_throw)	 / bd.vx;
				local t_rebounce = 0.75;	-- 0.5 * 	(bd.x_rebounce 	- bd.x_bounce)	 / bd.vx;
				local t_edge 	 = 0.5;		-- 			(bd.x_edge 		- bd.x_rebounce) / bd.vx;
				self:y( bd.y_throw )
					:accelerate( t_bounce / BPS )
					:y( bd.y_table )
					:decelerate( t_rebounce / BPS )
					:y( bd.y_bounce )
					:accelerate( t_edge / BPS )
					:y( bd.y_edge )
					:sleep(0.5 / BPS)
					:queuecommand("BZBReset");
			else
				local t_bounce 	 = 0.75;	--			(bd.x_bounce 	- bd.x_throw)	 / bd.vx;
				local t_rebounce = 0.375;	-- 0.5 *	(bd.x_rebounce 	- bd.x_bounce)	 / bd.vx;
				local t_end 	 = 0.5;		--			(bd.x_end 		- bd.x_rebounce) / bd.vx;
				self:y( bd.y_throw )
					:accelerate( t_bounce / BPS )
					:y( bd.y_table )
					:decelerate( t_rebounce / BPS )
					:y( bd.y_bounce )
					:accelerate( t_rebounce / BPS )
					:y( bd.y_table )
					:decelerate( t_end / BPS )
					:y( bd.y_end )
					:sleep(0.5 / BPS)
					:queuecommand("BZBReset");
			end
		end,
		BZBResetMessageCommand = function(self)
			local bd = BZBData[self:getaux()];
			self:stoptweening()
				:y( bd.y_throw );
		end,
	}
	BZBFrame[#BZBFrame + 1] = Def.ActorMultiVertex {
		-- Draw the trajectory hit for each player.
		Name = "bzbTrail"..i,
		InitCommand = function(self)
			self:aux( tonumber(string.match(self:GetName(), "([0-9]+)")) )
				:SetLineWidth(lineWidth)
				:SetDrawState{Mode = "DrawMode_LineStrip", First = 1, Num = -1}
				:SetVertices({})
				:xy(0, 0)
				:z(0.25);
		end,
		BZBUpdateMessageCommand = function(self)
			local verts = BZBUpdateDataModel(self:getaux(), 0.1);			
			self:SetDrawState{Num = -1}
				:SetVertices(verts)
				:SetDrawState{Num = (#verts - 1)};
		end,
	}
	BZBFrame[#BZBFrame + 1] = Def.Sprite {
		Name = "bzbRSCFront"..i,
		Texture = "rsc-hi.png",
		InitCommand = function(self)
			self:aux( tonumber(string.match(self:GetName(), "([0-9]+)")) )
				:xy(BTIUtil_SideSign(i) * 64, 313)
				:zoom(0.75)
				:z(0.35);
		end,
	}
	for sfi = 1,totalAttempts do
		BZBFrame[#BZBFrame + 1] = Def.Sprite {
			Name = "bzbSucc"..i.."_"..sfi,
			Texture = "succ.png",
			InitCommand = function(self)
				local xi = 			  (sfi-1) % resultRowLength;
				local yi = math.floor((sfi-1) / resultRowLength);
				self:xy(BTIUtil_SideSign(i) * (32 + 256 * xi / resultRowLength), 420 + 32 * yi)
					:z(0.4)
					:diffusealpha(0.0);
			end,
			["P"..i.."RecordSucc"..sfi.."MessageCommand"] = function(self)
				self:diffusealpha(0.0)
					:zoom(0.5)
					:bounceend(0.5)
					:diffusealpha(1.0)
					:zoom(1.0);
			end,
		}		
		BZBFrame[#BZBFrame + 1] = Def.Sprite {
			Name = "bzbFail"..i.."_"..sfi,
			Texture = "fail.png",
			InitCommand = function(self)
				local xi = 			  (sfi-1) % resultRowLength;
				local yi = math.floor((sfi-1) / resultRowLength);
				self:xy(BTIUtil_SideSign(i) * (32 + 256 * xi / resultRowLength), 420 + 32 * yi)
					:z(0.4)
					:diffusealpha(0.0);
			end,
			["P"..i.."RecordFail"..sfi.."MessageCommand"] = function(self)
				self:diffusealpha(0.0)
					:zoom(0.5)
					:bounceend(0.5)
					:diffusealpha(1.0)
					:zoom(1.0);
			end,
		}
	end	
	
	local bzbReceptorNames = {
		"Left",
		"Down",
		"Up",
		"Right"
	};
	local bzbReceptorPlacement = {
		{-1,  0,  90},
		{ 0,  1,   0},
		{ 0, -1, 180},
		{ 1,  0, -90}
	};
	local bzbReceptorsThisSide = Def.ActorFrame {
		InitCommand = function(self)
			self:xy(BTIUtil_SideSign(i) * 112, 80);
		end,
	}
	for rcpi = 1,4 do
		bzbReceptorsThisSide[#bzbReceptorsThisSide + 1] = NOTESKIN:LoadActorForNoteSkin("Down", "Receptor", "cyber") ..{
			-- Realistic as possible!
			Name = "bzbReceptor"..i.."_"..rcpi,
			InitCommand = function(self)
				self:x(bzbReceptorPlacement[rcpi][1] * 33)
					:y(bzbReceptorPlacement[rcpi][2] * 33)
					:rotationz(bzbReceptorPlacement[rcpi][3])
					:zoom(0.75)
					:z(0.5)
					:diffusealpha(0.3);
			end,
			["P"..i..bzbReceptorNames[rcpi].."OnMessageCommand"] = function(self)
				self:diffusealpha(1.0);
				
				local pn, di = string.match(self:GetName(), "([0-9]+)_([0-9]+)");
				BZBInput[tonumber(pn)][1][tonumber(di)] = true;
			end,
			["P"..i..bzbReceptorNames[rcpi].."OffMessageCommand"] = function(self)
				self:diffusealpha(0.3);
				
				local pn, di = string.match(self:GetName(), "([0-9]+)_([0-9]+)");
				BZBInput[tonumber(pn)][1][tonumber(di)] = false;
			end,
		}
	end
	for ctdi = 1,4 do
		bzbReceptorsThisSide[#bzbReceptorsThisSide + 1] = Def.Sprite {
			Name = "bzbCountdown"..i.."_"..(4-ctdi),
			Texture = "ctd"..(4-ctdi)..".png",
			InitCommand = function(self)
				self:aux( tonumber(string.match(self:GetName(), "_([0-9]+)")) )
					:xy(0, 0)
					:z(0.6)
					:diffuse(BTIUtil_Scale(ctdi, 1.0, 4.0, 1.0, 0.0), 1.0, 0.0, 0.0)
					--:visible(false);
			end,
			BZBThrowMessageCommand = function(self)
				local myIndex = self:getaux();
				self:xy(0, 0)
					:zoom(0.5)
					:sleep((3-myIndex) / BPS)
					:diffusealpha(1.0)
					:bounceend(1.0 / BPS)
					:zoom(1.0)
					:queuecommand("TickOver");
			end,
			TickOverCommand = function(self)
				self:diffusealpha(0.0);
			end,
		}
	end	
	BZBFrame[#BZBFrame + 1] = bzbReceptorsThisSide;
		
	BZBFrame[#BZBFrame + 1] = Def.Sprite {
		Name = "bzbRating"..i,
		Texture = "ratings 1x5.png",
		InitCommand = function(self)
			self:aux( tonumber(string.match(self:GetName(), "([0-9]+)")) )
				:xy(BTIUtil_SideSign(i) * 160, 160)
				:z(1.0)
				:animate(0)
				:diffusealpha(0.0)
				--:visible(false);
		end,
		BZBRateMyProfessorMessageCommand = function(self)
			local bd = BZBData[self:getaux()];
			self:setstate(BZBRateMyProfessor(bd.totalSucc))
				:zoom(0.5)
				:decelerate(1.0 / BPS)
				:diffusealpha(1.0)
				:zoom(1.0)
				:sleep(2.0 / BPS)
				:accelerate(1.0 / BPS)
				:diffusealpha(0.0);
		end,
	}
end


table.insert(theBoys, BZBFrame);

--
-- 		BUZZIBEE no jutsu
--
-------------------------------------------------------------------------------


theBoys[#theBoys+1] = Def.Quad{
	InitCommand=function(self)
		self:Center()
			:SetWidth(sw)
			:SetHeight(sh)
			:diffuse(0.0, 0.0, 0.0, 0.0);
	end,
	OnCommand=function(self)
		self:z(0.8)
			:diffusealpha(0.0);
	end,
	BZBInGameStepsMessageCommand=function(self)
		inSession = false;
		self:diffusealpha(0.0)
			:decelerate(1.0 / BPS)
			:diffusealpha(0.5)
			:queuecommand("BZBWaitForSteps");
	end,
	BZBWaitForStepsCommand=function(self)
		inSession = false;
		self:sleep(4.0 / BPS)
			:queuecommand("BZBReturnToGame");
	end,
	BZBReturnToGameCommand=function(self)
		inSession = true;
		self:decelerate(1.0 / BPS)
			:diffusealpha(0.0);
	end,
};





-------------------------------------------------------------------------------
--
-- 		Proxies (as usual)
--
--		idk, let's make three. to have
--
local proxyCount = 3;
local circlingAroundXExtent = sw/4;
local circlingAroundYExtent = sh/12;

local remPlayerLoc = {
	{nil, nil},
	{nil, nil}
};

for pn = 1,2 do
	for i = 1,proxyCount do
		theBoys[#theBoys + 1] = Def.ActorFrame {	
			Name = "ProxyP"..pn.."Outer_"..i,
			Def.ActorFrame {	
				Name = "ProxyP"..pn.."Inner_"..i,
				Def.ActorProxy {					
					Name = "ProxyP"..pn,
					InitCommand = function(self)
						self:aux( tonumber(string.match(self:GetName(), "[0-9]")) );
					end,
					BeginCommand=function(self)
						local McCoy = SCREENMAN:GetTopScreen():GetChild('PlayerP'..self:getaux());
						if McCoy then self:SetTarget(McCoy); else self:hibernate(1573); end
					end,
					OnCommand=function(self)
						local McCoy = SCREENMAN:GetTopScreen():GetChild('PlayerP'..self:getaux());
						if McCoy then 
							remPlayerLoc[pn][1] = McCoy:GetX();
							remPlayerLoc[pn][2] = McCoy:GetY();
							self:xy(-McCoy:GetX(), -McCoy:GetY()); 
							self:GetParent():xy(McCoy:GetX(), McCoy:GetY()); 
						end
					end,
					RecenterProxyMessageCommand=function(self)					
						local McCoy = SCREENMAN:GetTopScreen():GetChild('PlayerP'..self:getaux());
						if McCoy then 
							remPlayerLoc[pn][1] = McCoy:GetX();
							remPlayerLoc[pn][2] = McCoy:GetY();
							self:xy(-McCoy:GetX(), -McCoy:GetY()); 
							self:GetParent():xy(McCoy:GetX(), McCoy:GetY()); 
						end
					end
				},
				InitCommand = function(self)
					self:aux( tonumber(string.match(self:GetName(), "_([0-9]+)")) );
				end,
				OnCommand = function(self)
--					self:xy(remPlayerLoc[pn][1], remPlayerLoc[pn][2]);
				end,
				
				
				["CirclingAroundP"..pn.."MessageCommand"] = function(self)
					local offset = (self:getaux()-1 + 1.5*(pn - 1));
					self:decelerate((2 + offset) * (8/proxyCount) / BPS)
						:addy(circlingAroundYExtent)
						:queuecommand("CircleUp");
				end,
				CircleUpCommand = function(self)
					self:smooth(4.0/BPS)
						:addy(-2 * circlingAroundYExtent)
						:queuecommand("CircleDown");
				end,
				CircleDownCommand = function(self)
					self:smooth(4.0/BPS)
						:addy(2 * circlingAroundYExtent)
						:queuecommand("CircleUp");
				end,
				["CirclingEndP"..pn.."MessageCommand"] = function(self)
					self:stoptweening()
						:smooth(1.0/BPS)
						:xy(remPlayerLoc[pn][1], remPlayerLoc[pn][2]);
				end,
			
			
				PunishDrunksMessageCommand = function(self)
					local pn = tonumber(string.match(self:GetName(), "ProxyP([0-9])"));
					self:decelerate(4.0/BPS)
						:addx(sw * 0.25 * BTIUtil_SideSign(pn))
						:queuecommand("WagLeft");
				end,
				WagLeftCommand = function(self)
					local pn = tonumber(string.match(self:GetName(), "ProxyP([0-9])"));
					local strength = (1 - (BZBData[pn].totalSucc / totalAttempts));
					Trace("pn = "..pn);
					self:smooth(1.0 / BPS)
						:rotationz(-45 * strength*strength)
						:rotationy(-60 * strength*strength)
						:queuecommand("WagRight");
				end,
				WagRightCommand = function(self)
					local pn = tonumber(string.match(self:GetName(), "ProxyP([0-9])"));
					local strength = (1 - (BZBData[pn].totalSucc / totalAttempts));
					self:smooth(1.0 / BPS)
						:rotationz( 45 * strength*strength)
						:rotationy( 60 * strength*strength)
						:queuecommand("WagLeft");
				end,
				
				PunishmentCompleteMessageCommand = function(self)
					local pn = tonumber(string.match(self:GetName(), "ProxyP([0-9])"));
					self:stopeffect()
						:stoptweening()
						:decelerate(4.0/BPS)
						:addx(sw * -0.25 * BTIUtil_SideSign(pn))
						:rotationz(0)
						:rotationy(0);
				end,
			},
			InitCommand = function(self)
				self:aux( tonumber(string.match(self:GetName(), "_([0-9]+)")) );
			end,
			OnCommand = function(self)
				self:xy(0, 0)
					:z(1);
			end,
			["CirclingAroundP"..pn.."MessageCommand"] = function(self)
				local offset = (self:getaux()-1 + 1.5*(pn - 1));
				self:decelerate(offset * (8/proxyCount) / BPS)
					:addx(circlingAroundXExtent)
					:queuecommand("CircleLeft");
			end,
			CircleLeftCommand = function(self)
				self:smooth(4.0/BPS)
					:addx(-2 * circlingAroundXExtent)
					:queuecommand("CircleRight");
			end,
			CircleRightCommand = function(self)
				self:smooth(4.0/BPS)
					:addx(2 * circlingAroundXExtent)
					:queuecommand("CircleLeft");
			end,
			["CirclingEndP"..pn.."MessageCommand"] = function(self)
				self:stoptweening()
					:smooth(1.0/BPS)
					:xy(0, 0);
			end,
			
			
--			["CirclingAroundP"..(3-pn).."MessageCommand"] = function(self)
--				self:visible(false);
--			end,
--			["CirclingEndP"..(3-pn).."MessageCommand"] = function(self)
--				self:sleep(1.0/BPS)
--					:visible(true);
--			end,
		}
	end
end



--
-- Judgment proxies
--
for pn = 1,2 do
	theBoys[#theBoys + 1] = Def.ActorProxy {
		Name = "JudgeP"..pn.."Proxy",
		BeginCommand = function(self)
			local McCoy = SCREENMAN:GetTopScreen():GetChild('PlayerP'..pn):GetChild('Judgment');
			if McCoy then 
				self:SetTarget(McCoy); 
				McCoy:visible(false);
			else 
				self:hibernate(1573);
			end
		end,
		OnCommand = function(self)
			local pn = string.match(self:GetName(), "[0-9]");
			self:xy( sw * (4*pn - 3)/6, sh/2)
				:zoom(0.8);
		end,
	}
end

--
-- 		Proxies (as usual)
--
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
--
--		Some ghosting!
--
local ghostColors = {{0.0, 1.0, 1.0, 0.0},
					 {1.0, 0.3, 0.3, 0.0}};
local nGhosts = #ghostColors;
for pn = 1,2 do
	for ghostIndex = 1,nGhosts do
		local aftMemoryName = "MemoryP"..pn.."_"..ghostIndex;
		local aftOutputName = "OutputP"..pn.."_"..ghostIndex;
		local ghostBoyName  = "GhostP" ..pn.."_"..ghostIndex;
		local aftOutSprName = "SpriteP"..pn.."_"..ghostIndex;
		
		local aftMemory = 
			Def.ActorFrameTexture{
				Name = aftMemoryName,
				InitCommand=function(self)
					self:SetTextureName( self:GetName() )
						:SetWidth( sw )
						:SetHeight( sh )
						:EnableAlphaBuffer( true )
						:Create();
				end,
				Def.Sprite{Name = "Sprite"; InitCommand=cmd(Center) }
			};

		local aftOutput = 
			Def.ActorFrameTexture{
				Name = aftOutputName,
				InitCommand=function(self)
					self:SetTextureName( self:GetName() )
						:SetWidth( sw ) -- change these to simulate textures being drawn away from source
						:SetHeight( sh ) -- change these to simulate textures being drawn away from source
						:EnableAlphaBuffer( true )
						:Create();
						
					myMemoryName = "Memory"..string.match(self:GetName(), "Output(P[12]_[0-9]+)");
					Trace(myMemoryName);
					self:GetParent():GetChild(myMemoryName):GetChild("Sprite"):SetTexture( self:GetTexture() );
				end,
				Def.Sprite{	
					Name = aftOutSprName,
					Texture = aftMemoryName,
					InitCommand=function(self)
					end,
					BeginCommand=function(self)
						local myColorIndex = tonumber(string.match(self:GetName(), "SpriteP[12]_([0-9]+)"));
						self:Center()
							:rotationz(myColorIndex * 4 - 6)
							:zoom(1.003)
							:diffuse({1,1,1,0.99})
							:visible(true);
					end,
					["StopTrailP"..pn.."MessageCommand"]=function(self)
						self:diffuse({1,1,1,0.0});
					end,
					["StartTrailP"..pn.."MessageCommand"]=function(self)
						self:diffuse({1,1,1,0.99});
					end
				},
				Def.ActorProxy {					
					Name = "ProxyP"..pn,
					BeginCommand=function(self)
						local pn = string.match(self:GetName(), "ProxyP([12])");
						local p = self:GetParent()
									  :GetParent()
									  :GetChild('ProxyP'..pn.."Outer_1")
									  :GetChild('ProxyP'..pn.."Inner_1");
						self:SetTarget(p);
					end,
					OnCommand=function(self)
						self:xy(0, 0);
					end
				}
			};
			
		local ghostBoy = 
			Def.Sprite{
				Name = ghostBoyName,
				Texture = aftOutputName,
				InitCommand=cmd(Center),
				OnCommand=function(self)
					local myColorIndex = tonumber(string.match(self:GetName(), "GhostP[12]_([0-9]+)"));
					Trace("myColorIndex: "..myColorIndex);
					self:z(3)
						:blend("BlendMode_Add")
						:diffuse(ghostColors[myColorIndex])
						:visible(false);
				end,
				PunishDrunksMessageCommand=function(self)
					local pn = tonumber(string.match(self:GetName(), "GhostP([12])"));
					self:visible(true)
						:diffusealpha(0.0)
						:decelerate(4.0 / BPS)
						:diffusealpha( 1 - (BZBData[pn].totalSucc / totalAttempts) );					
				end,
				PunishmentCompleteMessageCommand=function(self)
					self:decelerate(8.0/BPS)
						:diffusealpha(0.0)
						:queuecommand("DisappearMe");
				end,
				DisappearMeCommand=function(self)
					self:visible(false);
				end,
				
			};
			
		table.insert(theBoys, aftMemory);
		table.insert(theBoys, aftOutput);
		table.insert(theBoys, ghostBoy);
	end
end

--
-- Special bell ghost
--
theBoys[#theBoys+1] = Def.Quad{
		InitCommand=function(self)
			self:Center()
				:SetWidth(sw)
				:SetHeight(sh)
				:diffuse(0.0, 0.0, 0.0, 0.0);
		end,
		OnCommand=function(self)
			self:z(3.5)
				:diffusealpha(0.0);
		end,
		BellDingMessageCommand=function(self)
			self:diffusealpha(1.0)
				:accelerate(4.0 / BPS)
				:diffusealpha(0.0)
		end,
		DoublingMessageCommand=function(self)
			-- Lead-in: 1 beat
			self:diffusealpha(0.0)
				:accelerate(2.0 / BPS)
				:diffusealpha(1.0)
				:accelerate(3.0 / BPS)
				:diffusealpha(0.0)
		end,
	};
	
	
theBoys[#theBoys+1] = Def.ActorFrameTexture{
		Name = "BellGhostMemory",
		InitCommand=function(self)
			self:SetTextureName( self:GetName() )
				:SetWidth( sw )
				:SetHeight( sh )
				:EnableAlphaBuffer( true )
				:Create();
		end,
		Def.Sprite{Name = "Sprite"; InitCommand=cmd(Center;blend,"BlendMode_Add") }
	};

theBoys[#theBoys+1] = Def.ActorFrameTexture{
		Name = "BellGhostOutput",
		InitCommand=function(self)
			self:SetTextureName( self:GetName() )
				:SetWidth( sw ) -- change these to simulate textures being drawn away from source
				:SetHeight( sh ) -- change these to simulate textures being drawn away from source
				:EnableAlphaBuffer( true )
				:Create();
				
			self:GetParent():GetChild("BellGhostMemory"):GetChild("Sprite"):SetTexture( self:GetTexture() );
		end,
		Def.Sprite{	
			Texture = "BellGhostMemory",
			InitCommand=function(self)
			end,
			BeginCommand=function(self)
				self:Center()
					:zoom(0.99)
					:diffuse({1,1,1,0.995})
					:blend("BlendMode_Add")
					:visible(true);
			end,
			StopTrailMessageCommand=function(self)
				self:diffuse({1,1,1,0.0});
			end,
			StartTrailMessageCommand=function(self)
				self:diffuse({1,1,1,0.995});
			end
		},
		Def.ActorFrame {
			Def.ActorFrame {
				Def.ActorProxy {					
					Name = "ProxyP1",
					BeginCommand=function(self)
						local p = SCREENMAN:GetTopScreen():GetChild('PlayerP1');
						self:SetTarget(p);
					end,
					BellDingMessageCommand=function(self)
						local p = SCREENMAN:GetTopScreen():GetChild('PlayerP1');
						self:xy(-p:GetX(), -p:GetY());
					end,
				},
				OnCommand=function(self)
					self:xy(sw * 1/6, 0.375*sh)
						:zoom(0.5);
				end,
			},
			Def.ActorFrame {
				Def.ActorProxy {					
					Name = "ProxyP2",
					BeginCommand=function(self)
						local p = SCREENMAN:GetTopScreen():GetChild('PlayerP2');
						self:SetTarget(p);
					end,
					BellDingMessageCommand=function(self)
						local p = SCREENMAN:GetTopScreen():GetChild('PlayerP2');
						self:xy(-p:GetX(), -p:GetY());
					end,
				},
				OnCommand=function(self)
					self:xy(sw * 5/6, 0.375*sh)
						:zoom(0.5);
				end,
			},
			BellDingMessageCommand=function(self)
				-- Assume both are minified to the same strength.
				pops = GAMESTATE:GetPlayerState("PlayerNumber_P1"):GetPlayerOptions("ModsLevel_Song");
				local myMini = pops:Mini();
				local mySSpd = pops:ScrollSpeed();
				self:y(sh/2-100*(1-myMini/2)*mySSpd)
					:linear(6.0 / BPS)
					:y(sh/2+100*(1-myMini/2)*mySSpd)
					:queuecommand("Reset");
			end,
			ResetCommand = function(self)
				self:y(0);
			end,
		},
	};
	
theBoys[#theBoys+1] = Def.Sprite{
		Name = "BellGhost",
		Texture = "BellGhostOutput",
		InitCommand=cmd(Center),
		OnCommand=function(self)
			self:z(4)
				:blend("BlendMode_Add")
				:diffusealpha(0.0);
		end,
		BellDingMessageCommand=function(self)
			self:diffusealpha(1.0)
				:accelerate(4.0 / BPS)
				:diffusealpha(0.0)
		end,
	};
	
table.insert(theBoys, aftMemory);
table.insert(theBoys, aftOutput);
table.insert(theBoys, ghostBoy);

--
--		Some ghosting!
--
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
--
-- 		Doubles mode. You need both feet to play this game
--
local LOG2  = math.log(2.0);
local tw = math.exp(math.ceil(math.log(sw)/LOG2) * LOG2);
local th = math.exp(math.ceil(math.log(sh)/LOG2) * LOG2);

local dspd			= 2.0;				-- special scroll speed for this section (to accommodate driven drop)
local dblMinify		= 0.8;				-- using mini mod. unity is fullsize
local dblSideW		= 576*dblMinify;	-- slightly larger
local dblSideH		= 256*dblMinify;	-- slightly larger
local dblSideOff	= 576*dblMinify;	-- bring the AMV up to meet the arrows
local dblShift		= 512*dblMinify;	-- driven drop distance

local dblRTLVerts = {
		{{-dblSideW/2, -dblSideH/2 + dblSideOff/2, 0}, Color.White, {0.5*(sw - dblSideW)/tw, 0.5*(sh - dblSideH + dblSideOff)/th}},
		{{ dblSideW/2, -dblSideH/2 - dblSideOff/2, 0}, Color.White, {0.5*(sw + dblSideW)/tw, 0.5*(sh - dblSideH - dblSideOff)/th}},
		{{ dblSideW/2,  dblSideH/2 - dblSideOff/2, 0}, Color.White, {0.5*(sw + dblSideW)/tw, 0.5*(sh + dblSideH - dblSideOff)/th}},
		{{-dblSideW/2,  dblSideH/2 + dblSideOff/2, 0}, Color.White, {0.5*(sw - dblSideW)/tw, 0.5*(sh + dblSideH + dblSideOff)/th}},
	};
local dblLTRVerts = {
		{{ dblSideW/2, -dblSideH/2 + dblSideOff/2, 0}, Color.White, {0.5*(sw + dblSideW)/tw, 0.5*(sh - dblSideH + dblSideOff)/th}},
		{{-dblSideW/2, -dblSideH/2 - dblSideOff/2, 0}, Color.White, {0.5*(sw - dblSideW)/tw, 0.5*(sh - dblSideH - dblSideOff)/th}},
		{{-dblSideW/2,  dblSideH/2 - dblSideOff/2, 0}, Color.White, {0.5*(sw - dblSideW)/tw, 0.5*(sh + dblSideH - dblSideOff)/th}},
		{{ dblSideW/2,  dblSideH/2 + dblSideOff/2, 0}, Color.White, {0.5*(sw + dblSideW)/tw, 0.5*(sh + dblSideH + dblSideOff)/th}},
	};

theBoys[#theBoys+1] = Def.ActorMultiVertex {
	Name = "DoublingAMV",
	InitCommand=function(self)
	end,
	OnCommand=function(self)
		for i = 1,4 do
			Trace("## ["..i.."][1] = {"..dblRTLVerts[i][1][1]..", "..dblRTLVerts[i][1][2]..", "..dblRTLVerts[i][1][3].."}!");
			Trace("## ["..i.."][2] = {"..dblRTLVerts[i][2][1]..", "..dblRTLVerts[i][2][2]..", "..dblRTLVerts[i][2][3]..", "..dblRTLVerts[i][2][4].."}!");
			Trace("## ["..i.."][3] = {"..dblRTLVerts[i][3][1]..", "..dblRTLVerts[i][3][2].."}!");
		end

		self:visible(false)
			:xy(sw/2, sh/2)
			:z(5)
			:SetVertices(dblRTLVerts)
			:SetDrawState{Mode = "DrawMode_Quads", First = 1, Num = 4};
	end,
	DoublingMessageCommand=function(self, dir)
		local verts = {};
		if dir[1] == "RTL" then
			verts = dblRTLVerts;
		elseif dir[1] == "LTR" then
			verts = dblLTRVerts;
		end
		-- Lead-in: 1 beat
		local p = SCREENMAN:GetTopScreen():GetChild('PlayerP1');
		self:visible(true)
			:SetVertices(verts)
			:diffusealpha(0.0)
			:linear(1.0 / BPS)
			:diffusealpha(1.0)
			:queuecommand("Double");
	end,
	DoubleCommand=function(self)
		self:linear(4.0 / BPS)
			:addy(0)
			:linear(1.0 / BPS)
			:diffusealpha(0.0)
			:queuecommand("DoublingOver");
	end,
	DoublingOverCommand=function(self)
		self:visible(false);
	end,
}


theBoys[#theBoys+1] = Def.ActorFrameTexture {
	Name = "DoublingAFT",
	InitCommand=function(self)
		self:SetTextureName( self:GetName() )
			:SetWidth( sw )
			:SetHeight( sh )
			:xy(0, 0)
			:EnableAlphaBuffer( true )
			:Create();			
			
		self:GetParent():GetChild("DoublingAMV"):SetTexture( self:GetTexture() );
	end,
	OnCommand=function(self)
		for pn = 1,2 do
			local p = SCREENMAN:GetTopScreen():GetChild('PlayerP' .. pn);
			self:GetChild("ProxyP" .. pn)
				:SetTarget(p)
				:xy(BTIUtil_SideSign(pn) * 128 * dblMinify, 0);
		end
	end,
	DoublingMessageCommand=function(self)
		-- Lead-in: 1 beat
		self:sleep(1.0 / BPS)
			:queuecommand("Double");
	end,
	DoubleCommand = function(self)
		for pn = 1,2 do
			local p = SCREENMAN:GetTopScreen():GetChild('PlayerP' .. pn);
			self:GetChild("ProxyP" .. pn)
				:xy(BTIUtil_SideSign(pn) * 128 * dblMinify, 0)
				:linear(4.0 / BPS)
				:addy(dblShift);
		end
	end,
	
	Def.ActorProxy {Name = "ProxyP1"},
	Def.ActorProxy {Name = "ProxyP2"},
}

local dblRcps = Def.ActorFrame {
	Name = "DoublingReceptors",
	InitCommand=function(self)
	end,
	OnCommand=function(self)
		local p = SCREENMAN:GetTopScreen():GetChild('PlayerP1');
		self:visible(false)
			:xy(sw/2, p:GetY()-128)
			:z(3.8);
	end,
	DoublingMessageCommand=function(self)
		-- Lead-in: 1 beat
		local p = SCREENMAN:GetTopScreen():GetChild('PlayerP1');
		self:y(p:GetY()-128)
			:sleep(1.0 / BPS)
			:queuecommand("Double");
	end,
	DoubleCommand = function(self)
		self:visible(true)
			:linear(4.0 / BPS)
			:addy(dblShift)
			:queuecommand("DoublingOver");
	end,
	DoublingOverCommand=function(self)
		self:visible(false);
	end,
}

rcpRotation = {90, 0, 180, -90, 90, 0, 180, -90};
for rcpi = 1,8 do
	dblRcps[#dblRcps+1] = NOTESKIN:LoadActorForNoteSkin("Down", "Receptor", "cyber") ..{
		InitCommand=function(self)
			self:xy((rcpi-4.5)*64*dblMinify, 0)
				:zoom(dblMinify)
				:rotationz(rcpRotation[rcpi]);
		end,
	}
end

theBoys[#theBoys+1] = dblRcps;

--
--		Doubles mode. You need both feet to play this game
--
-------------------------------------------------------------------------------



-------------------------------------------------------------------------------
--
-- 		Opening/Closing stuff
--

theBoys[#theBoys+1] = Def.Quad {
	Name = "InOutCtrl",
	InitCommand = function(self)
		self:SetHeight(6)
			:SetWidth(6)
			:xy(-sw,-sh)
			:visible(false);
	end,
	OnCommand = function(self)
		self:aux(0.5);
	end,
	OpenUpMessageCommand = function(self)
		self:linear(64.0 / BPS):aux(1);
	end,
	CloseOutMessageCommand = function(self)
		self:linear(64.0 / BPS):aux(0);
	end,
};

local rcpIntroOutro = Def.ActorFrame {
	Name = "IntroOutro",
	InitCommand = function(self)
		self:xy(sw/2, sh/2);
	end,
	PulseRCPMessageCommand = function(self, swaths)
		local strength = self:GetParent():GetChild("InOutCtrl"):getaux();
		for _,si in pairs(swaths) do
			self:GetChild("Swath"..si)
				:visible(true)
				:diffusealpha(strength)
				:decelerate(4.0/BPS)
				:diffusealpha(0.0);
		end
	end,
	HideRCPMessageCommand = function(self, swaths)
		for _,si in pairs(swaths) do
			self:GetChild("Swath"..si)
				:stoptweening()
				:decelerate(4.0/BPS)
				:diffusealpha(0.0)
				:queuecommand("HideMyself");
		end
	end,
};

local nSwaths = 9;
for si = 1,9 do
	local rcpSwath = Def.ActorFrame {
		Name = "SwathItems"..si,
		InitCommand = function(self)
			self:xy(0, 0);
		end,
		OnCommand = function(self)
			self:aux(-1)
				:queuecommand("Rotater");
		end,
		RotaterCommand = function(self)
			self:aux( self:getaux() * -1 );
			self:smooth((4.0 + math.random() * 4.0) / BPS)
				:rotationz(180 * math.random() * self:getaux())
				:queuecommand("Rotater");
		end,
	}
	
	local nObj = 3 + si;
	for ri = 1,nObj do
		rcpSwath[#rcpSwath + 1] = NOTESKIN:LoadActorForNoteSkin("Down", "Tap Mine", "cyber")..{
			InitCommand = function(self)
				local theta = math.pi * (2 * ri / nObj + 7 * si);
				local reta = (si-0.5) * 0.5 * sw/nSwaths;					-- yes, I know the corresponding Greek letter is "rho". but I wrhote this, not you
				self:xy( math.cos(theta) * reta, math.sin(theta) * reta )
					:zoom(1 - 0.3 * si/nSwaths);
			end,
		}
	end
	
	rcpIntroOutro[#rcpIntroOutro+1] = Def.ActorFrame 
	{
		Name = "Swath"..si,
		InitCommand = function(self)
			self:visible(false);
		end,
		HideMyselfCommand = function(self)
			self:visible(false);
		end,
		rcpSwath,
	};
end

theBoys[#theBoys + 1] = rcpIntroOutro;

--
--		Opening/Closing stuff
--
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
--
-- 		This is where the shit will be happening.
--

local messageList = {
	{	4.0, "RecenterProxy"},
	
	{  8.00, "PulseRCP", {1,4,7}},
	{  8.75, "PulseRCP", {2,5,8}},
	{  9.50, "PulseRCP", {3,6,9}},
	{ 16.00, "PulseRCP", {1,4,7}},
	{ 16.75, "PulseRCP", {2,5,8}},
	{ 17.50, "PulseRCP", {3,6,9}},	
	{ 24.00, "PulseRCP", {1,4,7}},
	{ 24.75, "PulseRCP", {2,5,8}},
	{ 25.50, "PulseRCP", {3,6,9}},
	{ 32.00, "PulseRCP", {1,4,7}},
	{ 32.75, "PulseRCP", {2,5,8}},
	{ 33.50, "PulseRCP", {3,6,9}},
		
	{ 40.00, "PulseRCP", {1,4,9}},
	{ 40.75, "PulseRCP", {2,5,8}},
	{ 41.50, "PulseRCP", {3,6,7}},
	{ 48.00, "PulseRCP", {1,2,6}},
	{ 48.75, "PulseRCP", {3,4,7}},
	{ 49.50, "PulseRCP", {5,8,9}},
	{ 56.00, "PulseRCP", {1,2,4}},
	{ 56.75, "PulseRCP", {3,5,7}},
	{ 57.50, "PulseRCP", {6,8,9}},
	{ 64.00, "PulseRCP", {1,2,3}},
	{ 64.75, "PulseRCP", {4,5,6}},
	{ 65.50, "PulseRCP", {7,8,9}},	
	
	{ 66.00, "HideRCP",  {1,2,3,4,5,6,7,8,9}},
	
	{  76.0, "BellDing"},
	{  92.0, "BellDing"},
	{ 108.0, "BellDing"},
	{ 124.0, "BellDing"},
	
	{ 164.0, "CirclingAroundP1"},
	{ 195.0, "CirclingEndP1"},
	{ 195.0, "Doubling", {"LTR"}},
	{ 196.0, "CirclingAroundP2"},
	{ 215.0, "CirclingEndP2"},
	
	{ 239.5, "BellDing"},
	{ 255.5, "BellDing"},

	
	{ 296.0, "BZBStart"},
	{ 308.0, "BZBThrow"},
	{ 316.0, "BZBThrow"},
	{ 324.0, "BZBThrow"},
	{ 332.0, "BZBThrow"},
	{ 340.0, "BZBThrow"},
	{ 348.0, "BZBThrow"},
	{ 356.0, "BZBThrow"},
	{ 364.0, "BZBThrow"},
	{ 371.0, "BZBInGameSteps"},
	{ 372.0, "BZBThrow"},
	{ 380.0, "BZBThrow"},
	{ 388.0, "BZBThrow"},
	{ 391.0, "BZBVibrate"},
	{ 392.0, "BZBVibrateStop"},
	{ 396.0, "BZBThrow"},
	{ 403.0, "BZBInGameSteps"},
	{ 404.0, "BZBThrow"},
	{ 412.0, "BZBThrow"},
	{ 415.0, "BZBVibrate"},
	{ 416.0, "BZBVibrateStop"},
	{ 420.0, "BZBThrow"},
	{ 423.0, "BZBVibrate"},
	{ 424.0, "BZBVibrateStop"},
	{ 424.0, "BZBAllVibrate"},
	{ 432.0, "BZBThrow"},
	{ 436.0, "BZBAllVibrateStop"},
	{ 436.0, "BZBRateMyProfessor"},
	{ 436.0, "BZBEnd"},
	{ 436.0, "PunishDrunks"},
		
	{ 467.0, "Doubling", {"RTL"}},
	
	{ 488.0, "PunishmentComplete"},
	
	{ 512.0, "BellDing"},
	{ 528.0, "BellDing"},
	
	{ 572.0, "BellDing"},
	{ 588.0, "BellDing"},
	{ 604.0, "BellDing"},
	{ 620.0, "BellDing"},
	
	
	{634.00, "PulseRCP", {4}},
	{636.00, "PulseRCP", {9}},
	{638.00, "PulseRCP", {3}},
	{640.00, "PulseRCP", {8}},
	{642.00, "PulseRCP", {2}},
	{644.00, "PulseRCP", {7}},	
	{646.00, "PulseRCP", {1}},
	
	{650.00, "PulseRCP", {4}},
	{652.00, "PulseRCP", {1}},
	{653.00, "PulseRCP", {3}},
	{654.00, "PulseRCP", {9}},
	{654.75, "PulseRCP", {8}},
	{655.50, "PulseRCP", {7}},	
	{656.00, "PulseRCP", {6}},	
	{658.00, "PulseRCP", {2}},	
	{660.00, "PulseRCP", {5}},	
	{662.00, "PulseRCP", {8}},
	
	{666.00, "PulseRCP", {4}},
	{668.00, "PulseRCP", {9}},
	{670.00, "PulseRCP", {3}},
	{672.00, "PulseRCP", {8}},
	{674.00, "PulseRCP", {2}},
	{676.00, "PulseRCP", {7}},	
	{678.00, "PulseRCP", {1}},
	
	{682.00, "PulseRCP", {4}},
	{684.00, "PulseRCP", {1}},
	{685.00, "PulseRCP", {3}},
	{686.00, "PulseRCP", {9}},
	{686.75, "PulseRCP", {8}},
	{687.50, "PulseRCP", {7}},	
	{688.00, "PulseRCP", {6}},	
	{690.00, "PulseRCP", {2}},	
	{692.00, "PulseRCP", {5}},	
	{694.00, "PulseRCP", {8}},
	
	{696.00, "HideRCP",  {1,2,3,4,5,6,7,8,9}},
};

local fifthProxyEffects = {
	-- proxyEffect[1]: beat number
	-- proxyEffect[2]: mod name (applied as element function of Actor, with a couple exceptions)
	-- proxyEffect[3]: mod strength
	-- proxyEffect[4]: mod length (in beats)
	-- proxyEffect[5]: player application (1 = P1, 2 = P2, 3 = both, 0 = neither)
	--
	-- stag = column-based "skewing", where +1.0 staggers the columns by one arrow height, left highest
	--
--	{ 97.0, "addx",		 sw/12,	 6.0,	1},
--	{ 97.0, "addx",		-sw/12,	 6.0,	2},
--	{ 97.0, "vibrate",	 5.0,	 6.0,	3},
--	
--	{410.0, "rotationz",	360.0,	 5.0,	3, 'smooth'},

	{136.0, "vibrate",	 5.0,	 1.0,	3, {1,2,3}},
	{136.00,"addx",		 16,	15.0,	3, {1}},
	{136.00,"addx",		-16,	15.0,	3, {3}},
	{151.00,"addx",		-16,	 8.0,	3, {1}},
	{151.00,"addx",		 16,	 8.0,	3, {3}},
	{151.0, "vibrate",	 0.0,	 1.0,	3, {1,2,3}},
	{152.0, "vibrate",	10.0,	 1.0,	3, {1,2,3}},
	{160.0, "vibrate",	20.0,	 1.0,	3, {1,2,3}},
	{164.0, "vibrate",	 0.0,	 1.0,	3, {1,2,3}},
	
	{232.00,"skewx",	 1.0,	 1.0,	3, {1,2,3}},
	{233.00,"skewx",	-1.0,	 1.0,	3, {1,2,3}},
	{234.00,"skewx",	 0.7,	 1.0,	3, {1,2,3}},
	{235.00,"skewx",	 0.0,	 0.5,	3, {1,2,3}},
	{235.50,"rotationz",	 15.0,	 1.0,	3, {1,2,3}},
	{236.50,"rotationz",	-15.0,	 1.0,	3, {1,2,3}},
	{237.50,"rotationz",	 15.0,	 1.0,	3, {1,2,3}},
	{238.50,"rotationz",	-15.0,	 1.0,	3, {1,2,3}},
	{239.50,"rotationz",	  0.0,	 0.5,	3, {1,2,3}},
	
	{248.00,"skewx",	-1.0,	 1.0,	3},
	{249.00,"skewx",	 1.0,	 1.0,	3},
	{250.00,"skewx",	-0.7,	 1.0,	3},
	{251.00,"skewx",	 0.0,	 0.5,	3},
	{251.50,"rotationz",	-15.0,	 1.0,	3, {1,2,3}},
	{252.50,"rotationz",	 15.0,	 1.0,	3, {1,2,3}},
	{253.50,"rotationz",	-15.0,	 1.0,	3, {1,2,3}},
	{254.50,"rotationz",	 15.0,	 1.0,	3, {1,2,3}},
	{255.50,"rotationz",	  0.0,	 0.5,	3, {1,2,3}},
	
	
	{280.00,"stag",		 0.17,	 0.01,	3},
	{280.00,"addrotationz",    1,	 0.01,	1},
	{280.00,"addrotationz",    2,	 0.01,	2},
	{280.00,"addy",		 13.3,	 0.01,	3},
	{280.33,"stag",		 0.33,	 0.01,	3},
	{280.33,"addrotationz",    1,	 0.01,	1},
	{280.33,"addrotationz",    2,	 0.01,	2},
	{280.33,"addy",		 13.4,	 0.01,	3},
	{280.67,"stag",		 0.50,	 0.01,	3},
	{280.67,"addrotationz",    1,	 0.01,	1},
	{280.67,"addrotationz",    2,	 0.01,	2},
	{280.67,"addy",		 13.3,	 0.01,	3},
	{281.00,"stag",		 0.67,	 0.01,	3},
	{281.00,"addrotationz",    1,	 0.01,	1},
	{281.00,"addrotationz",    2,	 0.01,	2},
	{281.00,"addy",		 13.3,	 0.01,	3},
	{281.33,"stag",		 0.83,	 0.01,	3},
	{281.33,"addrotationz",    1,	 0.01,	1},
	{281.33,"addrotationz",    2,	 0.01,	2},
	{281.33,"addy",		 13.4,	 0.01,	3},
	{281.67,"stag",		 1.00,	 0.01,	3},
	{281.67,"addrotationz",    1,	 0.01,	1},
	{281.67,"addrotationz",    2,	 0.01,	2},
	{281.67,"addy",		 13.3,	 0.01,	3},
	
	{282.00,"stag",		 0.83,	 0.01,	3},
	{282.00,"addrotationz",   -1,	 0.01,	1},
	{282.00,"addrotationz",   -2,	 0.01,	2},
	{282.00,"addy",		-13.3,	 0.01,	3},
	{282.33,"stag",		 0.67,	 0.01,	3},
	{282.33,"addrotationz",   -1,	 0.01,	1},
	{282.33,"addrotationz",   -2,	 0.01,	2},
	{282.33,"addy",		-13.3,	 0.01,	3},
	{282.67,"stag",		 0.50,	 0.01,	3},
	{282.67,"addrotationz",   -1,	 0.01,	1},
	{282.67,"addrotationz",   -2,	 0.01,	2},
	{282.67,"addy",		-13.3,	 0.01,	3},
	{283.00,"stag",		 0.33,	 0.01,	3},
	{283.00,"addrotationz",   -1,	 0.01,	1},
	{283.00,"addrotationz",   -2,	 0.01,	2},
	{283.00,"addy",		-13.3,	 0.01,	3},
	{283.33,"stag",		 0.17,	 0.01,	3},
	{283.33,"addrotationz",   -1,	 0.01,	1},
	{283.33,"addrotationz",   -2,	 0.01,	2},
	{283.33,"addy",		-13.3,	 0.01,	3},
	{283.67,"stag",		 0.00,	 0.01,	3},
	{283.67,"addrotationz",   -1,	 0.01,	1},
	{283.67,"addrotationz",   -2,	 0.01,	2},
	{283.67,"addy",		-13.3,	 0.01,	3},
	
	{284.00,"stag",		-0.17,	 0.01,	3},
	{284.00,"addrotationz",    2,	 0.01,	1},
	{284.00,"addrotationz",    1,	 0.01,	2},
	{284.00,"addy",		 13.3,	 0.01,	3},
	{284.33,"stag",		-0.33,	 0.01,	3},
	{284.33,"addrotationz",    2,	 0.01,	1},
	{284.33,"addrotationz",    1,	 0.01,	2},
	{284.33,"addy",		 13.4,	 0.01,	3},
	{284.67,"stag",		-0.50,	 0.01,	3},
	{284.67,"addrotationz",    2,	 0.01,	1},
	{284.67,"addrotationz",    1,	 0.01,	2},
	{284.67,"addy",		 13.3,	 0.01,	3},
	{285.00,"stag",		-0.67,	 0.01,	3},
	{285.00,"addrotationz",    2,	 0.01,	1},
	{285.00,"addrotationz",    1,	 0.01,	2},
	{285.00,"addy",		 13.3,	 0.01,	3},
	{285.33,"stag",		-0.83,	 0.01,	3},
	{285.33,"addrotationz",    2,	 0.01,	1},
	{285.33,"addrotationz",    1,	 0.01,	2},
	{285.33,"addy",		 13.4,	 0.01,	3},
	{285.67,"stag",		-1.00,	 0.01,	3},
	{285.67,"addrotationz",    2,	 0.01,	1},
	{285.67,"addrotationz",    1,	 0.01,	2},
	{285.67,"addy",		 13.3,	 0.01,	3},
	
	{286.00,"stag",		-0.83,	 0.01,	3},
	{286.00,"addrotationz",   -2,	 0.01,	1},
	{286.00,"addrotationz",   -1,	 0.01,	2},
	{286.00,"addy",		-13.3,	 0.01,	3},
	{286.33,"stag",		-0.67,	 0.01,	3},
	{286.33,"addrotationz",   -2,	 0.01,	1},
	{286.33,"addrotationz",   -1,	 0.01,	2},
	{286.33,"addy",		-13.3,	 0.01,	3},
	{286.67,"stag",		-0.50,	 0.01,	3},
	{286.67,"addrotationz",   -2,	 0.01,	1},
	{286.67,"addrotationz",   -1,	 0.01,	2},
	{286.67,"addy",		-13.3,	 0.01,	3},
	{287.00,"stag",		-0.33,	 0.01,	3},
	{287.00,"addrotationz",   -2,	 0.01,	1},
	{287.00,"addrotationz",   -1,	 0.01,	2},
	{287.00,"addy",		-13.3,	 0.01,	3},
	{287.33,"stag",		-0.17,	 0.01,	3},
	{287.33,"addrotationz",   -2,	 0.01,	1},
	{287.33,"addrotationz",   -1,	 0.01,	2},
	{287.33,"addy",		-13.3,	 0.01,	3},
	{287.67,"stag",		 0.00,	 0.01,	3},
	{287.67,"addrotationz",   -2,	 0.01,	1},
	{287.67,"addrotationz",   -1,	 0.01,	2},
	{287.67,"addy",		-13.3,	 0.01,	3},
	
	{288.00,"stag",		 0.33,	 0.01,	3},
	{288.00,"addy",		 26.7,	 0.01,	3},
	{288.33,"stag",		 0.67,	 0.01,	3},
	{288.33,"addy",		 26.6,	 0.01,	3},
	{288.67,"stag",		 1.00,	 0.01,	3},
	{288.67,"addy",		 26.7,	 0.01,	3},
	{289.00,"stag",		 0.67,	 0.01,	3},
	{289.00,"addy",		-26.7,	 0.01,	3},
	{289.33,"stag",		 0.33,	 0.01,	3},
	{289.33,"addy",		-26.6,	 0.01,	3},
	{289.67,"stag",		 0.00,	 0.01,	3},
	{289.67,"addy",		-26.7,	 0.01,	3},
	
	{290.00,"stag",		-0.33,	 0.01,	3},
	{290.00,"addy",		 26.7,	 0.01,	3},
	{290.33,"stag",		-0.67,	 0.01,	3},
	{290.33,"addy",		 26.6,	 0.01,	3},
	{290.67,"stag",		-1.00,	 0.01,	3},
	{290.67,"addy",		 26.7,	 0.01,	3},
	{291.00,"stag",		-0.67,	 0.01,	3},
	{291.00,"addy",		-26.7,	 0.01,	3},
	{291.33,"stag",		-0.33,	 0.01,	3},
	{291.33,"addy",		-26.6,	 0.01,	3},
	{291.67,"stag",		-0.00,	 0.01,	3},
	{291.67,"addy",		-26.7,	 0.01,	3},
	
	
	{504.00,"skewx",	 1.0,	 1.0,	3},
	{505.00,"skewx",	-1.0,	 1.0,	3},
	{506.00,"skewx",	 0.7,	 1.0,	3},
	{507.00,"skewx",	 0.0,	 0.5,	3},
	{507.50,"rotationz",	 15.0,	 1.0,	3},
	{508.50,"rotationz",	-15.0,	 1.0,	3},
	{509.50,"rotationz",	 15.0,	 1.0,	3},
	{510.50,"rotationz",	-15.0,	 1.0,	3},
	{511.50,"rotationz",	  0.0,	 0.5,	3},
	
	{520.00,"skewx",	-1.0,	 1.0,	3},
	{521.00,"skewx",	 1.0,	 1.0,	3},
	{522.00,"skewx",	-0.7,	 1.0,	3},
	{523.00,"skewx",	 0.0,	 0.5,	3},
	{523.50,"rotationz",	-15.0,	 1.0,	3},
	{524.50,"rotationz",	 15.0,	 1.0,	3},
	{525.50,"rotationz",	-15.0,	 1.0,	3},
	{526.50,"rotationz",	 15.0,	 1.0,	3},
	{527.50,"rotationz",	  0.0,	 0.5,	3},
	
	
	{552.00,"stag",		 0.17,	 0.01,	3},
	{552.00,"addrotationz",    1,	 0.01,	1},
	{552.00,"addrotationz",    2,	 0.01,	2},
	{552.00,"addy",		 13.3,	 0.01,	3},
	{552.33,"stag",		 0.33,	 0.01,	3},
	{552.33,"addrotationz",    1,	 0.01,	1},
	{552.33,"addrotationz",    2,	 0.01,	2},
	{552.33,"addy",		 13.4,	 0.01,	3},
	{552.67,"stag",		 0.50,	 0.01,	3},
	{552.67,"addrotationz",    1,	 0.01,	1},
	{552.67,"addrotationz",    2,	 0.01,	2},
	{552.67,"addy",		 13.3,	 0.01,	3},
	{553.00,"stag",		 0.67,	 0.01,	3},
	{553.00,"addrotationz",    1,	 0.01,	1},
	{553.00,"addrotationz",    2,	 0.01,	2},
	{553.00,"addy",		 13.3,	 0.01,	3},
	{553.33,"stag",		 0.83,	 0.01,	3},
	{553.33,"addrotationz",    1,	 0.01,	1},
	{553.33,"addrotationz",    2,	 0.01,	2},
	{553.33,"addy",		 13.4,	 0.01,	3},
	{553.67,"stag",		 1.00,	 0.01,	3},
	{553.67,"addrotationz",    1,	 0.01,	1},
	{553.67,"addrotationz",    2,	 0.01,	2},
	{553.67,"addy",		 13.3,	 0.01,	3},
	
	{554.00,"stag",		 0.83,	 0.01,	3},
	{554.00,"addrotationz",   -1,	 0.01,	1},
	{554.00,"addrotationz",   -2,	 0.01,	2},
	{554.00,"addy",		-13.3,	 0.01,	3},
	{554.33,"stag",		 0.67,	 0.01,	3},
	{554.33,"addrotationz",   -1,	 0.01,	1},
	{554.33,"addrotationz",   -2,	 0.01,	2},
	{554.33,"addy",		-13.3,	 0.01,	3},
	{554.67,"stag",		 0.50,	 0.01,	3},
	{554.67,"addrotationz",   -1,	 0.01,	1},
	{554.67,"addrotationz",   -2,	 0.01,	2},
	{554.67,"addy",		-13.3,	 0.01,	3},
	{555.00,"stag",		 0.33,	 0.01,	3},
	{555.00,"addrotationz",   -1,	 0.01,	1},
	{555.00,"addrotationz",   -2,	 0.01,	2},
	{555.00,"addy",		-13.3,	 0.01,	3},
	{555.33,"stag",		 0.17,	 0.01,	3},
	{555.33,"addrotationz",   -1,	 0.01,	1},
	{555.33,"addrotationz",   -2,	 0.01,	2},
	{555.33,"addy",		-13.3,	 0.01,	3},
	{555.67,"stag",		 0.00,	 0.01,	3},
	{555.67,"addrotationz",   -1,	 0.01,	1},
	{555.67,"addrotationz",   -2,	 0.01,	2},
	{555.67,"addy",		-13.3,	 0.01,	3},
	
	{556.00,"stag",		-0.17,	 0.01,	3},
	{556.00,"addrotationz",    2,	 0.01,	1},
	{556.00,"addrotationz",    1,	 0.01,	2},
	{556.00,"addy",		 13.3,	 0.01,	3},
	{556.33,"stag",		-0.33,	 0.01,	3},
	{556.33,"addrotationz",    2,	 0.01,	1},
	{556.33,"addrotationz",    1,	 0.01,	2},
	{556.33,"addy",		 13.4,	 0.01,	3},
	{556.67,"stag",		-0.50,	 0.01,	3},
	{556.67,"addrotationz",    2,	 0.01,	1},
	{556.67,"addrotationz",    1,	 0.01,	2},
	{556.67,"addy",		 13.3,	 0.01,	3},
	{557.00,"stag",		-0.67,	 0.01,	3},
	{557.00,"addrotationz",    2,	 0.01,	1},
	{557.00,"addrotationz",    1,	 0.01,	2},
	{557.00,"addy",		 13.3,	 0.01,	3},
	{557.33,"stag",		-0.83,	 0.01,	3},
	{557.33,"addrotationz",    2,	 0.01,	1},
	{557.33,"addrotationz",    1,	 0.01,	2},
	{557.33,"addy",		 13.4,	 0.01,	3},
	{557.67,"stag",		-1.00,	 0.01,	3},
	{557.67,"addrotationz",    2,	 0.01,	1},
	{557.67,"addrotationz",    1,	 0.01,	2},
	{557.67,"addy",		 13.3,	 0.01,	3},
	
	{558.00,"stag",		-0.83,	 0.01,	3},
	{558.00,"addrotationz",   -2,	 0.01,	1},
	{558.00,"addrotationz",   -1,	 0.01,	2},
	{558.00,"addy",		-13.3,	 0.01,	3},
	{558.33,"stag",		-0.67,	 0.01,	3},
	{558.33,"addrotationz",   -2,	 0.01,	1},
	{558.33,"addrotationz",   -1,	 0.01,	2},
	{558.33,"addy",		-13.3,	 0.01,	3},
	{558.67,"stag",		-0.50,	 0.01,	3},
	{558.67,"addrotationz",   -2,	 0.01,	1},
	{558.67,"addrotationz",   -1,	 0.01,	2},
	{558.67,"addy",		-13.3,	 0.01,	3},
	{559.00,"stag",		-0.33,	 0.01,	3},
	{559.00,"addrotationz",   -2,	 0.01,	1},
	{559.00,"addrotationz",   -1,	 0.01,	2},
	{559.00,"addy",		-13.3,	 0.01,	3},
	{559.33,"stag",		-0.17,	 0.01,	3},
	{559.33,"addrotationz",   -2,	 0.01,	1},
	{559.33,"addrotationz",   -1,	 0.01,	2},
	{559.33,"addy",		-13.3,	 0.01,	3},
	{559.67,"stag",		 0.00,	 0.01,	3},
	{559.67,"addrotationz",   -2,	 0.01,	1},
	{559.67,"addrotationz",   -1,	 0.01,	2},
	{559.67,"addy",		-13.3,	 0.01,	3},
	
	{560.00,"stag",		 0.33,	 0.01,	3},
	{560.00,"addy",		 26.7,	 0.01,	3},
	{560.33,"stag",		 0.67,	 0.01,	3},
	{560.33,"addy",		 26.6,	 0.01,	3},
	{560.67,"stag",		 1.00,	 0.01,	3},
	{560.67,"addy",		 26.7,	 0.01,	3},
	{561.00,"stag",		 0.67,	 0.01,	3},
	{561.00,"addy",		-26.7,	 0.01,	3},
	{561.33,"stag",		 0.33,	 0.01,	3},
	{561.33,"addy",		-26.6,	 0.01,	3},
	{561.67,"stag",		 0.00,	 0.01,	3},
	{561.67,"addy",		-26.7,	 0.01,	3},
	
	{562.00,"stag",		-0.33,	 0.01,	3},
	{562.00,"addy",		 26.7,	 0.01,	3},
	{562.33,"stag",		-0.67,	 0.01,	3},
	{562.33,"addy",		 26.6,	 0.01,	3},
	{562.67,"stag",		-1.00,	 0.01,	3},
	{562.67,"addy",		 26.7,	 0.01,	3},
	{563.00,"stag",		-0.67,	 0.01,	3},
	{563.00,"addy",		-26.7,	 0.01,	3},
	{563.33,"stag",		-0.33,	 0.01,	3},
	{563.33,"addy",		-26.6,	 0.01,	3},
	{563.67,"stag",		-0.00,	 0.01,	3},
	{563.67,"addy",		-26.7,	 0.01,	3},
};
local fifthEffectIndex = 0;


local fifthGfxHQ = Def.Quad {
	InitCommand = function(self)
		self:SetHeight(6)
			:SetWidth(6)
			:xy(-sw,-sh)
			:visible(false);
	end,
	OnCommand = function(self)
		self:queuecommand("Update");
	end,
	UpdateCommand = function(self)
		-- Most things are determined by beat, believe it or not.		
		overtime = GAMESTATE:GetSongBeat();
		
		-- TODO: this assumes the effect applies over a constant BPM section!!
		BPS = GAMESTATE:GetSongBPS();	
		
		-- Who's interesting today?
		if overtime >=   0.0 and fgcurcommand ==  0 then
			for i,v in ipairs(plr) do
				if v then
					v:visible(false):decelerate(2.0 / BPS):x(sw/2):y(sh/2 - 30):z(0);
				end
			end
			
			fgcurcommand = fgcurcommand + 1;
		end
		
		
		
		-- Broadcast messages on their own terms.
		while true do
			if curmessage < #messageList then
				if overtime >= messageList[curmessage+1][1] then			
					if messageList[curmessage+1][3] then
						MESSAGEMAN:Broadcast( messageList[curmessage+1][2], messageList[curmessage+1][3] );
					else
						MESSAGEMAN:Broadcast( messageList[curmessage+1][2] );
					end
					
					curmessage = curmessage + 1;
				else
					break;
				end
			else
				break;
			end
		end
		
		
		
		-- Apply skews and staggers.
		while true do
			if fifthEffectIndex < #fifthProxyEffects then
				local proxyEffect = fifthProxyEffects[fifthEffectIndex+1];				
				if overtime >= proxyEffect[1] then			
					local effFunc 		= proxyEffect[2];
					local effArg  		= proxyEffect[3];
					local effBeats		= proxyEffect[4];
					local effPlayers	= proxyEffect[5];
					local effProxies	= proxyEffect[6];
					local effTweenHint	= proxyEffect[7];
					
					if not effProxies then effProxies = {}; end
										
					for pn = 1,2 do
						if effPlayers == 3 or effPlayers == pn then
							pv = SCREENMAN:GetTopScreen():GetChild("PlayerP"..pn);
							if pv then							
								if effFunc == "stag" then
									pca = pv:GetChild("NoteField"):GetColumnActors();
									for colIndex = 1,4 do
										pca[colIndex]:decelerate(effBeats / BPS)
													 :y(64 * effArg * (colIndex - 2.5));
									end
								else
									if #proxyEffect < 6 then effProxies = {1, 2, 3}; end
									for proxyIndex in ivalues(effProxies) do
										pp = self:GetParent():GetChild("ProxyP"..pn.."Outer_"..proxyIndex):GetChild("ProxyP"..pn.."Inner_"..proxyIndex);
										if effFunc == "vibrate" then
											if effArg <= 0.01 then
												pp:stopeffect();
											else
												pp[effFunc](pp);
												pp:effectmagnitude(effArg, effArg, 0);
											end
										elseif effFunc == "wag" then
											if effArg <= 0.01 then
												pp:stopeffect();
											else
												pp[effFunc](pp);
												pp:effectperiod(2);
												pp:effectmagnitude(0, 0, effArg);
											end
										else
											if effTweenHint then
												pp[effTweenHint](pp, effBeats / BPS);
											else
												pp:decelerate(effBeats / BPS);
											end
											pp[effFunc](pp, effArg);
										end
									end
								end
							end
						end
					end		
														
					fifthEffectIndex = fifthEffectIndex + 1;
				else
					break;
				end
			else
				break;
			end
		end
		
					
					
		-- BUZZIBEE no jutsu: update
		MESSAGEMAN:Broadcast("BZBUpdate");
		for i = 1,2 do
			inputPerturbanceFactor = self:GetParent():GetChild("bzbFrame"):GetChild("bzbPerturbance"):getaux();
			BZBPush(i, self:GetParent():GetChild("bzbFrame"):GetChild("bzbTable"):getaux(), overtime, 0.02);
		end
		
		-- Wait a bit and then update again!
		self:queuecommand("WaitABit");
	end,
	WaitABitCommand = function(self)
		self:sleep(0.02);
		self:queuecommand("Update");
	end
}
table.insert(theBoys, fifthGfxHQ);


-------------------------------------------------------------------------------
--
--		Manage arrow mods for the whole song here.
--
local cspd = 3.0;
local bspd = 4.0;
local modsTable = {
	-- [1]: beat start
	-- [2]: mod type
	-- [3]: mod strength (out of unity),
	-- [4]: mod approach (in beats to complete)
	-- [5]: player application (1 = P1, 2 = P2, 3 = both, 0 = neither)
		
		{   0.0,	"ScrollSpeed",		 cspd,    4.0,	3}, 
		{   0.0,	"Dark",				  1.0,    1.0,	3}, 
		{   0.0,	"Stealth",			  1.0,    1.0,	3}, 
		
		{  32.0,	"Tilt",				 -2.0,    1.0,	3}, 
		
		{  64.0,	"Tilt",				  0.0,    4.0,	3}, 
		{  64.0,	"Stealth",			  0.0,    4.0,	3}, 
		{  67.0,	"Dark",				  0.0,    1.0,	3}, 
		{  68.0,	"Tornado",			  0.7,    2.0,	3}, 
		{  70.0,	"Tornado",			  0.0,    2.0,	3}, 
		
		
		{  71.0,	"Drunk",			  0.3,    1.0,	3}, 
		{  71.0,	"Twirl",			 -0.8,    1.0,	3}, 
		{  71.5,	"Beat",				  1.0,    0.5,	3}, 
		{  72.0,	"Drunk",			  1.0,   64.0,	3}, 
		{  72.0,	"Twirl",			  0.8,    1.0,	3}, 
		{  73.0,	"Twirl",			 -0.8,    1.0,	3}, 
		{  74.0,	"Twirl",			  0.8,    1.0,	3}, 
		{  75.0,	"Twirl",			 -0.8,    1.0,	3}, 		
		{  75.5,	"Beat",				  0.0,    0.5,	3}, 
		
		{  79.0,	"Twirl",			 -0.8,    1.0,	3}, 
		{  79.5,	"Beat",				  1.0,    0.5,	3}, 
		{  80.0,	"Twirl",			  0.8,    1.0,	3}, 
		{  81.0,	"Twirl",			 -0.8,    1.0,	3}, 
		{  82.0,	"Twirl",			  0.8,    1.0,	3}, 
		{  83.0,	"Twirl",			 -0.8,    1.0,	3}, 
		{  84.0,	"Twirl",			  0.8,    1.0,	3}, 
		{  85.0,	"Twirl",			 -0.8,    1.0,	3}, 
		{  86.0,	"Twirl",			  0.8,    1.0,	3}, 
		{  87.0,	"Twirl",			  0.0,    1.0,	3}, 
		{  87.0,	"Roll",				 -0.8,    1.0,	3}, 
		{  88.0,	"Roll",				  0.8,    1.0,	3}, 
		{  89.0,	"Roll",				 -0.8,    1.0,	3}, 
		{  90.0,	"Roll",				  0.8,    1.0,	3}, 
		{  91.0,	"Roll",				 -0.8,    1.0,	3}, 
		{  91.5,	"Beat",				  0.0,    0.5,	3}, 
		
		{  95.0,	"Roll",				 -0.8,    1.0,	3}, 
		{  95.5,	"Beat",				  1.0,    0.5,	3}, 
		{  96.0,	"Roll",				  0.8,    1.0,	3}, 
		{  97.0,	"Roll",				 -0.8,    1.0,	3}, 
		{  98.0,	"Roll",				  0.8,    1.0,	3}, 
		{  99.0,	"Roll",				 -0.8,    1.0,	3}, 
		{ 100.0,	"Roll",				  0.8,    1.0,	3}, 
		{ 101.0,	"Roll",				 -0.8,    1.0,	3}, 
		{ 102.0,	"Roll",				  0.8,    1.0,	3}, 
		{ 103.0,	"Roll",				  0.0,    1.0,	3}, 
		{ 103.0,	"Twirl",			 -0.8,    1.0,	3}, 
		{ 104.0,	"Twirl",			  0.8,    1.0,	3}, 
		{ 105.0,	"Twirl",			 -0.8,    1.0,	3}, 
		{ 106.0,	"Twirl",			  0.8,    1.0,	3}, 
		{ 107.0,	"Twirl",			 -0.8,    1.0,	3},
		{ 107.5,	"Beat",				  0.0,    0.5,	3}, 
		
		{ 111.0,	"Twirl",			 -0.8,    1.0,	3}, 
		{ 111.5,	"Beat",				  1.0,    0.5,	3}, 
		{ 112.0,	"Twirl",			  0.8,    1.0,	3}, 
		{ 113.0,	"Twirl",			 -0.8,    1.0,	3}, 
		{ 114.0,	"Twirl",			  0.8,    1.0,	3}, 
		{ 115.0,	"Twirl",			 -0.8,    1.0,	3}, 
		{ 116.0,	"Twirl",			  0.8,    1.0,	3}, 
		{ 117.0,	"Twirl",			 -0.8,    1.0,	3}, 
		{ 118.0,	"Twirl",			  0.8,    1.0,	3}, 
		{ 119.0,	"Twirl",			  0.0,    1.0,	3}, 
		{ 119.0,	"Roll",				 -0.8,    1.0,	3}, 
		{ 120.0,	"Roll",				  0.8,    1.0,	3}, 
		{ 121.0,	"Roll",				 -0.8,    1.0,	3}, 
		{ 122.0,	"Roll",				  0.8,    1.0,	3}, 
		{ 123.0,	"Roll",				 -0.8,    1.0,	3},
		{ 123.5,	"Beat",				  0.0,    0.5,	3}, 
		
		{ 127.0,	"Roll",				 -0.8,    1.0,	3}, 
		{ 127.5,	"Beat",				  1.0,    0.5,	3}, 
		{ 128.0,	"Roll",				  0.8,    1.0,	3}, 
		{ 129.0,	"Roll",				 -0.8,    1.0,	3}, 
		{ 130.0,	"Roll",				  0.8,    1.0,	3}, 
		{ 131.0,	"Roll",				 -0.8,    1.0,	3}, 
		{ 132.0,	"Roll",				  0.8,    1.0,	3}, 
		{ 133.0,	"Roll",				 -0.8,    1.0,	3}, 
		{ 134.0,	"Roll",				  0.8,    1.0,	3}, 
		{ 135.0,	"Roll",				  0.0,    1.0,	3}, 
		{ 135.5,	"Beat",				  0.0,    0.5,	3}, 
		
		{ 136.0,	"Drunk",			  1.2,   12.0,	3}, 
		{ 150.0,	"Centered",			  1.0,    2.0,	3}, 
		{ 151.0,	"Drunk",			  0.0,    1.0,	3}, 
		{ 152.0,	"Cross",			  1.0,    2.0,	3}, 
		{ 154.0,	"Alternate",		  1.0,    2.0,	3}, 
		{ 156.0,	"Reverse",			  1.0,    2.0,	3}, 
		{ 156.0,	"Split",			  1.0,    2.0,	3}, 
		{ 158.0,	"Cross",			  0.0,    2.0,	3}, 
		{ 158.0,	"Alternate",		  0.0,    2.0,	3}, 
		{ 158.0,	"Split",			  0.0,    2.0,	3}, 
		{ 160.0,	"Centered",			  0.0,    4.0,	3}, 
		{ 160.0,	"ScrollSpeed",		 bspd,    4.0,	3}, 	
		{ 160.0,	"Mini",	  (1-dblMinify)*2,    4.0,	3}, 
		{ 166.0,	"Reverse",			  0.0,    2.0,	3}, 
		
				
		{ 194.0,	"ScrollSpeed",		 dspd,    2.0,	3},	
		
		{ 200.0,	"ScrollSpeed",		 cspd,    8.0,	3},	
		{ 208.0,	"Boost",			 -2.5,   16.0,	3},	
		{ 208.0,	"Mini",	  			  0.0,    8.0,	3}, 
		
		{ 214.0,	"Centered",			  2.0,   10.0,	3}, 
		{ 224.0,	"Boost",			  0.0,    2.0,	3}, 
		{ 224.0,	"Reverse",			  1.0,    4.0,	3}, 
		{ 224.0,	"Centered",			  0.0,    4.0,	3}, 
		
		{ 230.0,	"Reverse",			  0.0,    2.0,	3}, 	
		
		{ 239.6,	"Tiny",	  			 -1.5,    0.0,	3},
		{ 239.6,	"Flip",	  			  0.5,    0.0,	3},
		{ 243.5,	"Tiny",	  			  0.0,    2.0,	3},
		{ 243.5,	"Flip",	  			  0.0,    2.0,	3},
		
		{ 255.6,	"Tiny",	  			 -1.5,    0.0,	3},
		{ 255.6,	"Flip",	  			  0.5,    0.0,	3},
		{ 259.5,	"Tiny",	  			  0.0,    1.0,	3},
		{ 259.5,	"Flip",	  			  0.0,    1.0,	3},
		
		
		{ 263.5,	"Beat",	  			  0.2,    0.5,	3},
		
		{264.00,	"Flip",	  			  0.08,    0.0,	3},
		{264.00,	"Invert",	  		 -0.25,    0.0,	3},
		{264.33,	"Flip",	  			  0.17,    0.0,	3},
		{264.33,	"Invert",	  		 -0.50,    0.0,	3},
		{264.67,	"Flip",	  			  0.25,    0.0,	3},
		{264.67,	"Invert",	  		 -0.75,    0.0,	3},
		
		{265.00,	"Flip",	  			  0.50,    0.0,	3},
		{265.00,	"Invert",	  		 -0.83,    0.0,	3},
		{265.33,	"Flip",	  			  0.75,    0.0,	3},
		{265.33,	"Invert",	  		 -0.92,    0.0,	3},
		{265.67,	"Flip",	  			  1.00,    0.0,	3},
		{265.67,	"Invert",	  		 -1.00,    0.0,	3},
		
		--{266.00,	"Flip",	  			  1.00,    0.0,	3},
		{266.00,	"Invert",	  		 -0.67,    0.0,	3},
		--{266.33,	"Flip",	  			  1.00,    0.0,	3},
		{266.33,	"Invert",	  		 -0.33,    0.0,	3},
		--{266.67,	"Flip",	  			  1.00,    0.0,	3},
		{266.67,	"Invert",	  		  0.00,    0.0,	3},
		
		{267.00,	"Flip",	  			  0.67,    0.0,	3},
		--{267.00,	"Invert",	  		 -0.67,    0.0,	3},
		{267.33,	"Flip",	  			  0.33,   0.33,	3},
		--{267.33,	"Invert",	  		 -0.33,    0.0,	3},
		{267.67,	"Flip",	  			  0.00,    0.0,	3},
		--{267.67,	"Invert",	  		  0.00,    0.0,	3},
		
		
		{268.00,	"Flip",	  			  0.08,    0.0,	3},
		{268.00,	"Invert",	  		  0.08,    0.0,	3},
		{268.33,	"Flip",	  			  0.17,    0.0,	3},
		{268.33,	"Invert",	  		  0.17,    0.0,	3},
		{268.67,	"Flip",	  			  0.25,    0.0,	3},
		{268.67,	"Invert",	  		  0.25,    0.0,	3},
		
		{269.00,	"Flip",	  			  0.17,    0.0,	3},
		{269.00,	"Invert",	  		  0.50,    0.0,	3},
		{269.33,	"Flip",	  			  0.08,    0.0,	3},
		{269.33,	"Invert",	  		  0.75,    0.0,	3},
		{269.67,	"Flip",	  			  0.00,    0.0,	3},
		{269.67,	"Invert",	  		  1.00,    0.0,	3},
		
		{270.00,	"Flip",	  			  0.08,    0.0,	3},
		{270.00,	"Invert",	  		  1.08,    0.0,	3},
		{270.33,	"Flip",	  			  0.17,    0.0,	3},
		{270.33,	"Invert",	  		  1.17,    0.0,	3},
		{270.67,	"Flip",	  			  0.25,    0.0,	3},
		{270.67,	"Invert",	  		  1.25,    0.0,	3},
		
		{271.00,	"Flip",	  			  0.17,    0.0,	3},
		{271.00,	"Invert",	  		  0.83,    0.0,	3},
		{271.33,	"Flip",	  			  0.08,   0.33,	3},
		{271.33,	"Invert",	  		  0.42,   0.33,	3},
		{271.67,	"Flip",	  			  0.00,    0.0,	3},
		{271.67,	"Invert",	  		  0.00,    0.0,	3},
		
		
		{272.00,	"Flip",	  			  0.08,    0.0,	3},
		{272.00,	"Invert",	  		 -0.25,    0.0,	3},
		{272.33,	"Flip",	  			  0.17,    0.0,	3},
		{272.33,	"Invert",	  		 -0.50,    0.0,	3},
		{272.67,	"Flip",	  			  0.25,    0.0,	3},
		{272.67,	"Invert",	  		 -0.75,    0.0,	3},
		
		{273.00,	"Flip",	  			  0.42,    0.0,	3},
		{273.00,	"Invert",	  		 -0.92,    0.0,	3},
		{273.33,	"Flip",	  			  0.58,    0.0,	3},
		{273.33,	"Invert",	  		 -1.08,    0.0,	3},
		{273.67,	"Flip",	  			  0.75,    0.0,	3},
		{273.67,	"Invert",	  		 -1.25,    0.0,	3},
		
		{274.00,	"Flip",	  			  0.83,    0.0,	3},
		{274.00,	"Invert",	  		 -1.17,    0.0,	3},
		{274.33,	"Flip",	  			  0.92,    0.0,	3},
		{274.33,	"Invert",	  		 -1.08,    0.0,	3},
		{274.67,	"Flip",	  			  1.00,    0.0,	3},
		{274.67,	"Invert",	  		 -1.00,    0.0,	3},
		
		--{275.00,	"Flip",	  			  1.00,    0.0,	3},
		{275.00,	"Invert",	  		 -0.67,    0.0,	3},
		--{275.33,	"Flip",	  			  1.00,    0.0,	3},
		{275.33,	"Invert",	  		 -0.33,   0.33,	3},
		--{275.67,	"Flip",	  			  1.00,    0.0,	3},
		{275.67,	"Invert",	  		  0.00,    0.0,	3},
		
		{276.00,	"Flip",	  			  0.92,    0.0,	3},
		{276.00,	"Invert",	  		  0.25,    0.0,	3},
		{276.33,	"Flip",	  			  0.83,    0.0,	3},
		{276.33,	"Invert",	  		  0.50,    0.0,	3},
		{276.67,	"Flip",	  			  0.75,    0.0,	3},
		{276.67,	"Invert",	  		  0.75,    0.0,	3},
		
		{277.00,	"Flip",	  			 0.625,    0.0,	3},
		{277.00,	"Invert",	  		 0.625,    0.0,	3},
		{277.33,	"Flip",	  			  0.50,    0.0,	3},
		{277.33,	"Invert",	  		  0.50,    0.0,	3},
		{277.67,	"Flip",	  			 0.375,    0.0,	3},
		{277.67,	"Invert",	  		 0.375,    0.0,	3},		
		{278.00,	"Flip",	  			  0.25,    0.0,	3},
		{278.00,	"Invert",	  		  0.25,    0.0,	3},
		{278.33,	"Flip",	  			 0.125,    0.0,	3},
		{278.33,	"Invert",	  		 0.125,    0.0,	3},
		{278.67,	"Flip",	  			  0.00,    0.0,	3},
		{278.67,	"Invert",	  		  0.00,    0.0,	3},
		
		{291.50,	"Beat",	  			  0.0,    0.5,	3},
		
		{292.00,	"Tiny",		  		 -2.0,    8.0,	3},
		{292.00,	"Flip",		  		  0.5,    4.0,	3},
		{296.00,	"Dark",		  		  1.0,    4.0,	3},
		{296.00,	"Stealth",	  		  1.0,    4.0,	3},
		
		{304.00,	"Tiny",		  		  0.0,    8.0,	3},
		{304.00,	"Flip",		  		  0.0,    8.0,	3},		
		{304.00,	"Tilt",				 -2.0,    1.0,	3}, 
		
		{ 368.0,	"Tilt",				  0.0,    4.0,	3}, 
		{ 368.0,	"Stealth",			  0.0,    4.0,	3}, 
		{ 371.0,	"Dark",				  0.0,    1.0,	3}, 
		
		
		{ 376.0,	"Dark",				  1.0,    1.0,	3}, 
		{ 376.0,	"Stealth",	  		  1.0,    4.0,	3},
		
		{ 400.0,	"Stealth",			  0.0,    4.0,	3}, 
		{ 403.0,	"Dark",				  0.0,    1.0,	3}, 
		
		{ 408.0,	"Dark",				  1.0,    1.0,	3}, 
		{ 408.0,	"Stealth",	  		  1.0,    4.0,	3},
		{ 408.0,	"ScrollSpeed",		 bspd,   16.0,	3}, 
		{ 408.0,	"Mini",	  (1-dblMinify)*2,   16.0,	3}, 
		
		{ 436.0,	"Stealth",			  0.0,    4.0,	3}, 
		{ 436.0,	"Dark",				  0.0,    1.0,	3}, 
				
		{ 467.0,	"ScrollSpeed",		 dspd,    1.0,	3},			
		{ 472.0,	"ScrollSpeed",		 bspd,    1.0,	3},	
		
		{ 488.0,	"Centered",			  1.0,    8.0,	3}, 
		{ 488.0,	"Invert",		  	  1.0,    2.0,	3},	
		{ 490.0,	"Invert",		  	  0.0,    2.0,	3},			
		{ 492.0,	"Invert",		  	  1.0,    2.0,	3},	
		{ 494.0,	"Invert",		  	  0.0,    2.0,	3},		
		{ 496.0,	"Reverse",			  1.0,    4.0,	3}, 
		{ 496.0,	"Centered",			  0.0,    4.0,	3}, 	
		{ 496.0,	"Invert",		  	  1.0,    1.0,	3},	
		{ 497.0,	"Invert",		  	  0.0,    1.0,	3},	
		
		
		
		{ 502.0,	"Reverse",			  0.0,    2.0,	3},
		{ 502.0,	"ScrollSpeed",		 cspd,    2.0,	3},  	
		{ 502.0,	"Mini",	  			  0.0,    2.0,	3}, 
		
		{ 511.6,	"Tiny",	  			 -1.5,    0.0,	3},
		{ 511.6,	"Flip",	  			  0.5,    0.0,	3},
		{ 515.5,	"Tiny",	  			  0.0,    2.0,	3},
		{ 515.5,	"Flip",	  			  0.0,    2.0,	3},
		
		{ 527.6,	"Tiny",	  			 -1.5,    0.0,	3},
		{ 527.6,	"Flip",	  			  0.5,    0.0,	3},
		{ 531.5,	"Tiny",	  			  0.0,    1.0,	3},
		{ 531.5,	"Flip",	  			  0.0,    1.0,	3},
		
		
		{ 535.5,	"Beat",	  			  0.2,    0.5,	3},
		
		{536.00,	"Flip",	  			  0.08,    0.0,	3},
		{536.00,	"Invert",	  		 -0.25,    0.0,	3},
		{536.33,	"Flip",	  			  0.17,    0.0,	3},
		{536.33,	"Invert",	  		 -0.50,    0.0,	3},
		{536.67,	"Flip",	  			  0.25,    0.0,	3},
		{536.67,	"Invert",	  		 -0.75,    0.0,	3},
		
		{537.00,	"Flip",	  			  0.50,    0.0,	3},
		{537.00,	"Invert",	  		 -0.83,    0.0,	3},
		{537.33,	"Flip",	  			  0.75,    0.0,	3},
		{537.33,	"Invert",	  		 -0.92,    0.0,	3},
		{537.67,	"Flip",	  			  1.00,    0.0,	3},
		{537.67,	"Invert",	  		 -1.00,    0.0,	3},
		
		--{538.00,	"Flip",	  			  1.00,    0.0,	3},
		{538.00,	"Invert",	  		 -0.67,    0.0,	3},
		--{538.33,	"Flip",	  			  1.00,    0.0,	3},
		{538.33,	"Invert",	  		 -0.33,    0.0,	3},
		--{538.67,	"Flip",	  			  1.00,    0.0,	3},
		{538.67,	"Invert",	  		  0.00,    0.0,	3},
		
		{539.00,	"Flip",	  			  0.67,    0.0,	3},
		--{539.00,	"Invert",	  		 -0.67,    0.0,	3},
		{539.33,	"Flip",	  			  0.33,   0.33,	3},
		--{539.33,	"Invert",	  		 -0.33,    0.0,	3},
		{539.67,	"Flip",	  			  0.00,    0.0,	3},
		--{539.67,	"Invert",	  		  0.00,    0.0,	3},
		
		
		{540.00,	"Flip",	  			  0.08,    0.0,	3},
		{540.00,	"Invert",	  		  0.08,    0.0,	3},
		{540.33,	"Flip",	  			  0.17,    0.0,	3},
		{540.33,	"Invert",	  		  0.17,    0.0,	3},
		{540.67,	"Flip",	  			  0.25,    0.0,	3},
		{540.67,	"Invert",	  		  0.25,    0.0,	3},
		
		{541.00,	"Flip",	  			  0.17,    0.0,	3},
		{541.00,	"Invert",	  		  0.50,    0.0,	3},
		{541.33,	"Flip",	  			  0.08,    0.0,	3},
		{541.33,	"Invert",	  		  0.75,    0.0,	3},
		{541.67,	"Flip",	  			  0.00,    0.0,	3},
		{541.67,	"Invert",	  		  1.00,    0.0,	3},
		
		{542.00,	"Flip",	  			  0.08,    0.0,	3},
		{542.00,	"Invert",	  		  1.08,    0.0,	3},
		{542.33,	"Flip",	  			  0.17,    0.0,	3},
		{542.33,	"Invert",	  		  1.17,    0.0,	3},
		{542.67,	"Flip",	  			  0.25,    0.0,	3},
		{542.67,	"Invert",	  		  1.25,    0.0,	3},
		
		{543.00,	"Flip",	  			  0.17,    0.0,	3},
		{543.00,	"Invert",	  		  0.83,    0.0,	3},
		{543.33,	"Flip",	  			  0.08,   0.33,	3},
		{543.33,	"Invert",	  		  0.42,   0.33,	3},
		{543.67,	"Flip",	  			  0.00,    0.0,	3},
		{543.67,	"Invert",	  		  0.00,    0.0,	3},
		
		
		{544.00,	"Flip",	  			  0.08,    0.0,	3},
		{544.00,	"Invert",	  		 -0.25,    0.0,	3},
		{544.33,	"Flip",	  			  0.17,    0.0,	3},
		{544.33,	"Invert",	  		 -0.50,    0.0,	3},
		{544.67,	"Flip",	  			  0.25,    0.0,	3},
		{544.67,	"Invert",	  		 -0.75,    0.0,	3},
		
		{545.00,	"Flip",	  			  0.42,    0.0,	3},
		{545.00,	"Invert",	  		 -0.92,    0.0,	3},
		{545.33,	"Flip",	  			  0.58,    0.0,	3},
		{545.33,	"Invert",	  		 -1.08,    0.0,	3},
		{545.67,	"Flip",	  			  0.75,    0.0,	3},
		{545.67,	"Invert",	  		 -1.25,    0.0,	3},
		
		{546.00,	"Flip",	  			  0.83,    0.0,	3},
		{546.00,	"Invert",	  		 -1.17,    0.0,	3},
		{546.33,	"Flip",	  			  0.92,    0.0,	3},
		{546.33,	"Invert",	  		 -1.08,    0.0,	3},
		{546.67,	"Flip",	  			  1.00,    0.0,	3},
		{546.67,	"Invert",	  		 -1.00,    0.0,	3},
		
		--{547.00,	"Flip",	  			  1.00,    0.0,	3},
		{547.00,	"Invert",	  		 -0.67,    0.0,	3},
		--{547.33,	"Flip",	  			  1.00,    0.0,	3},
		{547.33,	"Invert",	  		 -0.33,   0.33,	3},
		--{547.67,	"Flip",	  			  1.00,    0.0,	3},
		{547.67,	"Invert",	  		  0.00,    0.0,	3},
		
		{548.00,	"Flip",	  			  0.92,    0.0,	3},
		{548.00,	"Invert",	  		  0.25,    0.0,	3},
		{548.33,	"Flip",	  			  0.83,    0.0,	3},
		{548.33,	"Invert",	  		  0.50,    0.0,	3},
		{548.67,	"Flip",	  			  0.75,    0.0,	3},
		{548.67,	"Invert",	  		  0.75,    0.0,	3},
		
		{549.00,	"Flip",	  			 0.625,    0.0,	3},
		{549.00,	"Invert",	  		 0.625,    0.0,	3},
		{549.33,	"Flip",	  			  0.50,    0.0,	3},
		{549.33,	"Invert",	  		  0.50,    0.0,	3},
		{549.67,	"Flip",	  			 0.375,    0.0,	3},
		{549.67,	"Invert",	  		 0.375,    0.0,	3},		
		{550.00,	"Flip",	  			  0.25,    0.0,	3},
		{550.00,	"Invert",	  		  0.25,    0.0,	3},
		{550.33,	"Flip",	  			 0.125,    0.0,	3},
		{550.33,	"Invert",	  		 0.125,    0.0,	3},
		{550.67,	"Flip",	  			  0.00,    0.0,	3},
		{550.67,	"Invert",	  		  0.00,    0.0,	3},
		
		{563.50,	"Beat",	  			  0.0,    0.5,	3},
		
		{564.00,	"Tiny",		  		 -1.0,    3.5,	3},
		{564.00,	"Flip",		  		  0.5,    3.5,	3},
		{567.00,	"Tiny",		  		  0.0,    0.5,	3},
		{567.00,	"Flip",		  		  0.0,    0.5,	3},
		
		{ 567.0,	"Drunk",			  0.3,    1.0,	3}, 
		{ 567.0,	"Twirl",			 -0.8,    1.0,	3}, 
		{ 567.5,	"Beat",				  1.0,    0.5,	3}, 
		{ 568.0,	"Drunk",			  1.0,   64.0,	3}, 
		{ 568.0,	"Twirl",			  0.8,    1.0,	3}, 
		{ 569.0,	"Twirl",			 -0.8,    1.0,	3}, 
		{ 570.0,	"Twirl",			  0.8,    1.0,	3}, 
		{ 571.0,	"Twirl",			 -0.8,    1.0,	3}, 		
		{ 571.5,	"Beat",				  0.0,    0.5,	3}, 
		
		{ 575.0,	"Twirl",			 -0.8,    1.0,	3}, 
		{ 575.5,	"Beat",				  1.0,    0.5,	3}, 
		{ 576.0,	"Twirl",			  0.8,    1.0,	3}, 
		{ 577.0,	"Twirl",			 -0.8,    1.0,	3}, 
		{ 578.0,	"Twirl",			  0.8,    1.0,	3}, 
		{ 579.0,	"Twirl",			 -0.8,    1.0,	3}, 
		{ 580.0,	"Twirl",			  0.8,    1.0,	3}, 
		{ 581.0,	"Twirl",			 -0.8,    1.0,	3}, 
		{ 582.0,	"Twirl",			  0.8,    1.0,	3}, 
		{ 583.0,	"Twirl",			  0.0,    1.0,	3}, 
		{ 583.0,	"Roll",				 -0.8,    1.0,	3}, 
		{ 584.0,	"Roll",				  0.8,    1.0,	3}, 
		{ 585.0,	"Roll",				 -0.8,    1.0,	3}, 
		{ 586.0,	"Roll",				  0.8,    1.0,	3}, 
		{ 587.0,	"Roll",				 -0.8,    1.0,	3}, 
		{ 587.5,	"Beat",				  0.0,    0.5,	3}, 
		
		{ 591.0,	"Roll",				 -0.8,    1.0,	3}, 
		{ 591.5,	"Beat",				  1.0,    0.5,	3}, 
		{ 592.0,	"Roll",				  0.8,    1.0,	3}, 
		{ 593.0,	"Roll",				 -0.8,    1.0,	3}, 
		{ 594.0,	"Roll",				  0.8,    1.0,	3}, 
		{ 595.0,	"Roll",				 -0.8,    1.0,	3}, 
		{ 596.0,	"Roll",				  0.8,    1.0,	3}, 
		{ 597.0,	"Roll",				 -0.8,    1.0,	3}, 
		{ 598.0,	"Roll",				  0.8,    1.0,	3}, 
		{ 599.0,	"Roll",				  0.0,    1.0,	3}, 
		{ 599.0,	"Twirl",			 -0.8,    1.0,	3}, 
		{ 600.0,	"Twirl",			  0.8,    1.0,	3}, 
		{ 601.0,	"Twirl",			 -0.8,    1.0,	3}, 
		{ 602.0,	"Twirl",			  0.8,    1.0,	3}, 
		{ 603.0,	"Twirl",			 -0.8,    1.0,	3},
		{ 603.5,	"Beat",				  0.0,    0.5,	3}, 
		
		{ 607.0,	"Twirl",			 -0.8,    1.0,	3}, 
		{ 607.5,	"Beat",				  1.0,    0.5,	3}, 
		{ 608.0,	"Twirl",			  0.8,    1.0,	3}, 
		{ 609.0,	"Twirl",			 -0.8,    1.0,	3}, 
		{ 610.0,	"Twirl",			  0.8,    1.0,	3}, 
		{ 611.0,	"Twirl",			 -0.8,    1.0,	3}, 
		{ 612.0,	"Twirl",			  0.8,    1.0,	3}, 
		{ 613.0,	"Twirl",			 -0.8,    1.0,	3}, 
		{ 614.0,	"Twirl",			  0.8,    1.0,	3}, 
		{ 615.0,	"Twirl",			  0.0,    1.0,	3}, 
		{ 615.0,	"Roll",				 -0.8,    1.0,	3}, 
		{ 616.0,	"Roll",				  0.8,    1.0,	3}, 
		{ 617.0,	"Roll",				 -0.8,    1.0,	3}, 
		{ 618.0,	"Roll",				  0.8,    1.0,	3}, 
		{ 619.0,	"Roll",				 -0.8,    1.0,	3},
		{ 619.5,	"Beat",				  0.0,    0.5,	3}, 
		
		{ 623.0,	"Roll",				 -0.8,    1.0,	3}, 
		{ 623.5,	"Beat",				  1.0,    0.5,	3}, 
		{ 624.0,	"Tornado",			  1.0,    8.0,	3},
		{ 624.0,	"Roll",				  0.8,    1.0,	3}, 
		{ 625.0,	"Roll",				 -0.8,    1.0,	3}, 
		{ 626.0,	"Roll",				  0.8,    1.0,	3}, 
		{ 627.0,	"Roll",				 -0.8,    1.0,	3}, 
		{ 628.0,	"Roll",				  0.8,    1.0,	3}, 
		{ 629.0,	"Roll",				 -0.8,    1.0,	3}, 
		{ 630.0,	"Roll",				  0.8,    1.0,	3}, 
		{ 631.0,	"Roll",				  0.0,    1.0,	3}, 
		{ 631.5,	"Beat",				  0.0,    0.5,	3}, 
		{ 632.0,	"Drunk",			  0.0,   64.0,	3}, 
		{ 632.0,	"Tornado",			  0.0,    8.0,	3},
		{ 632.0,	"Dark",				  1.0,    8.0,	3}, 
		{ 632.0,	"Stealth",	  		  1.0,   32.0,	3},
		
	};
local modsLaunched = 0;
local modsWait = 0;
local modsLeadBy = 0.03;
	
local mods = {
	["LifeSetting"] =	"ENUM", 
	["DrainSetting"] =	"ENUM", 
--	["BatteryLives"] =	"INT", 
	["TimeSpacing"] =	"FLOAT", 
	["MaxScrollBPM"] =	"FLOAT", 
	["ScrollSpeed"] =	"FLOAT", 
	["ScrollBPM"] =		"FLOAT", 
	["Boost"] =			"FLOAT", 
	["Brake"] =			"FLOAT", 
	["Wave"] =			"FLOAT", 
	["Expand"] =		"FLOAT", 
	["Boomerang"] =		"FLOAT", 
	["Drunk"] =			"FLOAT", 
	["Dizzy"] =			"FLOAT", 
	["Confusion"] =		"FLOAT",
	["Mini"] =			"FLOAT", 
	["Tiny"] =			"FLOAT", 
	["Flip"] =			"FLOAT", 
	["Invert"] =		"FLOAT", 
	["Tornado"] =		"FLOAT", 
	["Tipsy"] =			"FLOAT", 
	["Bumpy"] =			"FLOAT", 
	["Beat"] =			"FLOAT", 
	["Xmode"] =			"FLOAT", 
	["Twirl"] =			"FLOAT", 
	["Roll"] =			"FLOAT", 
	["Hidden"] =		"FLOAT", 
	["HiddenOffset"] =	"FLOAT", 
	["Sudden"] =		"FLOAT", 
	["SuddenOffset"] =	"FLOAT", 
	["Stealth"] =		"FLOAT", 
	["Blink"] =			"FLOAT", 
	["RandomVanish"] =	"FLOAT", 
	["Reverse"] =		"FLOAT", 
	["Split"] =			"FLOAT", 
	["Alternate"] =		"FLOAT", 
	["Cross"] =			"FLOAT", 
	["Centered"] =		"FLOAT", 
	["Dark"] =			"FLOAT", 
	["Blind"] =			"FLOAT", 
	["Cover"] =			"FLOAT", 
	["RandAttack"] =	"FLOAT", 
	["NoAttack"] =		"FLOAT", 
	["PlayerAutoPlay"] ="FLOAT", 
	["Skew"] =			"FLOAT", 
	["Tilt"] =			"FLOAT", 
	["Passmark"] =		"FLOAT", 
	["RandomSpeed"] =	"FLOAT", 
	["TurnNone"] =		"BOOL", 
	["Mirror"] =		"BOOL", 
	["Backwards"] =		"BOOL", 
	["Left"] =			"BOOL", 
	["Right"] =			"BOOL", 
	["Shuffle"] =		"BOOL", 
	["SoftShuffle"] =	"BOOL", 
	["SuperShuffle"] =	"BOOL", 
	["NoHolds"] =		"BOOL", 
	["NoRolls"] =		"BOOL", 
	["NoMines"] =		"BOOL", 
	["Little"] =		"BOOL", 
	["Wide"] =			"BOOL", 
	["Big"] =			"BOOL", 
	["Quick"] =			"BOOL", 
	["BMRize"] =		"BOOL", 
	["Skippy"] =		"BOOL", 
	["Mines"] =			"BOOL", 
	["AttackMines"] =	"BOOL", 
	["Echo"] =			"BOOL", 
	["Stomp"] =			"BOOL", 
	["Planted"] =		"BOOL", 
	["Floored"] =		"BOOL", 
	["Twister"] =		"BOOL", 
	["HoldRolls"] =		"BOOL", 
	["NoJumps"] =		"BOOL", 
	["NoHands"] =		"BOOL", 
	["NoLifts"] =		"BOOL", 
	["NoFakes"] =		"BOOL", 
	["NoQuads"] =		"BOOL", 
	["NoStretch"] =		"BOOL", 
	["MuteOnError"] =	"BOOL", 
	["FailSetting"] =	"ENUM", 
	["MinTNSToHideNotes"] =	"ENUM"
}
local clearAllMods = function(playerNum, justTrace)
	local currValue;
	local currApproach;
	
	playerNum = playerNum or 1
	justTrace = justTrace or false
	
	if playerNum < 1 or playerNum > 2 then do Trace("In clearAllMods: Player number "..playerNum.." is invalid!"); return end end
	pops = GAMESTATE:GetPlayerState("PlayerNumber_P"..playerNum):GetPlayerOptions("ModsLevel_Song");
	if pops then
		for modName,modType in pairs(mods) do
			currValue,currApproach = pops[modName](pops);
			-- Trace("In clearAllMods: P"..playerNum.." has mod "..modName.." set to "..tostring(currValue));
			
			if not justTrace then
				if modType == "FLOAT" then
					if modName == "ScrollBPM" then
						pops[modName](pops, 200);
					elseif modName == "ScrollSpeed" then
						pops[modName](pops, 1);
					else
						pops[modName](pops, 0);
					end
				elseif modType == "BOOL" then
					pops[modName](pops, false);
				elseif modType == "INT" then
					if modName == "BatteryLives" then
						pops[modName](pops, 4);
					else
						pops[modName](pops, 0);
					end
				else -- if modType == "ENUM" then
				end
			end
		end
	else
		Trace("In clearAllMods: Player options for "..playerNum.." are not initialized!");
	end
end

local modsHQ = Def.Quad {
	InitCommand = function(self)
		self:SetHeight(6)
			:SetWidth(6)
			:xy(-sw,-sh)
			:visible(false);
	end,
	OnCommand = function(self)
		self:queuecommand("Update");
		clearAllMods(1);
		clearAllMods(2);
	end,
	UpdateCommand = function(self)
		-- Most things are determined by beat, believe it or not.		
		local overtime = GAMESTATE:GetSongBeat();
		
		if modsLaunched >= #modsTable then
			Trace('>>> modsHQ: Hibernated!!');
			self:hibernate(600);
			do return end
		else
			while modsLaunched < #modsTable do
				-- Trace('>>> modsHQ: ' .. modsLaunched);
				-- Check the next line of the mods table.
				nextMod = modsTable[modsLaunched + 1];
				
				if overtime + modsLeadBy >= nextMod[1] then
					-- TODO: this assumes the effect applies over a constant BPM section!!
					Trace('>>> modsHQ: ' .. modsLaunched .. ' @ time = ' .. overtime);
					
					for _,pe in pairs(GAMESTATE:GetEnabledPlayers()) do
						pn = tonumber(string.match(pe, "[0-9]+"));
						if (nextMod[5] == pn or nextMod[5] == 3) then
							pops = GAMESTATE:GetPlayerState(pe):GetPlayerOptions("ModsLevel_Song");
							
							-- Calculate approach (in units of the value per second):
							-- a = (value final - value initial) * (beats per second) / (beats for transition + ``machine epsilon``)
							-- Has to be done individually for each player, just in case they're coming from different initial values :(
							opVal, opApproach = pops[ nextMod[2] ]( pops );
							if opApproach == 0 then -- SOMEONE FUCKED UP AND IT WASN'T ME.
								newApproach = BPS;
							else
								newApproach = math.abs(nextMod[3] - opVal) * BPS / (nextMod[4] + 0.001);
							end
							pops[ nextMod[2] ]( pops, nextMod[3], newApproach );
							Trace('>>> modsHQ: ' .. opVal      .. ' @ rate = ' .. opApproach  .. ' for ' .. pe);
							Trace('>>> modsHQ: ' .. nextMod[3] .. ' @ rate = ' .. newApproach .. ' for ' .. pe .. ' [New!]');
						end
					end
					
					modsLaunched = modsLaunched + 1;
				else
					-- Trace('>>> modsHQ: ' .. overtime .. ' < ' .. nextMod[1]);
					break;
				end
			end
		end		
		
		-- Wait a bit and then update again!
		self:queuecommand('WaitABit');
	end,
	WaitABitCommand = function(self)
		self:sleep(0.01);
		self:queuecommand('Update');
	end
}
table.insert(theBoys, modsHQ);

-------------------------------------------------------------------------------
--
--		Everybody wants to hide the Lay's.
--
noteskinSet = nil;
local hamburgerHelper = Def.Quad {
	InitCommand = function(self)
		self:SetHeight(6)
			:SetWidth(6)
			:xy(-sw,-sh)
			:visible(false);
	end,
	OnCommand = function(self)
		local hamburger = SCREENMAN:GetTopScreen();
		
		-- Add input callback to enable BUZZIBEE no jutsu
		hamburger:AddInputCallback(input);
		
		if hamburger:GetScreenType() == "ScreenType_Gameplay" then
			hamburger:GetChild("Overlay" ):decelerate(1.0):diffusealpha(0.0);
			hamburger:GetChild("Underlay"):decelerate(1.0):diffusealpha(0.0);
		end
				
		local playersFound = 0;
		local hadToSetNoteskin = false;
		for pn = 1,2 do
			if not noteskinSet then				
				pops = GAMESTATE:GetPlayerState("PlayerNumber_P"..pn):GetPlayerOptions("ModsLevel_Preferred");
				if pops then 
					prevNS, didItWork = pops:NoteSkin("cyber");
					Trace (pn .. ": " .. prevNS .. " > " .. tostring(didItWork) .. "!!");
					if prevNS ~= "cyber" then
						hadToSetNoteskin = true;
					end
				end
			end
			
			pv = hamburger:GetChild("PlayerP"..pn);
			if pv then
				pv:GetChild("Combo"):hibernate(1573);
				playersFound = playersFound + pn;
			end
			
			pops = GAMESTATE:GetPlayerState("PlayerNumber_P"..pn):GetPlayerOptions("ModsLevel_Song");
			pops:FailSetting('FailType_Off');
		end
				
--		noteskinSet = true;
--		if hadToSetNoteskin then
--			SCREENMAN:SetNewScreen("ScreenGameplay"):StartTransitioningScreen("SM_GoToNextScreen");
--		end
		
		if playersFound == 3 then
			Trace("#### hibernate!");
			self:hibernate(6000);
		else
			-- Wait a bit and then update again!
			self:queuecommand('WaitABit');
		end
	end,	
	WaitABitCommand = function(self)
		self:sleep(0.02);
		self:queuecommand('Update');
	end
}
table.insert(theBoys, hamburgerHelper);
-------------------------------------------------------------------------------




return theBoys;

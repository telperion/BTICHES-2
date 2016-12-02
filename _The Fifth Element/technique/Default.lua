-------------------------------------------------------------------------------
--
--		Quintessence
--		
--		Author: 	Telperion
--		Date: 		2016-11-25
--
-------------------------------------------------------------------------------

local sw = SCREEN_WIDTH;
local sh = SCREEN_HEIGHT;
local BPS = GAMESTATE:GetSongBPS();	
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

-- I grabbed this out of ScreenTestInput underlay
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

local RoundBezier =
{
	0	,	0,
	0	,	1,
	1	,	1,
	1	,	0,
}

-------------------------------------------------------------------------------
--
-- 		BUZZIBEE no jutsu
--
local totalAttempts = 12;
local takenAttempts = 0;
local resultRowLength = 8;
local lineWidth = 6;
local inputPersistenceFactor = 0.8;
local inputPerturbanceFactor = 0;
local inputStrengthX = 50;				-- Units per beat
local inputStrengthY = 200;				-- Units per beat
local inSession = false;
local DEBUG_firstVerts = true;

local BZBFrame = Def.ActorFrame {
	Name = "bzbFrame",
	OnCommand = function(self)
		self:diffusealpha(0.0)
			:visible(false);
	end,
	BZBStartMessageCommand = function(self)
		self:visible(true)
			:decelerate(8.0 / BPS)
			:diffusealpha(1.0)
			:queuecommand("BZBReady");
	end,
	BZBReadyCommand = function(self)
		Trace("BZB is in session!");
		inSession = true;
	end,
	BZBEndMessageCommand = function(self)
		self:visible(true)
			:decelerate(8.0 / BPS)
			:diffusealpha(0.0)
			:queuecommand("BZBFinished");
	end,
	BZBFinishedCommand = function(self)
		Trace("BZB is over!");
		inSession = false;
		self:hibernate(1573);
	end,
};

local BZBData = {};
local BZBInput = {};
for i = 1,2 do
	local s = (i == 2) and 1 or -1;
	BZBData[i] = {
		vx = -33*s,						-- **	**	Initial horizontal velocity
		vy =   0,						-- 		**	Initial vertical velocity
		
		x_throw 	= 320 + 288*s,		-- (const)	Horizontal position from which ball is thrown
		x_bounce 	= nil,				-- (calc)	Horizontal position at which ball bounces first time
		x_rebounce 	= nil,				-- (calc)	Horizontal position at which ball bounces second time
		x_end	 	= nil,				-- (calc)	Horizontal position at which ball would peak on the /third/ bounce
		x_near 		= 320 + 104*s,		-- (const)	Horizontal position of left side of cup
		x_far	 	= 320 +  24*s,		-- (const)	Horizontal position of right side of cup
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

		totalSucc = 0					-- Successes
	};
	BZBInput[i] = {
		{false, false, false, false},	-- State of input
		{0, 0, 0, 0},					-- Persistence factor of input
	};
end

local BZBRateMyProfessor = function(succ)
		if totalAttempts - succ < 2 then do return 0 end		-- why are spritesheets of all things zero-indexed??
	elseif totalAttempts - succ < 4 then do return 1 end
	elseif totalAttempts - succ < 6 then do return 2 end
	elseif totalAttempts - succ < 9 then do return 3 end
	else 								 do return 4 end
	end
end	

local BZBAllowMove = function(pn)
	-- Constrain the range of player throws by making sure the ball bounces only once.
	-- Zero times, or twice, is not allowed.	
	
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
	if not inSession then do return end end
	
	inputStates = BZBInput[pn][1];
	inputPersist = BZBInput[pn][2];
	
	for rcpi = 1,4 do
		inputPersist[rcpi] = inputPersist[rcpi] * inputPersistenceFactor + (inputStates[rcpi] and (1-inputPersistenceFactor) or 0);
	end
	
	local ax = (inputPersist[4] - inputPersist[1]);
	local ay = (inputPersist[3] - inputPersist[2]);
	local allowMove = BZBAllowMove(pn);
	
	local axPerturb = inputPerturbanceFactor * math.cos(overtime * math.pi / 13.0) * (pn == 2 and 1 or -1);
	local ayPerturb = inputPerturbanceFactor * math.sin(overtime * math.pi / 13.0);	
	ax = ax + axPerturb;
	ay = ay + ayPerturb;	
	
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
		if (pn == 1 and (xn > SCREEN_CENTER_X or xn > bd.x_end)) or
		   (pn == 2 and (xn < SCREEN_CENTER_X or xn < bd.x_end)) then
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
			:xy(320, 591)
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
				:xy(320 + BTIUtil_SideSign(i) * 64, 313)
				:zoom(0.75)
				:z(0.2);
		end,
	}
	BZBFrame[#BZBFrame + 1] = Def.Sprite {
		Name = "bzbHand"..i,
		Texture = "hand.png",
		InitCommand = function(self)
			self:aux( tonumber(string.match(self:GetName(), "([0-9]+)")) )
				:xy(320 + BTIUtil_SideSign(i) * 308,  84)
				:z(0.1)
				:zoomx(BTIUtil_SideSign(i));
		end,
		BZBUpdateMessageCommand = function(self)
			self:y( BZBData[self:getaux()].y_throw );
		end,
	}
	BZBFrame[#BZBFrame + 1] = Def.ActorFrame {
		Name = "bzbBall"..i,
		Def.Sprite {
			Name = "bzbBallInner"..i,
			Texture = "ball.png",
			InitCommand = function(self)
				--TODO: follow splines
				self:aux( tonumber(string.match(self:GetName(), "([0-9]+)")) )
					:xy(320 + BTIUtil_SideSign(i) * 288, 0)
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
				:xy(320 + BTIUtil_SideSign(i) * 64, 313)
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
				self:xy(320 + BTIUtil_SideSign(i) * (32 + 256 * xi / resultRowLength), 420 + 32 * yi)
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
				self:xy(320 + BTIUtil_SideSign(i) * (32 + 256 * xi / resultRowLength), 420 + 32 * yi)
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
			self:xy(320 + BTIUtil_SideSign(i) * 112, 80);
		end,
	}
	for rcpi = 1,4 do
		bzbReceptorsThisSide[#bzbReceptorsThisSide + 1] = NOTESKIN:LoadActorForNoteSkin("Down", "Receptor", "cyber") ..{
			Name = "bzbReceptor"..i.."_"..rcpi,
			InitCommand = function(self)
				self:x(bzbReceptorPlacement[rcpi][1] * 33)
					:y(bzbReceptorPlacement[rcpi][2] * 33)
					:rotationz(bzbReceptorPlacement[rcpi][3])
					:zoom(0.75)
					:z(0.5)
					:diffusealpha(0.3);
			end,
			-- TODO: add listeners for the player stepping on the pads!!
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
				:xy(320 + BTIUtil_SideSign(i) * 160, 160)
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







-------------------------------------------------------------------------------
--
-- 		Proxies (as usual)
--
--		idk, let's make three. to have
--
local circleAroundXExtent = sw/4;
local circleAroundYExtent = sh/12;

local remP1Location = {nil, nil};

for i = 1,3 do
	theBoys[#theBoys + 1] = Def.ActorFrame {	
		Name = "ProxyP1Outer_"..i,
		Def.ActorFrame {	
			Name = "ProxyP1Inner_"..i,
			Def.ActorProxy {					
				Name = "ProxyP1",
				BeginCommand=function(self)
					local McCoy = SCREENMAN:GetTopScreen():GetChild('PlayerP1');
					if McCoy then self:SetTarget(McCoy); else self:hibernate(1573); end
				end,
				OnCommand=function(self)
					local McCoy = SCREENMAN:GetTopScreen():GetChild('PlayerP1');
					if McCoy then self:xy(-McCoy:GetX(), -McCoy:GetY()); end
				end
			},
			InitCommand = function(self)
				self:aux( tonumber(string.match(self:GetName(), "_([0-9]+)")) );
			end,
			OnCommand = function(self)
				local McCoy = SCREENMAN:GetTopScreen():GetChild('PlayerP1');
				remP1Location[1] = McCoy:GetX();
				remP1Location[2] = McCoy:GetY();
				if McCoy then self:xy(remP1Location[1], remP1Location[2]); end
			end,
			
			
			CircleAroundMessageCommand = function(self)
				self:decelerate((2 + (self:getaux()-1) * (8/3)) / BPS)
					:addy(circleAroundYExtent)
					:queuecommand("CircleUp");
			end,
			CircleUpCommand = function(self)
				self:smooth(4.0/BPS)
					:addy(-2 * circleAroundYExtent)
					:queuecommand("CircleDown");
			end,
			CircleDownCommand = function(self)
				self:smooth(4.0/BPS)
					:addy(2 * circleAroundYExtent)
					:queuecommand("CircleUp");
			end,
			CircleEndMessageCommand = function(self)
				self:stoptweening()
					:smooth(1.0/BPS)
					:xy(remP1Location[1], remP1Location[2]);
			end,
		},
		InitCommand = function(self)
			self:aux( tonumber(string.match(self:GetName(), "_([0-9]+)")) );
		end,
		OnCommand = function(self)
			self:xy(0, 0);
		end,
		CircleAroundMessageCommand = function(self)
			self:decelerate((self:getaux()-1) * (8/3) / BPS)
				:addx(circleAroundXExtent)
				:queuecommand("CircleLeft");
		end,
		CircleLeftCommand = function(self)
			self:smooth(4.0/BPS, RoundBezier)
				:addx(-2 * circleAroundXExtent)
				:queuecommand("CircleRight");
		end,
		CircleRightCommand = function(self)
			self:smooth(4.0/BPS, RoundBezier)
				:addx(2 * circleAroundXExtent)
				:queuecommand("CircleLeft");
		end,
		CircleEndMessageCommand = function(self)
			self:stoptweening()
				:smooth(1.0/BPS)
				:xy(0, 0);
		end,
	}

	theBoys[#theBoys + 1] = Def.ActorFrame {
		Name = "ProxyP2_"..i,
		Def.ActorProxy {					
			Name = "Proxy",
			BeginCommand=function(self)
				local McCoy = SCREENMAN:GetTopScreen():GetChild('PlayerP2');
				if McCoy then self:SetTarget(McCoy); else self:hibernate(1573); end
			end,
			OnCommand=function(self)
				local McCoy = SCREENMAN:GetTopScreen():GetChild('PlayerP2');
				if McCoy then self:xy(-McCoy:GetX(), -McCoy:GetY()); end
				self:visible(false);
			end
		},
		InitCommand = function(self)
			self:aux( tonumber(string.match(self:GetName(), "_([0-9]+)")) )
				:visible(false);
		end,
		OnCommand = function(self)
			local McCoy = SCREENMAN:GetTopScreen():GetChild('PlayerP2');
			if McCoy then self:xy(McCoy:GetX(), McCoy:GetY()); end
		end,
	}
end


--
-- Bell proxies & AFT
--




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
							:rotationz(myColorIndex * 1 - 2)
							:zoom(1.005)
							:diffuse({1,1,1,0.0})
							:visible(true);
					end,
					["StopTrailP"..pn.."MessageCommand"]=function(self)
						self:diffuse({1,1,1,0.0});
					end,
					["StartTrailP"..pn.."MessageCommand"]=function(self)
						self:diffuse({1,1,1,0.98});
					end
				},
				Def.ActorProxy {					
					Name = "ProxyP"..pn,
					BeginCommand=function(self)
						local p = SCREENMAN:GetTopScreen():GetChild('PlayerP'..string.match(self:GetName(), "ProxyP([12])"));
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
					self:blend("BlendMode_Add")
						:diffuse(ghostColors[myColorIndex]);
				end
			};
			
		table.insert(theBoys, aftMemory);
		table.insert(theBoys, aftOutput);
		table.insert(theBoys, ghostBoy);
	end
end

--
-- Special bell ghost (player 2)
--
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
					Name = "ProxyP2A",
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
					self:xy(sw * 1/6, 0.375*sh)
						:zoom(0.8);
				end,
			},
			Def.ActorFrame {
				Def.ActorProxy {					
					Name = "ProxyP2B",
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
						:zoom(0.8);
				end,
			},
			OnCommand=function(self)
				self:diffusealpha(0.0);
			end,
			BellDingMessageCommand=function(self)
				self:diffusealpha(1.0)
					:linear(8.0 / BPS)
					:diffusealpha(0.0);
			end,
		},
	};
	
theBoys[#theBoys+1] = Def.Sprite{
		Name = "BellGhost",
		Texture = "BellGhostOutput",
		InitCommand=cmd(Center),
		OnCommand=function(self)
			self:blend("BlendMode_Add")
		end
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
-- 		This is where the shit will be happening.
--

local messageList = {
	{   4.0, "BellDing"},
	{   8.0, "CircleAround"},
	{  16.0, "BellDing"},
	{  24.0, "CircleEnd"},
--	{   8.0, "BZBStart"},
--	{  16.0, "BZBThrow"},
--	{  24.0, "BZBEnd"},
	{ 104.0, "BZBRateMyProfessor"},
};

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
		local overtime = GAMESTATE:GetSongBeat();
		
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
					MESSAGEMAN:Broadcast( messageList[curmessage+1][2] );
					
					curmessage = curmessage + 1;
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
local cspd = 2.2;
local modsTable = {
	-- [1]: beat start
	-- [2]: mod type
	-- [3]: mod strength (out of unity),
	-- [4]: mod approach (in beats to complete)
	-- [5]: player application (1 = P1, 2 = P2, 3 = both, 0 = neither)
		
		{   0.0,	"ScrollSpeed",	 cspd,    3.0,	3}, 
		
		
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
	["Confusion"] =		"FLOAT", 	-- yuck
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

local fifthModsHQ = Def.Quad {
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
			Trace('>>> fifthModsHQ: Hibernated!!');
			self:hibernate(600);
			do return end
		else
			while modsLaunched < #modsTable do
				-- Trace('>>> enjoyModsHQ: ' .. modsLaunched);
				-- Check the next line of the mods table.
				nextMod = modsTable[modsLaunched + 1];
				
				if overtime + modsLeadBy >= nextMod[1] then
					-- TODO: this assumes the effect applies over a constant BPM section!!
					Trace('>>> fifthModsHQ: ' .. modsLaunched .. ' @ time = ' .. overtime);
					
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
							Trace('>>> enjoyModsHQ: ' .. opVal      .. ' @ rate = ' .. opApproach  .. ' for ' .. pe);
							Trace('>>> enjoyModsHQ: ' .. nextMod[3] .. ' @ rate = ' .. newApproach .. ' for ' .. pe .. ' [New!]');
						end
					end
					
					modsLaunched = modsLaunched + 1;
				else
					-- Trace('>>> enjoyModsHQ: ' .. overtime .. ' < ' .. nextMod[1]);
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
table.insert(theBoys, fifthModsHQ);

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

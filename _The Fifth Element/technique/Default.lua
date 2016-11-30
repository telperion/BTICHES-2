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
local bpm = 140;
local ofs = 0.000;	-- TODO
local plr = {nil, nil};
local curmessage = 1;
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

-------------------------------------------------------------------------------
--
-- 		BUZZIBEE no jutsu
--
local attempts = 12;
local lineWidth = 6;

local BZBFrame = Def.ActorFrame {};

local BZBData = {};
for i = 1,2 do
	local s = (i == 2) and 1 or -1;
	BZBData[i] = {
		vx = -10*s,						-- **	**	Initial horizontal velocity
		vy =  -3*s,						-- 		**	Initial vertical velocity
		
		x_throw 	= 320 - 264*s,		-- (const)	Horizontal position from which ball is thrown
		x_bounce 	= nil,				-- (calc)	Horizontal position at which ball bounces first time
		x_rebounce 	= nil,				-- (calc)	Horizontal position at which ball bounces second time
		x_near 		= 320 - 144*s,		-- (const)	Horizontal position of left side of cup
		x_far	 	= 320 -  16*s,		-- (const)	Horizontal position of right side of cup
		x_edge 		= nil,				-- (calc)	Horizontal position of ball meeting edge
		
		y_throw 	=  84,				-- **		Vertical position from which ball is thrown
		y_table 	= 360,				-- (const)	Vertical position of table surface, ball bounces, and base of cup
		y_edge 		= 212,				-- (const)	Vertical position of cup edge

		succ 		= 0,				-- Would currently make the shot
		
		elasticity = 0.9,				-- Ball bounce elasticity
		acceleration = 10,				-- Ball acceleration due to gravity (in pixels per beat squared!)

		totalSucc = 0					-- Successes
	};
end

local BZBRateMyProfessor = function(succ)
		if succ > 9 then do return 1 end
	elseif succ > 6 then do return 2 end
	elseif succ > 4 then do return 3 end
	elseif succ > 2 then do return 4 end
	else 				 do return 5 end
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
	
	local vb1 = math.sqrt(bd.vy + 4 * bd.acceleration * (bd.y_throw - bd.y_table));		-- vertical velocity on bounce 1
	local tb1 = 0.5 * (bd.vy + vb1) / bd.acceleration;									-- time at bounce 1
	local tb2 = bd.elasticity * vb1 / bd.acceleration;									-- time at bounce 2 (relative to bounce 1)
	
	local tce = 0.5 * (squarelastic * vb1 - math.sqrt(squarelastic * squarelastic * vb1 * vb1 - 4 * bd.acceleration * (bd.y_edge - bd.y_table))) / bd.acceleration;
	local t_total = tb1 + tb2 + tce;													-- time ball would reach height of cup edge on second bounce (relative to bounce 2)
	
	bd.x_bounce 	= bd.x_throw 	+ bd.vx * tb1;
	bd.x_rebounce 	= bd.x_bounce 	+ bd.vx * tb2;
	
	local tss = 0.5 * (bd.elasticity * vb1 + math.sqrt(squarelastic * vb1 * vb1 - 4 * bd.acceleration * (bd.y_edge - bd.y_table))) / bd.acceleration;
																						-- time ball would come down to height of cup edge on first bounce (relative to first bounce)
	bd.x_edge		= bd.x_bounce	+ bd.vx * tss;
	
	if pn == 1 then
		bd.succ = (bd.x_edge >= bd.x_near) and (bd.x_edge <= bd.x_far);
	else
		bd.succ = (bd.x_edge <= bd.x_near) and (bd.x_edge >= bd.x_far);
	end
	
	
	-- Check when the ball will hit the edge of the cup.
	-- TODO; can just go behind the cup for now :)
	
	for t = 0,t_total,timestep do
		-- Don't draw into the other player's field.
		if (pn == 1 and xn > SCREEN_CENTER_X) or
		   (pn == 2 and xn < SCREEN_CENTER_X) then
			break
		end
		-- Don't overdraw if we already made it.
		if currSucc and t > tss then
			break
		end
		
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
			tt = t - tb2;

			local an = bd.acceleration;
			local bn = -vb1 * squarelastic;
			local cn = bd.y_table;
			verts[#verts + 1] = {{bd.x_rebounce + bd.vx * tt, an*tt*tt + bn*tt + cn, 0}, colorator};
			
		end
		
	end
	
	return verts;	
end
local BZBProhibitMove = function(pn)
	-- Constrain the range of player throws by making sure the ball bounces only once.
	-- Zero times, or twice, is not allowed.	
end



BZBFrame[#BZBFrame + 1] = Def.Sprite {
	Name = "bzbTable",
	Texture = "table2-cy144.png",
	InitCommand = function(self)
		self:xy(320, 591)
			:z(0.0);
	end,
}
for i = 1,2 do
	BZBFrame[#BZBFrame + 1] = Def.Sprite {
		Name = "bzbHand"..i,
		Texture = "hand.png",
		InitCommand = function(self)
			self:aux( tonumber(string.match(self:GetName(), "([0-9]+)")) )
				:xy(320 + BTIUtil_SideSign(i) * 284,  84)
				:z(0.1)
				:zoomx(BTIUtil_SideSign(i));
		end,
		UpdateBZBMessageCommand = function(self)
			self:y( BZBData[self:getaux()].y_throw );
		end,
	}
	BZBFrame[#BZBFrame + 1] = Def.Sprite {
		Name = "bzbBall"..i,
		Texture = "ball.png",
		InitCommand = function(self)
			--TODO: follow splines
			self:aux( tonumber(string.match(self:GetName(), "([0-9]+)")) )
				:xy(320 + BTIUtil_SideSign(i) * 264, 84)
				:z(0.2);
		end,
		UpdateBZBMessageCommand = function(self)
			self:y( BZBData[self:getaux()].y_throw );
		end,
	}
	BZBFrame[#BZBFrame + 1] = Def.ActorMultiVertex {
		Name = "bzbTrail"..i,
		InitCommand = function(self)
			self:aux( tonumber(string.match(self:GetName(), "([0-9]+)")) )
				:SetLineWidth(lineWidth)
				:SetDrawState{Mode = "DrawMode_LineStrip", First= 1, Num= -1}
				:SetVertices({})
				:xy(0, 0)
				:z(0.25);
		end,
		UpdateBZBMessageCommand = function(self)
			if not inTheMiddleOfThrowing then
				local verts = BZBUpdateDataModel(self:getaux(), 0.1);			
				self:SetVertices(verts);
			end
		end,
	}
	BZBFrame[#BZBFrame + 1] = Def.Sprite {
		Name = "bzbRSC"..i,
		Texture = "rsc.png",
		InitCommand = function(self)
			self:aux( tonumber(string.match(self:GetName(), "([0-9]+)")) )
				:xy(320 + BTIUtil_SideSign(i) * 80, 292)
				z(0.3);
		end,
	}
	for sfi = 1,attempts do
		BZBFrame[#BZBFrame + 1] = Def.Sprite {
			Name = "bzbResult"..i.."_"..sfi,
			Texture = "fail.png",
			InitCommand = function(self)
				self:xy(320 + BTIUtil_SideSign(i) * (32 + 256 * (sfi-1) / (attempts-1)), 420)
					:z(0.4)
					:diffusealpha(0.0);
			end,
			SuccCommand = function(self)
				self:SetTexture("succ.png")
					:diffusealpha(0.0)
					:zoom(0.5)
					:bounceend(0.5)
					:diffusealpha(1.0)
					:zoom(1.0);
			end,
			FailCommand = function(self)
				self:SetTexture("fail.png")
					:diffusealpha(0.0)
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
			end,
			["P"..i..bzbReceptorNames[rcpi].."OffMessageCommand"] = function(self)
				self:diffusealpha(0.3);
			end,
		}
	end
	for ctdi = 1,4 do
		bzbReceptorsThisSide[#bzbReceptorsThisSide + 1] = Def.Sprite {
			Name = "bzbCountdown"..i.."_"..(4-ctdi),
			Texture = "ctd"..(4-ctdi)..".png",
			InitCommand = function(self)
				self:xy(0, 0)
					:z(0.6)
					:diffuse(BTIUtil_Scale(ctdi, 1.0, 4.0, 1.0, 0.0),
							 BTIUtil_Scale(ctdi, 1.0, 4.0, 0.0, 1.0),
							 0.0, 1.0)
					--:visible(false);
			end,
			TickCommand = function(self)
				self:xy(0, 0)
					:zoom(0.5)
					:visible(true)
					:bounceend(0.5 * 60 / bpm)
					:zoom(1.0)
					:queuecommand("TickOver");
			end,
			TickOverCommand = function(self)
				self:visible(false);
			end,
		}
	end	
	BZBFrame[#BZBFrame + 1] = bzbReceptorsThisSide;
		
	BZBFrame[#BZBFrame + 1] = Def.Sprite {
		Name = "bzbRating"..i,
		Texture = "ratings 1x5.png",
		InitCommand = function(self)
			self:xy(320 + BTIUtil_SideSign(i) * 160, 160)
				:z(1.0)
				:animate(0)
				--:visible(false);
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
-- 		Fungah no jutsu
--





--
-- 		Fungah no jutsu
--
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
--
-- 		Telperion no jutsu
--





--
-- 		Telperion no jutsu
--
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
--
-- 		Proxies (as usual)
--
--		idk, let's make three. to have
--
for i = 1,3 do
	theBoys[#theBoys + 1] = Def.ActorFrame {
		Name = "ProxyP1_"..i,
		Def.ActorProxy {					
			Name = "Proxy",
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
			self:aux( tonumber(string.match(self:GetName(), "_([0-9]+)")) )
				:visible(false);
		end,
		OnCommand = function(self)
			local McCoy = SCREENMAN:GetTopScreen():GetChild('PlayerP1');
			if McCoy then self:xy(McCoy:GetX(), McCoy:GetY()); end
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
-- 		Proxies (as usual)
--
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
--
-- 		This is where the shit will be happening.
--
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
		local BPS = GAMESTATE:GetSongBPS();	
		
		-- Who's interesting today?
		if overtime >=  0.0 and fgcurcommand ==  0 then
			for i,v in ipairs(plr) do
				if v then
					v:decelerate(16.0 / BPS):y(sh/2 - 30):z(0);
				end
			end
			
			fgcurcommand = fgcurcommand + 1;
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
					local BPS = GAMESTATE:GetSongBPS();
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
				
		noteskinSet = true;
		if hadToSetNoteskin then
			SCREENMAN:SetNewScreen("ScreenGameplay"):StartTransitioningScreen("SM_GoToNextScreen");
		end
		
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

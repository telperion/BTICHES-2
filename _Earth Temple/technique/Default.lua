-------------------------------------------------------------------------------
--
--		Special Content to Exercise the Player's Earthbending Technique
--		
--		Author: 	Telperion
--		Date: 		2016-11-25
--
-------------------------------------------------------------------------------

local sw = SCREEN_WIDTH;
local sh = SCREEN_HEIGHT;
local bpm = 170;
local ofs = -2.040;
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



-------------------------------------------------------------------------------
--
-- 		Some graphical doods 'n' dads 'n' doodads.
--
-------------------------------------------------------------------------------
local numArrows = {["4th"] = 45,  ["32nd"] = 30,    ["48th"] = 15};		-- Number of arrows to instantiate
local texArrows = {["4th"] = 0.0, ["32nd"] = 0.625, ["48th"] = 0.75};	-- Texture coordinate shifts

local felysNotes = {};
local stronk = 64;
for quantColor,quantCount in pairs(numArrows) do
	Trace("> making scary "..quantColor.." notes");
	for i = 1,quantCount do
		local pos = {math.cos(i/quantCount * 2 * math.pi) * stronk, math.sin(i/quantCount * 2 * math.pi) * stronk};
		
		Trace("> making scary "..quantColor.." note #"..i);
		felysNotes[#felysNotes + 1] = NOTESKIN:LoadActorForNoteSkin("Down", "Tap Note", "cyber") .. {
			Name = "ScaryNote"..quantColor.."_"..i,
			InitCommand = function(self)
				self:visible(true)
					:xy(sw/2 + pos[1], sh/2 + pos[2])
					:texturetranslate(texArrows[quantColor], 0);
			end,
		};
		Trace(">>> made scary "..quantColor.." note #"..i);
	end
	stronk = stronk + 64;
end

for i = 1,#felysNotes do
--	table.insert(theBoys, felysNotes[i]);
end

-------------------------------------------------------------------------------
--
-- 		This is where the shit will be happening.
--
local BTIUtil_Scale = function(t, inLower, inUpper, outLower, outUpper)
	local ti = (t - inLower) / (inUpper - inLower);
	return outLower + ti * (outUpper - outLower);
end


local enjoyGfxHQ = Def.Quad {
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
table.insert(theBoys, enjoyGfxHQ);


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
		
		{   0.0,	"ScrollSpeed",	 cspd,    2.0,	3}, 
		
		
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

local enjoyModsHQ = Def.Quad {
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
			Trace('>>> enjoyModsHQ: Hibernated!!');
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
					Trace('>>> enjoyModsHQ: ' .. modsLaunched .. ' @ time = ' .. overtime);
					
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
table.insert(theBoys, enjoyModsHQ);

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

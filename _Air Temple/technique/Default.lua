-------------------------------------------------------------------------------
--
--		Special Content to Exercise the Player's Airbending Technique
--		
--		Author: 	Telperion
--		Date: 		2016-10-16
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

-------------------------------------------------------------------------------
--		Mostly lifted from Kyzentun's clean rewrite of
--						   TaroNuke's arbitrary mods generator.
--		No sense rewriting code that I can just Ctrl+C, right?...
--
--	BEGIN 					Arbitrary Mods Generation					BEGIN
-------------------------------------------------------------------------------
-- Reflection into the eden. What's CapitalCase?
for func_name, func in pairs(PlayerOptions) do
   PlayerOptions[func_name:lower()]= func
end

-- Option recording.
local poptions= {}
-- Read down whatever options were applied going into the file.
for i, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
   poptions[pn]= GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Song")
end

-- Comprehensive list of available mods.
local float_mods= {
   "Boost", "Brake", "Wave", "Expand", "Boomerang", "Drunk", "Dizzy",
   "Confusion", "Mini", "Tiny", "Flip", "Invert", "Tornado", "Tipsy",
   "Bumpy", "Beat", "Xmode", "Twirl", "Roll", "Hidden", "HiddenOffset",
   "Sudden", "SuddenOffset", "Stealth", "Blink", "RandomVanish", "Reverse",
   "Split", "Alternate", "Cross", "Centered", "Dark", "Blind", "Cover",
   "RandAttack", "NoAttack", "PlayerAutoPlay", "Tilt", "Skew", "Passmark",
   "RandomSpeed",
}
-- Use this function to clear all mods.
local function clear_mods(pn)
   poptions[pn]:XMod(1)
   for i, mod in ipairs(float_mods) do
      poptions[pn][mod](poptions[pn], 0)
   end
end

local num_chars= {["-"]= true}
for i= 0, 9 do num_chars[tostring(i)]= true end

-- Apply a mod from a string specification.
local function apply_mod(mod, pn)
   mod= mod:lower()
   local sub_mods= split(",", mod)
   for i, sub in ipairs(sub_mods) do
      local level= 1
      local speed= 1
      local parts= split(" ", sub)
      for p, par in ipairs(parts) do
         local first_char= par:sub(1, 1)
         if par == "no" then
            level= 0
         else
            local before_num, num, after_num= par:match("(*?)([%d%-%.]+)([x%%%*]?)")
            num= tonumber(num)
            if num and after_num ~= "x" then
               if before_num == "*" or after_num == "*" then
                  speed= num
               else
                  level= num / 100
               end
            end
         end
      end
      local mod_name= parts[#parts]
      if PlayerOptions[mod_name] then
         poptions[pn][mod_name](poptions[pn], level, speed)
      elseif mod_name == "clearall" then
         clear_mods(pn)
      else
         local corm, value, xm= mod_name:match("([cm]?)([%d%-%.]+)(x?)")
         value= tonumber(value)
         if xm == "x" then
            poptions[pn]:XMod(value, speed)
         elseif corm == "c" then
            poptions[pn]:CMod(value, speed)
         elseif corm == "m" then
            poptions[pn]:MMod(value, speed)
         end
      end
   end
end
-------------------------------------------------------------------------------
--	 END 					Arbitrary Mods Generation					 END
-------------------------------------------------------------------------------



local cyberWidth = 20;
local cyberHeight = 30;
local cyberXStep = 2 * sw/cyberWidth/2;		-- Needs to be larger than half-screen to accommodate rotation
local cyberYStep = 2 * sh/cyberHeight;		-- Needs to be larger than half-screen to accommodate rotation
local cyberMinor = cyberWidth > cyberHeight and cyberHeight or cyberWidth;
local cyberMajor = cyberWidth > cyberHeight and cyberWidth or cyberHeight;
local cyberCenterX = cyberWidth/2;
local cyberCenterY = cyberHeight/2;

local cyberColorator = 1;



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



local cyberParameter = 0;
local cyberSkin = Def.ActorFrame {
	Name = "cyberSkin",
	InitCommand = function(self)
		self:SetWidth(sw/2 + 2)
			:SetHeight(sh + 2)
			:xy(sw/4, sh/2);
	end
};
local cyberModulator = 257;
local cyberGenerator = 12;
local cyberColorator = 1;
for cyberCol = 0,cyberWidth-1 do
	for cyberRow = 0,cyberHeight-1 do
		table.insert(cyberSkin,
			Def.Quad {
				Name = "cyberSkin_"..cyberCol.."_"..cyberRow,
				InitCommand = function(self)
					cyberColorator = math.fmod(cyberColorator * cyberGenerator, cyberModulator);
					local c = cyberColorator / cyberModulator;
					local cyberGreening = c < 0.5 and c + 0.5 or 1.0;
					local cyberBluing   = c < 0.5 and 0.0 or c - 0.5;
					self:zoomto(cyberXStep, cyberYStep)
						:xy((cyberCol + 0.5 - cyberWidth*0.5) * cyberXStep, (cyberRow + 0.5 - cyberHeight*0.5) * cyberYStep)
						:diffuse( color("0.0,"..cyberGreening..","..cyberBluing..",0.0") );
					Trace("Initialized cyberskin element: ("..cyberCol..", "..cyberRow..")");
				end,
				OnCommand = function(self)
				end				
			}
		);
	end
end

local cyberSkinP1 = Def.Sprite {
	Name = "cyberSkinP1",
	InitCommand = function(self)
		self:xy(  sw/4, sh/2);
		Trace("Drawn cyberskin for P1");
	end
};
local cyberSkinP2 = Def.Sprite {
	Name = "cyberSkinP2",
	InitCommand = function(self)
		self:zoomx(-1)
			:xy(3*sw/4, sh/2);
		Trace("Drawn cyberskin for P2");
	end
};
table.insert(theBoys, cyberSkinP1);
table.insert(theBoys, cyberSkinP2);



local cyberSkinTexName = "cyberSkinTex";
local cyberTexSet = {false, false};
local cyberSkinTex = Def.ActorFrameTexture {
	Name = "cyberSkinTex",
	InitCommand = function(self)
		self:SetWidth(sw/2 + 2)
			:SetHeight(sh + 2)
			:xy(0, 0)
			:EnableAlphaBuffer(true)
			:EnableDepthBuffer(true)
			:Create();
	end,
	OnCommand = function(self)
		-- Set myself as the texture of two sprites.
		if self:GetTexture() then
			if not cyberTexSet[1] then
				cyberTexSet[1] = self:GetParent():GetChild("cyberSkinP1");
				if cyberTexSet[1] then
					cyberTexSet[1]:SetTexture( self:GetTexture() );
				end
			end
			if not cyberTexSet[2] then
				cyberTexSet[2] = self:GetParent():GetChild("cyberSkinP2");
				if cyberTexSet[2] then
					cyberTexSet[2]:SetTexture( self:GetTexture() );
				end
			end
		end
	end
};
table.insert(cyberSkinTex, cyberSkin);
table.insert(theBoys, cyberSkinTex);


-------------------------------------------------------------------------------
--
-- This is where the shit will be happening.
--
local BTIUtil_Scale = function(t, inLower, inUpper, outLower, outUpper)
	local ti = (t - inLower) / (inUpper - inLower);
	return outLower + ti * (outUpper - outLower);
end

local CalcCyberEase = function(t)
	return t;
end

local CalcCyberWave = function(r, t)
	local waveSpread	= 4.0;		-- Spreading rate in units/beat
	local waveWidth		= 1.5;		-- Width of wave in units
	local waveOpacity	= 6.0;		-- Opacity constant by distance, where 1/(A+1) is minimum opacity
	local waveFieldSize	= (cyberWidth > cyberHeight) and cyberWidth or cyberHeight;		
									-- Opacity constant by distance, where 1/(A+1) is minimum opacity
	local waveProgress = (r / waveWidth - waveSpread * CalcCyberEase(t));
	return (waveFieldSize / (waveOpacity * r + waveFieldSize)) * (1 / (waveProgress * waveProgress + 1));
end

local CalcCyberLine = function(x, y, theta, t)
	-- The line always passes through (0, 0), so offset x and y if necessary.
	-- theta represents the angle of the line in degrees.
	local lineSpread	= 1.0;		-- Spreading rate in units/beat
	local lineDecay		= 1.0;		-- Decaying opacity rate in units/beat
	local lineWidth		= 0.5;		-- Width of wave in units
	
	local r = y * math.cos(DEG_TO_RAD * theta) - x * math.sin(DEG_TO_RAD * theta);
	local linePresence	= r / (lineWidth + lineSpread * t);
	local linePulse		= 1.0 / (1.0 + linePresence * linePresence);
	return linePulse * 1.0 / (1.0 + lineDecay*lineDecay * t*t);
end

local CalcCyberStripe = function(x, y, theta, d, t)
	-- The basis line always passes through (0, 0), so offset x and y if necessary.
	-- theta represents the angle of the stripes in degrees.
	-- d represents the spacing between stripes.
	local stripeDecay	= 1.0;		-- Decaying opacity rate in units/beat
	local stripeWidth	= 0.5;		-- Duty cycle / stretching of wave (TODO: figure out a clean way to do this)
	
	if not t then do return 0.0 end end
	
	local r = y * math.cos(DEG_TO_RAD * theta) - x * math.sin(DEG_TO_RAD * theta);
	local stripePulse	= 0.5 + 0.5 * math.cos(2 * math.pi * r / d);
	return stripePulse*stripePulse * 1.0 / (1.0 + stripeDecay*stripeDecay * t*t);
end

-- Find the radial distance in cyberskin patches from the center.
local CalcCyberRadialPos = function(x, y)
	xi = (x - cyberWidth*0.5 + 0.5);
	yi = (y - cyberHeight*0.5 + 0.5);
	return math.sqrt(xi*xi + yi*yi);
end


local cyberGfxHQ = Def.Quad {
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
		
		-- Who's interesting today?
		local cyberBaby = self:GetParent():GetChild("cyberSkinTex"):GetChild("cyberSkin");
		
		-- One rotation every 16 beats.
		local cyberRotX = math.sin(overtime * math.pi / 8) * (overtime / 12 + 10);
		local cyberRotZ = math.cos(overtime * math.pi / 8) * (overtime / 24 + 5);
		if cyberBaby then
			cyberBaby:rotationx(cyberRotX)
					 :rotationz(cyberRotZ);					 
		end
		if plr[1] then
			plr[1]:rotationx(cyberRotX)
				  :rotationz(cyberRotZ)
				  :z(1);
		end
		if plr[2] then
			plr[2]:rotationx(cyberRotX)
				  :rotationz(-cyberRotZ)
				  :z(1);
		end
		
		-- Pulse colors based on certain beat cues.
		local pulseDing		= {9.5,       25.5,     41.5,       57.5, 73.5,       89.5,     105.5,        121.5 };
		local pulseSamba	= {     17.5,                 49.5,             81.5,                  113.5        };
		local pulseSigh		= {1,2,3,4                                                                          };
		local pulseUnsigh	= {                 32,                                     96                      };
		local waveFadeoff	= 8.0;		-- Fade out the wave after this many beats
		local waveCutoff	= 12.0;		-- Cut off the wave after this many beats
		local unsighLength	= 2.0;		-- Sharp intake of breath lasts this many beats
		
		for moniker,starlet in pairs(cyberBaby:GetChildren()) do
			local xs, ys = string.match(moniker, "cyberSkin_(%d+)_(%d+)")
			if xs or ys then
				local x = tonumber(xs);
				local y = tonumber(ys);
				local alphaDerived = 0.0;
				
				for _,p in pairs(pulseDing) do
					local t = overtime - p;
					local waveFade = 1.0;
					if t >= 0.0 and t < waveCutoff then
						if t >= waveFadeoff then
							waveFade = BTIUtil_Scale(t, waveFadeoff, waveCutoff, 1.0, 0.0);
						else
							waveFade = 1.0;
						end
						
						alphaDerived = alphaDerived + CalcCyberWave( CalcCyberRadialPos(x, y), t ) * waveFade;
					end
				end
				
				for _,p in pairs(pulseSigh) do
					local t = overtime - p;
					local waveFade = 1.0;
					if t >= 0.0 and t < waveCutoff then
						if t >= waveFadeoff then
							waveFade = BTIUtil_Scale(t, waveFadeoff, waveCutoff, 1.0, 0.0);
						else
							waveFade = 1.0;
						end
						
						alphaDerived = alphaDerived + CalcCyberLine( x - cyberCenterX, y - cyberCenterY, 45, t ) * waveFade;
						alphaDerived = alphaDerived + CalcCyberLine( x - cyberCenterX, y - cyberCenterY, 135, t ) * waveFade;
					end
				end
				
				for _,p in pairs(pulseSamba) do
					local t = overtime - p;
					local waveFade = 1.0;
					if t >= 0.0 and t < waveCutoff then
						if t >= waveFadeoff then
							waveFade = BTIUtil_Scale(t, waveFadeoff, waveCutoff, 1.0, 0.0);
						else
							waveFade = 1.0;
						end
						
						local t2 = t > 0.75 and t - 0.75 or nil;
						local t3 = t > 1.5  and t - 1.5  or nil;
						alphaDerived = alphaDerived + CalcCyberStripe( x - cyberCenterX, y - cyberCenterY, 60,  cyberMinor*0.25, t  ) * waveFade;
						alphaDerived = alphaDerived + CalcCyberStripe( x - cyberCenterX, y - cyberCenterY, 120, cyberMinor*0.25, t2 ) * waveFade;
						alphaDerived = alphaDerived + CalcCyberStripe( x - cyberCenterX, y - cyberCenterY, 0,   cyberMinor*0.25, t3 ) * waveFade;
					end
				end
				
				for _,p in pairs(pulseUnsigh) do
					local t = overtime - p;
					local waveFade = 0.0;
					if t <= unsighLength/4.0 and t > -unsighLength then
						local unsighTime = t / unsighLength;
						waveFade = 1.0 + (unsighTime < 0 and unsighTime or -4.0*unsighTime);
						
						local unsighOpacity = 0.8;
						local waveFadePowered = waveFade*waveFade;
						alphaDerived = alphaDerived + waveFadePowered*unsighOpacity;
					end
				end
				
				alphaDerived = alphaDerived > 1.0 and 1.0 or alphaDerived;
				alphaDerived = alphaDerived < 0.3 and 0.3 or alphaDerived;
				starlet:diffusealpha(alphaDerived);
			end
		end
		
		
		-- Wait a bit and then update again!
		self:queuecommand("WaitABit");
	end,
	WaitABitCommand = function(self)
		self:sleep(0.02);
		self:queuecommand("Update");
	end
}
-- table.insert(theBoys, cyberGfxHQ);


local cyberModsTable = {
	-- [1]: beat start
	-- [2]: mod type
	-- [3]: mod strength (out of unity),
	-- [4]: mod approach (in beats to complete)
	-- [5]: player application (1 = P1, 2 = P2, 3 = both, 0 = neither)
		
		{ 32.0,	"Flip",			 0.5,   2.0, 3}, 
		{ 36.0,	"Flip",			 0.0,   2.0, 3}, 
		{ 38.0,	"Expand",		 0.5,  16.0, 3}, 
		{ 40.0,	"Invert",		 0.5,   2.0, 3}, 
		{ 44.0,	"Invert",		 0.0,   2.0, 3}, 
		{ 48.0,	"Flip",			 1.0,   3.0, 3}, 
		{ 48.0,	"Invert",		 0.5,   1.0, 3}, 
		{ 52.0,	"Alternate",	 0.1,  32.0, 3}, 
		{ 52.0,	"Split",		 0.2,  32.0, 3}, 
		{ 52.0,	"Reverse",		-0.2,  32.0, 3}, 
		{ 56.0,	"Flip",			 0.0,   1.0, 3}, 
		{ 56.0,	"Invert",		 0.0,   3.0, 3}, 
	};
local cyberModsLaunched = 0;
local cyberModsWait = 0;
local cyberModsLeadBy = 0.03;

local cyberModsHQ = Def.Quad {
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
		
		if cyberModsLaunched >= #cyberModsTable then
			Trace('>>> cyberModsHQ: Hibernated!!');
			self:hibernate(600);
			do return end
		else
			-- Trace('>>> cyberModsHQ: ' .. cyberModsLaunched);
			-- Check the next line of the mods table.
			cyberNextMod = cyberModsTable[cyberModsLaunched + 1];
			
			if overtime + cyberModsLeadBy >= cyberNextMod[1] then
				-- TODO: this assumes the effect applies over a constant BPM section!!
				local cyberBPS = GAMESTATE:GetSongBPS();
				Trace('>>> cyberModsHQ: ' .. cyberModsLaunched .. ' @ time = ' .. overtime);
				
				for _,pe in pairs(GAMESTATE:GetEnabledPlayers()) do
					if (cyberNextMod[5] == 1 or cyberNextMod[5] == 3) then								-- TODO: FIXME
						pops = GAMESTATE:GetPlayerState(pe):GetPlayerOptions("ModsLevel_Song");
						
						-- Calculate approach (in units of the value per second):
						-- a = (value final - value initial) * (beats per second) / (beats for transition + ``machine epsilon``)
						-- Has to be done individually for each player, just in case they're coming from different initial values :(
						opVal, opApproach = pops[ cyberNextMod[2] ]( pops );
						if opApproach == 0 then -- SOMEONE FUCKED UP AND IT WASN'T ME.
							newApproach = cyberBPS;
						else
							newApproach = math.abs(cyberNextMod[3] - opVal) * cyberBPS / (cyberNextMod[4] + 0.001);
						end
											pops[ cyberNextMod[2] ]( pops, cyberNextMod[3], newApproach );
						Trace('>>> cyberModsHQ: ' .. opVal .. ' @ rate = ' .. opApproach .. ' for ' .. pe);
						Trace('>>> cyberModsHQ: ' .. cyberNextMod[3] .. ' @ rate = ' .. newApproach .. ' for ' .. pe .. ' [New!]');
					end
				end
				
				cyberModsLaunched = cyberModsLaunched + 1;
			else
				-- Trace('>>> cyberModsHQ: ' .. overtime .. ' < ' .. cyberNextMod[1]);
			end
		end		
		
		-- Wait a bit and then update again!
		self:queuecommand('WaitABit');
	end,
	WaitABitCommand = function(self)
		self:sleep(0.02);
		self:queuecommand('Update');
	end
}
table.insert(theBoys, cyberModsHQ);

-------------------------------------------------------------------------------
--
--		Everybody wants to hide the overlay.
--
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
			hamburger:GetChild("Underlay"):decelerate(1.0):diffusealpha(0.0);
		end
		self:hibernate(6000);
	end
}
table.insert(theBoys, hamburgerHelper);
-------------------------------------------------------------------------------




return theBoys;

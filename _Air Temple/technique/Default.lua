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



-------------------------------------------------------------------------------
--	BEGIN 					   Cyberskin Creation						BEGIN
-------------------------------------------------------------------------------
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
						:diffuse(0.0, cyberGreening, cyberBluing, 0.0);
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
--	 END  					   Cyberskin Creation						 END 
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--	BEGIN 					   Airflight Creation						BEGIN
-------------------------------------------------------------------------------
local cyberFlightStrips 	= 10
local cyberFlightOptions 	= 10
local BTIUtil_FakeRandom = function(i, rangeSup)
	-- totally crypto safe. don't @ me
	rangeSup = rangeSup or (cyberFlightOptions+1)
	return math.fmod( math.sqrt(i/rangeSup) * 1000, 1 )
end
local cyberFlightAngle		= function(i) return 15 end
local cyberFlightHeight 	= function(i) return 120 / (1 + 2*i/(cyberFlightOptions-1)) end
local cyberFlightZed	 	= function(i) return 0*i end
local cyberFlightCrossing 	= function(i) return (BTIUtil_FakeRandom(i) - 0.5) * sw end
local cyberFlightUpperColor	= function(i) return {0.5*BTIUtil_FakeRandom(i) + 0.5, 1.0, 1.0} end
local cyberFlightLowerColor	= function(i) r = BTIUtil_FakeRandom(i); return {0.5*r, 0.7*r + 0.3, 0.4*r + 0.6} end
local cyberFlightSpeed	 	= function(i) return 6 / (1 + 5*i/(cyberFlightOptions-1)) end

local cyberFSc = 0.1;
local cyberFV = function(angle, height, crossing, zed, upperColor, lowerColor) 
	local swd2	= cyberFSc * sw/2;
	local swpc	= (swd2 + crossing) * math.sin(angle);
	local swmc	= (swd2 - crossing) * math.sin(angle);
	local hdiv2	= height / 2;
	
	local upperColorA = {upperColor[1], upperColor[2], upperColor[3], 0.8};
	local lowerColorA = {lowerColor[1], lowerColor[2], lowerColor[3], 0.0};
	--
	--                 5
	-- 1            _-¯6
	-- 2¯-_      _-¯
	--     ¯-__-¯
	--     _-¯¯-_
	-- 8_-¯      ¯-_
	-- 7            ¯-_4
	--                 3
	--
	return {
		{{-swd2,  -swpc-hdiv2, zed}, upperColorA},
		{{-swd2,  -swpc+hdiv2, zed}, lowerColorA},
		{{ swd2,   swmc+hdiv2, zed}, lowerColorA},
		{{ swd2,   swmc-hdiv2, zed}, upperColorA},
		{{ swd2,  -swmc-hdiv2, zed}, upperColorA},
		{{ swd2,  -swmc+hdiv2, zed}, lowerColorA},
		{{-swd2,   swpc+hdiv2, zed}, lowerColorA},
		{{-swd2,   swpc-hdiv2, zed}, upperColorA}
	}
end
local cyberFVIndexed = function(i)
	Trace("who turgled? "..i.." >> "..BTIUtil_FakeRandom(i))
	return cyberFV(
		cyberFlightAngle(i),
		cyberFlightHeight(i) * cyberFSc,
		cyberFlightCrossing(i) * cyberFSc,
		cyberFlightZed(i) * cyberFSc,
		cyberFlightUpperColor(i),
		cyberFlightLowerColor(i)
	)
end

local cyberFlight = Def.ActorFrame {
	Name = "cyberFlight",
	Def.ActorMultiVertex {
		Name = "sky",
		InitCommand = function(self)
			self:visible(false)
				:SetWidth(2)
				:SetHeight(24)
				:xy(sw/2, sh/2)
				:SetDrawState{Mode = "DrawMode_Quads"};
		end,
		OnCommand = function(self)
			self:SetVertices({				
					{{-1, -12, 0}, {0.4, 0.7, 0.9, 1.0}},
					{{ 1, -12, 0}, {0.4, 0.7, 0.9, 1.0}},
					{{ 1,  12, 0}, {0.0, 0.3, 0.6, 1.0}},
					{{-1,  12, 0}, {0.0, 0.3, 0.6, 1.0}}
				})
				:zoomto(sw, sh);
		end
	}
};

for i = cyberFlightStrips,1,-1 do
	local cyberSkyAMV = Def.ActorMultiVertex {
		Name = "skyAMV" .. i,
		InitCommand = function(self)
			self:visible(false)
				:xy(sw/2, sh/2)
				:zoom(1/cyberFSc)
				:SetDrawState{Mode = "DrawMode_Quads"};
			self:aux( tonumber(string.match(self:GetName(), "[0-9]+")) );
		end,
		OnCommand = function(self)
			self:SetVertices( cyberFVIndexed(self:getaux()) )
				:diffusealpha(1.0 - (i-1) / cyberFlightOptions);
		end,
		DescentCommand = function(self)
			local BPS = GAMESTATE:GetSongBPS();
			self:visible(true)
				:y(-1.5*sh)
				:linear(12 * BPS / cyberFlightSpeed(self:getaux()))
				:y(1.5*sh)
				:queuecommand("DescentCommand");
		end,
		AscentCommand = function(self)
			local BPS = GAMESTATE:GetSongBPS();
			self:visible(true)
				:y(1.5*sh)
				:linear(12 * BPS / cyberFlightSpeed(self:getaux()))
				:y(-1.5*sh)
				:queuecommand("AscentCommand");
		end	
	}
	table.insert(cyberFlight, cyberSkyAMV);
end

table.insert(theBoys, cyberFlight);
-------------------------------------------------------------------------------
--	 END  					   Airflight Creation						 END 
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
--
-- This is where the shit will be happening.
--
local BTIUtil_Scale = function(t, inLower, inUpper, outLower, outUpper)
	local ti = (t - inLower) / (inUpper - inLower);
	return outLower + ti * (outUpper - outLower);
end

local BTIUtil_ConcatTable = function(base, extension)
	for _,v in pairs(extension) do
		base[#base + 1] = v
	end
	return base
end

local CalcCyberEase = function(t)
	return t;
end

local CalcCyberWave = function(r, t)
	local waveSpread	= 4.0;		-- Spreading rate in units/beat
	local waveWidth		= 1.5;		-- Width of wave in units
	local waveOpacity	= 4.0;		-- Opacity constant by distance, where 1/(A+1) is minimum opacity
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

local fgcDidMyJob = false;
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
		local BPS = GAMESTATE:GetSongBPS();
		
		-- Who's interesting today?
		local cyberBaby 	= self:GetParent():GetChild("cyberSkinTex"):GetChild("cyberSkin");
		local cyberSky	 	= self:GetParent():GetChild("cyberFlight");
		
		-- Get really cyber!
		local cyberMaximum  = false;
		
		-------------------------------------------------------------------------------
		-- Actions for major synchronous phases
		--
		--		0: Setup (relocate playfields)
		--		1: Cyberskin and steps rotate		
		--		2: Cyberskin and steps do not rotate
		--		3: In-flight (ascending)
		--		4: In-flight (reached apex)
		--		5: In-flight (descending)
		--		6: In-flight (reached ground)
		--		7: Cyberskin and steps rotate again
		--
		if fgcurcommand == 0 then
			for i,v in ipairs(plr) do
				if v then
					Trace("P"..i.." Y = "..v:GetY());
					v:decelerate(BPS * 4)
					 :y(sh/2 - 30)
					 :z(1);
				end
			end
			
			fgcurcommand = 1;
		elseif fgcurcommand == 1 then
			local t = overtime;
			local forceScale = 1;
			-- Exception: Beats 256 through 264 scale back the rotation to zero.
			if t > 256 then
				forceScale = 1 - (overtime - 256) / 8;
				forceScale = (forceScale < 0) and 0 or forceScale;
			else 
				-- Exception: Beats {252, 252.75, 253.5, 254.25, 255, 255.5} pause the rotation.
				for _,beatPause in pairs({255.5, 255, 254.25, 253.5, 252.75, 252}) do
					if t > beatPause then
						t = beatPause;
						break;
					end
				end
			end
			-- One rotation every 16 beats.
			local cyberRotX = math.sin(t * math.pi / 8) * (t / 12 + 10) * forceScale;
			local cyberRotZ = math.cos(t * math.pi / 8) * (t / 24 + 5)  * forceScale;
			if cyberBaby then
				cyberBaby:rotationx(cyberRotX)
						 :rotationz(cyberRotZ);					 
			end
			for i,v in ipairs(plr) do
				if v then
					v:rotationx(cyberRotX)
					 :rotationz(cyberRotZ * ((i == 1) and 1 or -1));
				end
			end
			
			if overtime >= 265 then
				if cyberBaby then
					cyberBaby:rotationx(0)
							 :rotationz(0);					 
				end
				for i,v in ipairs(plr) do
					if v then
						v:rotationx(0)
						 :rotationz(0);
					end
				end
				
				fgcurcommand = 2;
			end
		elseif fgcurcommand == 2 then
			-- Just sit tight, mostly.
			cyberMaximum = true;
			
			if overtime >= 338 then
				fgcurcommand = 3;
				cyberMaximum = false;
			end
		elseif fgcurcommand == 3 then
			if not fgcDidMyJob then
				local skyBackdrop = self:GetParent():GetChild("cyberFlight"):GetChild("sky");
				if skyBackdrop then
					skyBackdrop:visible(true);
				end
				for skyIndex = 1,cyberFlightStrips do
					local cyberSkyStrip = self:GetParent():GetChild("cyberFlight"):GetChild("skyAMV"..skyIndex);
					if cyberSkyStrip then
						cyberSkyStrip:finishtweening()
									 :queuecommand("Descent");
					end
				end
				
				fgcDidMyJob = true;
			end
			
			if overtime >= 462 then
				fgcurcommand = 4;
				fgcDidMyJob = false;
			end			
		elseif fgcurcommand == 4 then
			-- Just sit tight, mostly.
			if not fgcDidMyJob then
				for skyIndex = 1,cyberFlightStrips do
					local cyberSkyStrip = self:GetParent():GetChild("cyberFlight"):GetChild("skyAMV"..skyIndex);
					if cyberSkyStrip then
						cyberSkyStrip:stoptweening();
					end
				end
				
				fgcDidMyJob = true;
			end
			
			if overtime >= 466 then
				fgcurcommand = 5;
				fgcDidMyJob = false;
			end		
		elseif fgcurcommand == 5 then
			if not fgcDidMyJob then
				for skyIndex = 1,cyberFlightStrips do
					local cyberSkyStrip = self:GetParent():GetChild("cyberFlight"):GetChild("skyAMV"..skyIndex);
					if cyberSkyStrip then
						cyberSkyStrip:finishtweening()
									 :queuecommand("Ascent");
					end
				end
				
				fgcDidMyJob = true;
			end
			
			if overtime >= 529 then
				fgcurcommand = 6;
				fgcDidMyJob = false;
			end		
		elseif fgcurcommand == 6 then
			-- Just sit tight, mostly.
			if not fgcDidMyJob then
				local fullSky = self:GetParent():GetChild("cyberFlight");
				if fullSky then
					fullSky:decelerate(BPS)
						   :diffusealpha(0.0)
						   :visible(false)
						   :hibernate(600);
				end
				
				fgcDidMyJob = true;
			end
			
			if overtime >= 530 then
				fgcurcommand = 7;
				fgcDidMyJob = false;
			end		
		elseif fgcurcommand == 7 then
			local t = overtime - 530;
			local forceScale = 1;
			-- Exception: Beats 256 through 264 scale back the rotation to zero.
			if overtime > 662 then
				forceScale = 1 - (overtime - 662) / 1;
				forceScale = (forceScale < 0) and 0 or forceScale;
			else
				-- Exception: Beats {661.25, 660.667, 660.188, 659.75, 657.688, 657.375, 657.313, 655.563, 655.375, 655, 654} pause the rotation. 
				for _,beatPause in pairs({131.25, 130.667, 130.188, 129.75, 127.688, 127.375, 127.313, 125.563, 125.375, 125, 124}) do
					if t > beatPause then
						t = beatPause;
						break;
					end
				end
			end
			-- One rotation every 16 beats.
			local cyberRotX = math.sin(t * math.pi / 8) * (t / 4 + 10) * forceScale;
			local cyberRotZ = math.cos(t * math.pi / 8) * (t / 8 + 5)  * forceScale;
			if cyberBaby then
				cyberBaby:rotationx(cyberRotX)
						 :rotationz(cyberRotZ);					 
			end
			for i,v in ipairs(plr) do
				if v then
					v:rotationx(cyberRotX)
					 :rotationz(cyberRotZ * ((i == 1) and 1 or -1));
				end
			end
		end
		
		
		-------------------------------------------------------------------------------
		-- Cyberskin control
		--
		-- Pulse colors based on certain beat cues.
		local pulseDing		= {9.5,       25.5,     41.5,       57.5, 73.5,       89.5,     105.5,        121.5,      149.5,           213.5         };
		local pulseSamba	= {     17.5,                 49.5,             81.5,                  113.5                                             };
		local pulseSigh		= {                                                                                  133,        165, 197,        229    };
		local pulseUnsigh	= {                 32,                                     96,                                                       264};
		
		local pulseDing2	= {       539.5,             555.5,        571.5,        587.5,        603.5,        619.5,             635.5,        651.5 }; pulseDing 	= BTIUtil_ConcatTable(pulseDing, 	pulseDing2);
		local pulseSamba2	= {              547.5,                           579.5,                      611.5,                           643.5        }; pulseSamba 	= BTIUtil_ConcatTable(pulseSamba, 	pulseSamba2);
		local pulseSigh2	= {531.5,                           563.5,                      595.5,                           627.5                      }; pulseSigh 	= BTIUtil_ConcatTable(pulseSigh, 	pulseSigh2);
		local pulseUnsigh2	= {                     562,                                                                626                             }; pulseUnsigh 	= BTIUtil_ConcatTable(pulseUnsigh, 	pulseUnsigh2);
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
						
						alphaDerived = alphaDerived + CalcCyberLine( x - cyberCenterX*0.5, y - cyberCenterY,  22.5, t ) * waveFade;
						alphaDerived = alphaDerived + CalcCyberLine( x - cyberCenterX*0.5, y - cyberCenterY,  67.5, t ) * waveFade;
						alphaDerived = alphaDerived + CalcCyberLine( x - cyberCenterX*0.5, y - cyberCenterY, 112.5, t ) * waveFade;
						alphaDerived = alphaDerived + CalcCyberLine( x - cyberCenterX*0.5, y - cyberCenterY, 157.5, t ) * waveFade;
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
				
				-- Special behavior for maximum cyber phase
				-- 330: 18 27 
				-- 332: 15 18 33
				--
				-- 333: 03 18 32
				-- 334
				-- {131.25, 130.667, 130.188, 129.75, 127.688, 127.375, 127.313, 125.563, 125.375, 125, 124}
				local cyberMaxOffset = 16;
				if cyberMaximum then
					local t = (overtime - 265);
					if t > 69 then 		-- nice.
						t = t * 6;
					else
						for _,beatPause in pairs({67.688, 67.375, 67.313, 65.563, 65.375, 65, 64}) do
							if t > beatPause then
								t = beatPause;
								break;
							end
						end
					end
					if t > 48 then
						t = t + (t - 48) * (t - 48);
					end
					if overtime < 337 then
						alphaDerived = alphaDerived + math.sin((t + cyberMaxOffset) * BTIUtil_FakeRandom( x + y * cyberWidth, cyberHeight * cyberWidth )) * 0.4 + 0.5;
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
table.insert(theBoys, cyberGfxHQ);


-------------------------------------------------------------------------------
--
--		Manage arrow mods for the whole song here.
--
local cyberModsTable = {
	-- [1]: beat start
	-- [2]: mod type
	-- [3]: mod strength (out of unity),
	-- [4]: mod approach (in beats to complete)
	-- [5]: player application (1 = P1, 2 = P2, 3 = both, 0 = neither)
		
--		{ 32.0,	"Flip",			 0.5,   2.0, 3}, 
--		{ 36.0,	"Flip",			 0.0,   2.0, 3}, 
--		{ 38.0,	"Expand",		 0.5,  16.0, 3}, 
--		{ 40.0,	"Invert",		 0.5,   2.0, 3}, 
--		{ 44.0,	"Invert",		 0.0,   2.0, 3}, 
--		{ 48.0,	"Flip",			 1.0,   3.0, 3}, 
--		{ 48.0,	"Invert",		 0.5,   1.0, 3}, 
--		{ 52.0,	"Alternate",	 0.1,  32.0, 3}, 
--		{ 52.0,	"Split",		 0.2,  32.0, 3}, 
--		{ 52.0,	"Reverse",		-0.2,  32.0, 3}, 
--		{ 56.0,	"Flip",			 0.0,   1.0, 3}, 
--		{ 56.0,	"Invert",		 0.0,   3.0, 3}, 
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
--		Everybody wants to hide the Lay's.
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
			hamburger:GetChild("Overlay" ):decelerate(1.0):diffusealpha(0.0);
			hamburger:GetChild("Underlay"):decelerate(1.0):diffusealpha(0.0);
		end
		
		-- TODO: how tf to hide the combo??
		local P1 = hamburger:GetChild("PlayerP1");
		if P1 then 
			P1:GetChild("Combo"):visible(false);
		end
		local P2 = hamburger:GetChild("PlayerP2");
		if P2 then 
			P2:GetChild("Combo"):visible(false);
		end
		
		
		if P1 and P2 then
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

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
local cyberWidth = 20;
local cyberHeight = 30;
local cyberXStep = 2 * sw/cyberWidth/2;		-- Needs to be larger than half-screen to accommodate rotation
local cyberYStep = 2 * sh/cyberHeight;		-- Needs to be larger than half-screen to accommodate rotation
local cyberMinor = cyberWidth > cyberHeight and cyberHeight or cyberWidth;
local cyberMajor = cyberWidth > cyberHeight and cyberWidth or cyberHeight;
local cyberCenterX = cyberWidth/2;
local cyberCenterY = cyberHeight/2;

local cyberColorator = 1;


local cyberSkin = Def.ActorFrame {
	Name = "cyberSkin",
	InitCommand = function(self)
		self:SetWidth(sw/2 + 2)
			:SetHeight(sh + 2)
			:xy(sw/4, sh/2);
	end
};

-- Assign each "pixel" of the cyberskin its own color.
-- The available spectrum ranges from {0.0, 0.5, 0.0} to {0.0, 1.0, 0.0} to {0.0, 1.0, 0.5}.
-- To mix things up a little, the Nth pixel gets the (12^N mod 257)th color in the spectrum.
-- (If you like it, then you should have put a ring on it.)
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


-- Two copies of a half-screen texture, to save on rendering requirements.
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
local cyberFlightStrips 	= 6
local cyberFlightOptions 	= 12
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
	-- I could have skewed a plain quad with vertex coloring for this,
	-- but why do that when I've already got AMVs on call
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
				:linear(12 * BPS / cyberFlightSpeed(self:getaux()))
				:y( 2*sh)
				:queuecommand("Descent2");
		end,
		Descent2Command = function(self)
			self:y(-2*sh)
				:queuecommand("Descent");
		end,
		AscentCommand = function(self)
			local BPS = GAMESTATE:GetSongBPS();
			self:visible(true)
				:linear(12 * BPS / cyberFlightSpeed(self:getaux()))
				:y(-2*sh)
				:queuecommand("Ascent2");
		end,
		Ascent2Command = function(self)
			self:y(2*sh)
				:queuecommand("Ascent");
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

-- Turn on pixels in the cyberskin to create various time-shifting patterns.
-- CalcCyberWave: imagine the ripple front from a drop of water in a still pond
-- CalcCyberLine: pulse the pixels that overlap a single line at a given angle and offset.
-- CalcCyberStripe: pulse the pixels that overlap a grating of lines at a given angle.

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

-- this is a monolith, but it was also the first of the BTI2 specials I wrote
-- if you're looking for SM5 Lua coding examples please do not follow this file lmao
-- I rolled a proper framework for almost everything after, with Special 5 probably being the cleanest
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
									 :queuecommand("Descent2");
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
				for i,v in ipairs(plr) do
					if v then
						v:decelerate(BPS * 4)
						 :y(sh/2 + 30);
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
			local fullSky = self:GetParent():GetChild("cyberFlight");
			if not fgcDidMyJob then
				if fullSky then
					fullSky:decelerate(BPS)
						   :diffusealpha(0.0);
				end
				for i,v in ipairs(plr) do
					if v then
						v:decelerate(BPS)
						 :y(sh/2 - 30);
					end
				end
				
				fgcDidMyJob = true;
			end
			
			if overtime >= 530 then
				if fullSky then
					fullSky:visible(false)
						   :hibernate(600);
				end
				
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
				local cyberMaxOffset = 16;
				if cyberMaximum then
					local t = (overtime - 265);
					if t > 69 then 		-- nice.
						t = t * 4;
					else
						for _,beatPause in pairs({67.688, 67.375, 67.313, 65.563, 65.375, 65, 64}) do
							if t > beatPause then
								t = beatPause;
								break;
							end
						end
					end
					if t > 48 then
						t = t + (t - 48) * (t - 48) / 4;
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
local cspd = 2.0;
local cyberModsTable = {
	-- [1]: beat start
	-- [2]: mod type
	-- [3]: mod strength (out of unity),
	-- [4]: mod approach (in beats to complete)
	-- [5]: player application (1 = P1, 2 = P2, 3 = both, 0 = neither)
		
		{ 0.0,	"ScrollSpeed",	 cspd,	 0.5,	3}, 
		{ 64.0,	"Beat",			 0.5,	16.0,	3}, 
		{ 92.5,	"Beat",			 0.0,	 0.5,	3}, 
		{ 93.0,	"Drunk",		 2.0,	 0.25,	3}, 
		{ 93.5,	"Drunk",		 0.0,	 1.5,	3}, 
		{ 95.5,	"Beat",			 0.5,	 0.5,	3}, 
		{ 96.0,	"Beat",			 1.0,	16.0,	3}, 
		{124.0,	"Beat",			 0.0,	 0.5,	3}, 
		
		{128.0,	"ScrollSpeed",	 3.0,	64.0,	3}, 
		{128.0,	"Wave",			 1.0,	64.0,	3}, 
		
		{129.0,	"Invert",		-0.1,	 0.5,	3}, {129.0,	"Flip",			-0.1,	 0.5,	3}, 
		{129.5,	"Invert",		 0.1,	 0.5,	3}, {129.5,	"Flip",			 0.1,	 0.5,	3}, 
		{130.0,	"Invert",		 0.0,	 1.0,	3}, {130.0,	"Flip",			 0.0,	 1.0,	3}, 
		{131.0,	"Invert",		-0.1,	 0.5,	3}, {131.0,	"Flip",			-0.1,	 0.5,	3}, 
		{131.5,	"Invert",		 0.1,	 0.5,	3}, {131.5,	"Flip",			 0.1,	 0.5,	3}, 
		{132.0,	"Invert",		 0.0,	 1.0,	3}, {132.0,	"Flip",			 0.0,	 1.0,	3}, 
		{133.5,	"Invert",		 0.1,	 0.5,	3}, {133.5,	"Flip",			 0.1,	 0.5,	3}, 
		{134.5,	"Invert",		-0.1,	 0.5,	3}, {134.5,	"Flip",			-0.1,	 0.5,	3}, 
		{135.0,	"Invert",		 0.0,	 1.0,	3}, {135.0,	"Flip",			 0.0,	 1.0,	3}, 
		{137.0,	"Invert",		-0.1,	 0.5,	3}, {137.0,	"Flip",			-0.1,	 0.5,	3}, 
		{137.5,	"Invert",		 0.1,	 0.5,	3}, {137.5,	"Flip",			 0.1,	 0.5,	3}, 
		{138.0,	"Invert",		 0.0,	 1.0,	3}, {138.0,	"Flip",			 0.0,	 1.0,	3}, 
		
		{139.0,	"Alternate",	 0.1,	 0.5,	3}, {140.0,	"Alternate",	 0.0,	 0.5,	3}, 
		{140.0,	"Cross",		-0.1,	 1.0,	3}, {141.5,	"Cross",		 0.0,	 1.0,	3}, 
		{141.5,	"Alternate",	-0.1,	 1.0,	3}, {143.0,	"Alternate",	 0.0,	 1.0,	3},
		
		{145.0,	"Invert",		-0.1,	 0.5,	3}, {145.0,	"Flip",			-0.1,	 0.5,	3}, 
		{145.5,	"Invert",		 0.1,	 0.5,	3}, {145.5,	"Flip",			 0.1,	 0.5,	3}, 
		{146.0,	"Invert",		 0.0,	 1.0,	3}, {146.0,	"Flip",			 0.0,	 1.0,	3}, 
		{147.0,	"Invert",		-0.1,	 0.5,	3}, {147.0,	"Flip",			-0.1,	 0.5,	3}, 
		{147.5,	"Invert",		 0.1,	 0.5,	3}, {147.5,	"Flip",			 0.1,	 0.5,	3}, 
		{148.0,	"Invert",		 0.0,	 1.0,	3}, {148.0,	"Flip",			 0.0,	 1.0,	3}, 
		{149.5,	"Invert",		 0.1,	 0.5,	3}, {149.5,	"Flip",			 0.1,	 0.5,	3}, 
		{150.5,	"Invert",		-0.1,	 0.5,	3}, {150.5,	"Flip",			-0.1,	 0.5,	3}, 
		{151.0,	"Invert",		 0.0,	 1.0,	3}, {151.0,	"Flip",			 0.0,	 1.0,	3}, 
		{153.0,	"Invert",		-0.1,	 0.5,	3}, {153.0,	"Flip",			-0.1,	 0.5,	3}, 
		{153.5,	"Invert",		 0.1,	 0.5,	3}, {153.5,	"Flip",			 0.1,	 0.5,	3}, 
		{154.0,	"Invert",		 0.0,	 1.0,	3}, {154.0,	"Flip",			 0.0,	 1.0,	3}, 

		{155.0,	"Cross",		 0.1,	 1.0,	3},
		{156.0,	"Invert",		 0.2,	 1.0,	3}, {156.0,	"Flip",			 -0.2,	 1.0,	3}, 
		{157.5,	"Cross",		 0.0,	 2.5,	3}, 
		{157.5,	"Invert",		 0.0,	 2.5,	3}, {157.5,	"Flip",			 0.0,	 2.5,	3}, 
		
		{161.0,	"Invert",		 0.1,	 0.5,	3}, {161.0,	"Flip",			-0.1,	 0.5,	3}, 
		{161.5,	"Invert",		-0.1,	 0.5,	3}, {161.5,	"Flip",			 0.1,	 0.5,	3}, 
		{162.0,	"Invert",		 0.0,	 1.0,	3}, {162.0,	"Flip",			 0.0,	 1.0,	3}, 
		{163.0,	"Invert",		-0.1,	 0.5,	3}, {163.0,	"Flip",			-0.1,	 0.5,	3}, 
		{163.5,	"Invert",		 0.1,	 0.5,	3}, {163.5,	"Flip",			 0.1,	 0.5,	3}, 
		{164.0,	"Invert",		 0.0,	 1.0,	3}, {164.0,	"Flip",			 0.0,	 1.0,	3}, 
		{165.5,	"Invert",		 0.1,	 0.5,	3}, {165.5,	"Flip",			 0.1,	 0.5,	3}, 
		{166.5,	"Invert",		-0.1,	 0.5,	3}, {166.5,	"Flip",			-0.1,	 0.5,	3}, 
		{167.0,	"Invert",		 0.0,	 1.0,	3}, {167.0,	"Flip",			 0.0,	 1.0,	3}, 
		{169.0,	"Invert",		 0.1,	 0.5,	3}, {169.0,	"Flip",			-0.1,	 0.5,	3}, 
		{169.5,	"Invert",		-0.1,	 0.5,	3}, {169.5,	"Flip",			 0.1,	 0.5,	3}, 
		{170.0,	"Invert",		 0.0,	 1.0,	3}, {170.0,	"Flip",			 0.0,	 1.0,	3}, 

		{171.0,	"Split",		-0.1,	 0.5,	3}, {172.0,	"Split",		 0.0,	 0.5,	3}, 
		{172.0,	"Cross",		-0.1,	 1.0,	3}, {173.5,	"Cross",		 0.0,	 1.0,	3}, 
		{173.5,	"Split",		 0.1,	 1.0,	3}, {175.0,	"Split",		 0.0,	 1.0,	3},
		
		{176.0,	"Tiny",			-1.0,	 8.0,	3}, 
		{176.0,	"Bumpy",		 1.0,	 8.0,	3}, 
		{184.0,	"Tiny",			 0.0,	 1.0,	3}, 
		{184.0,	"Bumpy",		 0.0,	 1.0,	3}, 
				
		{188.0,	"Dark",			 1.0,	 4.0,	3}, 
		{192.0,	"Wave",			 1.2,	60.0,	3}, 
		
		{193.0,	"Invert",		 0.3,	 0.5,	3}, {193.0,	"Flip",			-0.1,	 0.5,	3}, 
		{193.5,	"Invert",		-0.3,	 0.5,	3}, {193.5,	"Flip",			 0.1,	 0.5,	3}, 
		{194.0,	"Invert",		 0.0,	 1.0,	3}, {194.0,	"Flip",			 0.0,	 1.0,	3}, 
		{195.0,	"Invert",		 0.3,	 0.5,	3}, {195.0,	"Flip",			-0.1,	 0.5,	3}, 
		{195.5,	"Invert",		-0.3,	 0.5,	3}, {195.5,	"Flip",			 0.1,	 0.5,	3}, 
		{196.0,	"Invert",		 0.0,	 1.0,	3}, {196.0,	"Flip",			 0.0,	 1.0,	3}, 
		{201.0,	"Invert",		-0.3,	 0.5,	3}, {201.0,	"Flip",			 0.1,	 0.5,	3}, 
		{201.5,	"Invert",		 0.3,	 0.5,	3}, {201.5,	"Flip",			-0.1,	 0.5,	3}, 
		{202.0,	"Invert",		 0.0,	 1.0,	3}, {202.0,	"Flip",			 0.0,	 1.0,	3}, 
		{203.0,	"Invert",		-0.3,	 0.5,	3}, {203.0,	"Flip",			 0.1,	 0.5,	3}, 
		{203.5,	"Invert",		 0.3,	 0.5,	3}, {203.5,	"Flip",			-0.1,	 0.5,	3}, 
		{204.0,	"Invert",		 0.0,	 1.0,	3}, {204.0,	"Flip",			 0.0,	 1.0,	3}, 
		
		{209.0,	"Invert",		 0.3,	 0.5,	3}, {209.0,	"Flip",			-0.1,	 0.5,	3}, 
		{209.5,	"Invert",		-0.3,	 0.5,	3}, {209.5,	"Flip",			 0.1,	 0.5,	3}, 
		{210.0,	"Invert",		 0.0,	 1.0,	3}, {210.0,	"Flip",			 0.0,	 1.0,	3}, 
		{211.0,	"Invert",		 0.3,	 0.5,	3}, {211.0,	"Flip",			-0.1,	 0.5,	3}, 
		{211.5,	"Invert",		-0.3,	 0.5,	3}, {211.5,	"Flip",			 0.1,	 0.5,	3}, 
		{212.0,	"Invert",		 0.0,	 1.0,	3}, {212.0,	"Flip",			 0.0,	 1.0,	3}, 
		{217.0,	"Invert",		-0.3,	 0.5,	3}, {217.0,	"Flip",			 0.1,	 0.5,	3}, 
		{217.5,	"Invert",		 0.3,	 0.5,	3}, {217.5,	"Flip",			-0.1,	 0.5,	3}, 
		{218.0,	"Invert",		 0.0,	 1.0,	3}, {218.0,	"Flip",			 0.0,	 1.0,	3}, 
		{219.0,	"Invert",		-0.3,	 0.5,	3}, {219.0,	"Flip",			 0.1,	 0.5,	3}, 
		{219.5,	"Invert",		 0.3,	 0.5,	3}, {219.5,	"Flip",			-0.1,	 0.5,	3}, 
		{220.0,	"Invert",		 0.0,	 1.0,	3}, {220.0,	"Flip",			 0.0,	 1.0,	3}, 
		
		{224.0,	"Invert",		 0.375,	 2.0,	3}, {224.0,	"Flip",			 0.375,	 2.0,	3}, 
		{226.0,	"Invert",		 0.0,	 2.0,	3}, {226.0,	"Flip",			 0.0,	 2.0,	3}, 
		{232.0,	"Invert",		 0.375,	 2.0,	3}, {232.0,	"Flip",			 0.375,	 2.0,	3}, 
		{234.0,	"Invert",		 0.0,	 2.0,	3}, {234.0,	"Flip",			 0.0,	 2.0,	3}, 
		{240.0,	"Invert",		 0.8,	 2.0,	3},
		{242.0,	"Invert",		 0.0,	 2.0,	3},
		{244.0,	"Invert",		 0.8,	 2.0,	3},
		{246.0,	"Invert",		 0.0,	 2.0,	3},
				
		
		{256.0,	"ScrollSpeed",	 cspd,	 8.0,	3}, 
		{256.0,	"Wave",			 0.0,	 8.0,	3}, 
		{260.0,	"Dark",			 0.0,	 4.0,	3}, 
		
		{265.0,	"Tipsy",		 0.5,	 0.01,	3}, 
		{265.0,	"Dizzy",		 0.5,	 0.01,	3}, 
		{265.0,	"Brake",		 0.2,	 0.01,	3}, 		
		
		{266.0,	"Tipsy",		 1.0,	47.0,	3}, 
		{266.0,	"Brake",		 1.5,	63.0,	3}, 
		
		-- Dizzy is a fuckall useless mod when applied vanilla		
		{266.0,	"Dizzy",		-1.0,	 6.0,	3}, 
		{274.0,	"Dizzy",		 1.5,	 6.0,	3}, 
		{282.0,	"Dizzy",		-2.0,	 6.0,	3}, 
		{290.0,	"Dizzy",		 2.5,	 6.0,	3}, 
		{298.0,	"Dizzy",		-3.0,	 6.0,	3}, 
		{306.0,	"Dizzy",		 3.5,	 6.0,	3}, 
		{313.0,	"Dizzy",		 0.0,	16.0,	3}, 
		
		{329.0,	"Brake",		 0.0,	 8.0,	3}, 
		{337.0,	"Tipsy",		 0.0,	 0.01,	3}, 
		
		-- Air phase
		{370.0,	"Stealth",		 0.5,	 2.0,	3}, {370.0,	"Dark",			 1.0,	 2.0,	3}, 
		{370.0,	"Flip",			 1.0,	 2.0,	3}, {370.0,	"Invert",		-1.0,	 2.0,	3}, 
		{372.0,	"Stealth",		 0.0,	 2.0,	3}, {372.0,	"Dark",			 0.0,	 2.0,	3}, 
		{374.0,	"Stealth",		 0.5,	 2.0,	3}, {374.0,	"Dark",			 1.0,	 2.0,	3}, 
		{374.0,	"Flip",			 0.0,	 2.0,	3}, {374.0,	"Invert",		 0.0,	 2.0,	3}, 
		{376.0,	"Stealth",		 0.0,	 2.0,	3}, {376.0,	"Dark",			 0.0,	 2.0,	3}, 
		{378.0,	"Stealth",		 0.5,	 2.0,	3}, {378.0,	"Dark",			 1.0,	 2.0,	3}, 
		{378.0,	"Flip",			 1.0,	 2.0,	3}, {378.0,	"Invert",		-1.0,	 2.0,	3}, 
		{380.0,	"Stealth",		 0.0,	 2.0,	3}, {380.0,	"Dark",			 0.0,	 2.0,	3}, 
		{382.0,	"Stealth",		 0.5,	 2.0,	3}, {382.0,	"Dark",			 1.0,	 2.0,	3}, 
		{382.0,	"Flip",			 0.0,	 2.0,	3}, {382.0,	"Invert",		 0.0,	 2.0,	3}, 
		{384.0,	"Stealth",		 0.0,	 2.0,	3}, --{384.0,	"Dark",			 0.0,	 2.0,	3}, 
		
		{386.0,	"Flip",			 0.5,	 0.75,	3}, {386.0,	"Invert",		-0.5,	 0.75,	3},  
		{386.0, "Tornado",		 0.5,	 0.05,	3}, {386.0, "Tipsy",		-2.0,	 0.05,	3},
		{386.75,"Flip",			 0.0,	 0.75,	3}, {386.75,"Invert",		 0.0,	 0.75,	3}, 
		{386.75,"Tornado",		 0.0,	 0.75,	3}, {386.75,"Tipsy",		 0.0,	 0.75,	3},
		{388.0,	"Flip",			 0.0,	 0.75,	3}, {388.0,	"Invert",		 0.5,	 0.75,	3}, 
		{388.0, "Tornado",		 0.5,	 0.05,	3}, {388.0, "Tipsy",		-2.0,	 0.05,	3},
		{388.75,"Flip",			 0.0,	 0.75,	3}, {388.75,"Invert",		 0.0,	 0.75,	3}, 
		{388.75,"Tornado",		 0.0,	 0.75,	3}, {388.75,"Tipsy",		 0.0,	 0.75,	3},
		{390.0,	"Flip",			 0.5,	 0.75,	3}, {390.0,	"Invert",		-0.5,	 0.75,	3}, 
		{390.0, "Tornado",		-0.5,	 0.05,	3}, {390.0, "Tipsy",		 2.0,	 0.05,	3},
		{390.75,"Flip",			 0.0,	 0.75,	3}, {390.75,"Invert",		 0.0,	 0.75,	3}, 
		{390.75,"Tornado",		 0.0,	 0.75,	3}, {390.75,"Tipsy",		 0.0,	 0.75,	3},
		{392.0,	"Flip",			 0.0,	 0.75,	3}, {392.0,	"Invert",		 0.5,	 0.75,	3}, 
		{392.0, "Tornado",		-0.5,	 0.05,	3}, {392.0, "Tipsy",		 2.0,	 0.05,	3},
		{392.75,"Flip",			 0.0,	 0.75,	3}, {392.75,"Invert",		 0.0,	 0.75,	3}, 
		{392.75,"Tornado",		 0.0,	 0.75,	3}, {392.75,"Tipsy",		 0.0,	 0.75,	3},
		{394.0,	"Flip",			 0.5,	 4.0,	3}, {394.0,	"Invert",		 0.0,	 4.0,	3}, 
		{398.0,	"Flip",			 0.0,	 4.0,	3}, 
		{398.0,	"Dark",			 0.0,	 4.0,	3}, 
				
		{398.0,	"Hidden",		 0.7,	 4.0,	3}, 
		{398.0,	"Sudden",		 0.7,	 4.0,	3}, 
		{398.0,	"HiddenOffset",	-1.0,	 0.01,	3}, 
		{398.0,	"SuddenOffset",	-0.5,	 0.01,	3}, 
		{402.0,	"HiddenOffset",	 0.8,	60.0,	3}, 
		{402.0,	"SuddenOffset",	 1.0,	60.0,	3}, 
				
--		{402.0,	"ScrollSpeed",	 cspd * 0.6,	4.0,	3}, 
--		{402.0,	"Boost",		 1.2,	4.0,	3}, 
		
		{460.0,	"Hidden",		 0.0,	 2.0,	3}, 
		{460.0,	"Sudden",		 0.0,	 2.0,	3}, 
		{462.0,	"HiddenOffset",	-1.0,	 2.0,	3}, 
		{462.0,	"SuddenOffset",	-0.5,	 2.0,	3}, 
		{462.0,	"Reverse",		 1.0,	 3.5,	3}, 				
		{466.0,	"Hidden",		 0.7,	 4.0,	3}, 
		{466.0,	"Sudden",		 0.7,	 4.0,	3}, 
		{466.0,	"HiddenOffset",	 0.8,	64.0,	3}, 
		{466.0,	"SuddenOffset",	 1.0,	64.0,	3}, 
						
		{522.0,	"Hidden",		 0.0,	 4.0,	3}, 
		{522.0,	"Sudden",		 0.0,	 4.0,	3}, 
		{522.0,	"HiddenOffset",	 0.0,	 4.0,	3}, 
		{522.0,	"SuddenOffset",	 0.0,	 4.0,	3}, 
		{526.0,	"Reverse",		 0.8,	 0.01,	3}, 
		{526.0,	"Centered",		 0.3,	 0.01,	3}, 
		{526.75,"Reverse",		 0.6,	 0.01,	3}, 
		{526.75,"Centered",		 0.7,	 0.01,	3}, 
		{527.5,	"Reverse",		 0.4,	 0.01,	3}, 
		{527.5,	"Centered",		 1.0,	 0.01,	3}, 
		{528.25,"Reverse",		 0.2,	 0.01,	3}, 
		{528.25,"Centered",		 0.7,	 0.01,	3}, 
		{529.0,	"Reverse",		 0.0,	 0.01,	3}, 
		{529.0,	"Centered",		 0.3,	 0.01,	3}, 
--		{529.0,	"ScrollSpeed",	 cspd,	 1.0,	3}, 
--		{529.0,	"Boost",		 0.0,	 1.0,	3}, 
		{529.05,"Centered",		 0.0,	 5.0,	3}, 
		
		
		{529.5,	"Beat",			 1.0,	 0.5,	3}, 
		{530.0,	"Beat",			 0.5,	32.0,	3}, 
		{558.5,	"Beat",			 0.0,	 0.5,	3}, 
		{559.0,	"Drunk",		-2.0,	 0.25,	3}, 
		{559.5,	"Drunk",		 0.0,	 1.5,	3}, 
		{561.5,	"Beat",			 0.5,	 0.5,	3}, 
		{562.0,	"Beat",			 0.0,	32.0,	3}, 
				
		{590.0,	"Tiny",			-1.0,	 2.0,	3}, {590.0,	"Flip",			0.5,	 2.0,	3}, 
		{592.5,	"Tiny",			 1.0,	 0.25,	3},
		{592.75,"Tiny",			 0.0,	 0.25,	3}, {593.0,	"Flip",			0.0,	 1.0,	3}, 
				
		{623.0,	"Drunk",		-2.0,	 0.25,	3}, 
		{623.5,	"Drunk",		 0.0,	 1.5,	3}, 
};
local cyberModsLaunched = 0;
local cyberModsWait = 0;
local cyberModsLeadBy = 0.03;

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
			Trace("In clearAllMods: P"..playerNum.." has mod "..modName.." set to "..tostring(currValue));
			
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
		
		if cyberModsLaunched >= #cyberModsTable then
			Trace('>>> modsHQ: Hibernated!!');
			self:hibernate(600);
			do return end
		else
			while cyberModsLaunched < #cyberModsTable do
				-- Trace('>>> modsHQ: ' .. cyberModsLaunched);
				-- Check the next line of the mods table.
				cyberNextMod = cyberModsTable[cyberModsLaunched + 1];
				
				if overtime + cyberModsLeadBy >= cyberNextMod[1] then
					-- TODO: this assumes the effect applies over a constant BPM section!!
					local cyberBPS = GAMESTATE:GetSongBPS();
					Trace('>>> modsHQ: ' .. cyberModsLaunched .. ' @ time = ' .. overtime);
					
					for _,pe in pairs(GAMESTATE:GetEnabledPlayers()) do
						pn = tonumber(string.match(pe, "[0-9]+"));
						if (cyberNextMod[5] == pn or cyberNextMod[5] == 3) then
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
							Trace('>>> modsHQ: ' .. opVal .. ' @ rate = ' .. opApproach .. ' for ' .. pe);
							Trace('>>> modsHQ: ' .. cyberNextMod[3] .. ' @ rate = ' .. newApproach .. ' for ' .. pe .. ' [New!]');
						end
					end
					
					cyberModsLaunched = cyberModsLaunched + 1;
				else
					-- Trace('>>> modsHQ: ' .. overtime .. ' < ' .. cyberNextMod[1]);
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

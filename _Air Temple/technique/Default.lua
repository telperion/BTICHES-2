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


local cyberWidth = 20;
local cyberHeight = 30;
local cyberXStep = 2 * sw/cyberWidth/2;		-- Needs to be larger than half-screen to accommodate rotation
local cyberYStep = 2 * sh/cyberHeight;		-- Needs to be larger than half-screen to accommodate rotation



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
for cyberCol = 0,cyberWidth-1 do
	for cyberRow = 0,cyberHeight-1 do
		table.insert(cyberSkin,
			Def.Quad {
				Name = "cyberSkin_"..cyberCol.."_"..cyberRow,
				InitCommand = function(self)
					self:zoomto(cyberXStep, cyberYStep)
						:xy((cyberCol + 0.5 - cyberWidth*0.5) * cyberXStep, (cyberRow + 0.5 - cyberHeight*0.5) * cyberYStep)
						:diffuse( color("1.0,"..(cyberCol / cyberWidth)..","..(cyberRow / cyberHeight)..",0.0") );
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


-- This is where the shit will be happening.
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

-- Find the radial distance in cyberskin patches from the center.
local CalcCyberRadialPos = function(x, y)
	xi = (x - cyberWidth*0.5 + 0.5);
	yi = (y - cyberHeight*0.5 + 0.5);
	return math.sqrt(xi*xi + yi*yi);
end


local cyberHQ = Def.Quad {
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
		local pulseDing		= {8, 32, 64, 65, 68};
		local pulseSigh		= {};
		local pulseSamba	= {};
		local waveFadeoff	= 8.0;		-- Fade out the wave after this many beats
		local waveCutoff	= 12.0;		-- Cut off the wave after this many beats
		
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
						alphaDerived = alphaDerived > 1 and 1 or alphaDerived;
					end
				end
				
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
table.insert(theBoys, cyberHQ);

return theBoys;
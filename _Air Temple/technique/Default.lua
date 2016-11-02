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


local cyberWidth = 12;
local cyberHeight = 18;
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

local cyberSkinTexName = "cyberSkinTex";
local cyberTexSet = {false, false};
cyberSkinTex = Def.ActorFrameTexture {
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
		self:queuecommand("Update");
	end,
	UpdateCommand = function(self)		
		if self:GetTexture() then
			cyberSkinP1 = self:GetParent():GetChild("cyberSkinP1");
			cyberSkinP2 = self:GetParent():GetChild("cyberSkinP2");
			if cyberSkinP1 and not cyberTexSet[1] then
				cyberSkinP1:SetTexture( self:GetTexture() );
				cyberTexSet[1] = true;
			end
			if cyberSkinP2 and not cyberTexSet[2] then
				cyberSkinP2:SetTexture( self:GetTexture() );
				cyberTexSet[2] = true;
			end
		end
		
		-- One rotation every 16 beats.
		cyberParameter = GAMESTATE:GetSongBeat();
		local cyberRotX = math.sin(cyberParameter * math.pi / 8) * (cyberParameter / 12 + 10);
		local cyberRotZ = math.cos(cyberParameter * math.pi / 8) * (cyberParameter / 24 + 5);
		local cyberBaby = self:GetChild("cyberSkin");
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
		
		self:queuecommand("WaitABit");
	end,
	WaitABitCommand = function(self)
		self:sleep(0.02);
		self:queuecommand("Update");
	end
};

local cyberParameter = 0;
cyberSkin = Def.ActorFrame {
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
						:diffuse( color("0.5,"..(cyberCol / cyberWidth)..","..(cyberRow / cyberHeight)..",0.8") );
					Trace("Initialized cyberskin element: ("..cyberCol..", "..cyberRow..")");
				end,
				OnCommand = function(self)
				end				
			}
		);
	end
end
table.insert(cyberSkinTex, cyberSkin);
table.insert(theBoys, cyberSkinTex);

cyberSkinP1 = Def.Sprite {
	Name = "cyberSkinP1",
	InitCommand = function(self)
		self:xy(  sw/4, sh/2);
		Trace("Drawn cyberskin for P1");
	end
};
cyberSkinP2 = Def.Sprite {
	Name = "cyberSkinP2",
	InitCommand = function(self)
		self:zoomx(-1)
			:xy(3*sw/4, sh/2);
		Trace("Drawn cyberskin for P2");
	end
};
table.insert(theBoys, cyberSkinP1);
table.insert(theBoys, cyberSkinP2);

return theBoys;
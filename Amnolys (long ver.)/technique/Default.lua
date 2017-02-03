-------------------------------------------------------------------------------
--
--		Special Content to Exercise the Player's Firebending Technique
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

local cspd = 3.0;						-- Preferred scroll speed for most of the chart.
local cspdA = 1.8;						-- Scroll speed for the column staggering section.

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
--		Weak sunset.
--

-- In terms of sw (x) and sh (y).
-- First coordinate is center (xc, yc), second is size (width, height).
local felysSunsetQuadsLight = {			
	{{0.5,  0.5},  {1.3,  1.3}},		-- sky
	{{0.61, 0.72}, {0.23, 0.2}},		-- sun (horizontal)
	{{0.61, 0.72}, {0.15, 0.3}},		-- sun (vertical)
	{{0.34, 0.65}, {0.25, 0.06}},		-- left cloud
	{{0.78, 0.56}, {0.25, 0.06}},		-- right cloud
	{{0.08, 0.75}, {0.34, 0.23}},		-- left squat hill
	{{0.08, 0.75}, {0.17, 0.45}},		-- left tall hill
	{{0.92, 0.8},  {0.34, 0.23}},		-- right squat hill
	{{0.92, 0.8},  {0.17, 0.45}},		-- right tall hill
	{{0.5,  0.9},  {1.3,  0.3}},		-- ground
};

local felysSunsetQuadsDark = {	
	{{0.5,  0.5},  {1.3,  1.3}},		-- sky
	{{0.61, 1.05}, {0.28, 0.2}},		-- sun (horizontal)
	{{0.61, 1.05}, {0.18, 0.3}},		-- sun (vertical)
	{{0.34, 0.62}, {0.25, 0.06}},		-- left cloud
	{{0.78, 0.56}, {0.25, 0.06}},		-- right cloud
	{{0.08, 0.75}, {0.34, 0.31}},		-- left squat hill
	{{0.08, 0.75}, {0.23, 0.45}},		-- left tall hill
	{{0.92, 0.8},  {0.34, 0.31}},		-- right squat hill
	{{0.92, 0.8},  {0.23, 0.45}},		-- right tall hill
	{{0.5,  0.9},  {1.3,  0.3}},		-- ground
};

local felysSunsetQuadsAngry = {			
	{{0.5,  0.5},  {1.3,  1.3}},		-- sky
	{{0.61, 0.72}, {0.23, 0.2}},		-- sun (horizontal)
	{{0.61, 0.72}, {0.15, 0.3}},		-- sun (vertical)
	{{0.34, 0.65}, {0.25, 0.06}},		-- left cloud
	{{0.78, 0.56}, {0.25, 0.06}},		-- right cloud
	{{0.08, 0.75}, {0.34, 0.23}},		-- left squat hill
	{{0.08, 0.75}, {0.17, 0.45}},		-- left tall hill
	{{0.92, 0.8},  {0.34, 0.23}},		-- right squat hill
	{{0.92, 0.8},  {0.17, 0.45}},		-- right tall hill
	{{0.5,  0.9},  {1.3,  0.3}},		-- ground
};

local felysSunsetQuadsFree = {			
	{{0.5,  0.5},  {1.3,  1.3}},		-- sky
	{{0.61, 0.72}, {0.23, 0.2}},		-- sun (horizontal)
	{{0.61, 0.72}, {0.15, 0.3}},		-- sun (vertical)
	{{0.34, 0.65}, {0.25, 0.06}},		-- left cloud
	{{0.78, 0.56}, {0.25, 0.06}},		-- right cloud
	{{0.08, 0.75}, {0.34, 0.23}},		-- left squat hill
	{{0.08, 0.75}, {0.17, 0.45}},		-- left tall hill
	{{0.92, 0.8},  {0.34, 0.23}},		-- right squat hill
	{{0.92, 0.8},  {0.17, 0.45}},		-- right tall hill
	{{0.5,  0.9},  {1.3,  0.3}},		-- ground
};

-- {R, G, B, A}
-- {LT, RT, RB, LB}
local felysSunsetColorsLight = {			
	{	{0.0, 0.0, 0.0, 0.3},
		{0.0, 0.0, 0.0, 0.3},
		{0.4, 0.3, 0.3, 1.0},
		{0.4, 0.3, 0.3, 1.0}	},		-- sky
	{	{0.8, 0.7, 0.0, 1.0},
		{0.8, 0.7, 0.0, 1.0},
		{0.8, 0.5, 0.0, 1.0},
		{0.8, 0.5, 0.0, 1.0}	},		-- sun (horizontal)
	{	{0.8, 0.75, 0.0, 1.0},
		{0.8, 0.75, 0.0, 1.0},
		{0.8, 0.45, 0.0, 1.0},
		{0.8, 0.45, 0.0, 1.0}	},		-- sun (vertical)
	{	{1.0, 0.3, 0.0, 0.2},
		{1.0, 0.3, 0.0, 0.2},
		{1.0, 0.0, 0.0, 0.5},
		{1.0, 0.0, 0.0, 0.5}	},		-- left cloud
	{	{1.0, 0.3, 0.0, 0.2},
		{1.0, 0.3, 0.0, 0.2},
		{1.0, 0.0, 0.0, 0.5},
		{1.0, 0.0, 0.0, 0.5}	},		-- right cloud
	{	{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 0.7},
		{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0}	},		-- left squat hill
	{	{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 0.7},
		{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0}	},		-- left tall hill
	{	{0.0, 0.0, 0.0, 0.7},
		{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0}	},		-- right squat hill
	{	{0.0, 0.0, 0.0, 0.7},
		{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0}	},		-- right tall hill
	{	{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0}	},		-- ground
};

-- {R, G, B, A}
-- {LT, RT, RB, LB}
local felysSunsetColorsDark = {			
	{	{0.0, 0.0, 0.0, 0.3},
		{0.0, 0.0, 0.0, 0.3},
		{0.2, 0.1, 0.1, 0.5},
		{0.2, 0.1, 0.1, 0.5}	},		-- sky
	{	{0.8, 0.3, 0.0, 1.0},
		{0.8, 0.3, 0.0, 1.0},
		{0.8, 0.1, 0.0, 1.0},
		{0.8, 0.1, 0.0, 1.0}	},		-- sun (horizontal)
	{	{0.8, 0.35, 0.0, 1.0},
		{0.8, 0.35, 0.0, 1.0},
		{0.8, 0.05, 0.0, 1.0},
		{0.8, 0.05, 0.0, 1.0}	},		-- sun (vertical)
	{	{0.7, 0.3, 0.3, 0.1},
		{0.7, 0.3, 0.3, 0.1},
		{1.0, 0.0, 0.0, 0.2},
		{1.0, 0.0, 0.0, 0.2}	},		-- left cloud
	{	{0.7, 0.3, 0.3, 0.1},
		{0.7, 0.3, 0.3, 0.1},
		{1.0, 0.0, 0.0, 0.2},
		{1.0, 0.0, 0.0, 0.2}	},		-- right cloud
	{	{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0}	},		-- left squat hill
	{	{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0}	},		-- left tall hill
	{	{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0}	},		-- right squat hill
	{	{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0}	},		-- right tall hill
	{	{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0}	},		-- ground
};

local felysSunsetColorsAngry = {			
	{	{0.0, 0.0, 0.0, 0.3},
		{0.0, 0.0, 0.0, 0.3},
		{0.4, 0.3, 0.3, 1.0},
		{0.4, 0.3, 0.3, 1.0}	},		-- sky
	{	{0.8, 0.0, 0.5, 1.0},
		{0.8, 0.0, 0.5, 1.0},
		{0.8, 0.0, 0.2, 1.0},
		{0.8, 0.0, 0.2, 1.0}	},		-- sun (horizontal)
	{	{0.8, 0.0, 0.55, 1.0},
		{0.8, 0.0, 0.55, 1.0},
		{0.8, 0.0, 0.15, 1.0},
		{0.8, 0.0, 0.15, 1.0}	},		-- sun (vertical)
	{	{1.0, 0.3, 0.0, 0.2},
		{1.0, 0.3, 0.0, 0.2},
		{1.0, 0.0, 0.3, 0.5},
		{1.0, 0.0, 0.0, 0.5}	},		-- left cloud
	{	{1.0, 0.3, 0.0, 0.2},
		{1.0, 0.3, 0.0, 0.2},
		{1.0, 0.0, 0.0, 0.5},
		{1.0, 0.0, 0.3, 0.5}	},		-- right cloud
	{	{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 0.7},
		{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0}	},		-- left squat hill
	{	{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 0.7},
		{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0}	},		-- left tall hill
	{	{0.0, 0.0, 0.0, 0.7},
		{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0}	},		-- right squat hill
	{	{0.0, 0.0, 0.0, 0.7},
		{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0}	},		-- right tall hill
	{	{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0}	},		-- ground
};

local felysSunsetColorsFree = {			
	{	{0.0, 0.3, 1.0, 1.0},
		{0.0, 0.3, 1.0, 1.0},
		{0.4, 0.8, 1.0, 1.0},
		{0.4, 0.8, 1.0, 1.0}	},		-- sky
	{	{1.0, 0.7, 0.0, 1.0},
		{1.0, 0.7, 0.0, 1.0},
		{1.0, 0.5, 0.0, 1.0},
		{1.0, 0.5, 0.0, 1.0}	},		-- sun (horizontal)
	{	{1.0, 0.75, 0.0, 1.0},
		{1.0, 0.75, 0.0, 1.0},
		{1.0, 0.45, 0.0, 1.0},
		{1.0, 0.45, 0.0, 1.0}	},		-- sun (vertical)
	{	{0.7, 0.7, 0.7, 0.8},
		{0.7, 0.7, 0.7, 0.8},
		{1.0, 1.0, 1.0, 0.5},
		{1.0, 1.0, 0.8, 0.5}	},		-- left cloud
	{	{0.7, 0.7, 0.7, 0.8},
		{0.7, 0.7, 0.7, 0.8},
		{1.0, 1.0, 0.8, 0.5},
		{1.0, 1.0, 1.0, 0.5}	},		-- right cloud
	{	{0.0, 0.4, 0.0, 1.0},
		{0.0, 0.4, 0.0, 0.7},
		{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0}	},		-- left squat hill
	{	{0.0, 0.6, 0.0, 1.0},
		{0.0, 0.6, 0.0, 0.7},
		{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0}	},		-- left tall hill
	{	{0.0, 0.4, 0.0, 0.7},
		{0.0, 0.4, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0}	},		-- right squat hill
	{	{0.0, 0.6, 0.0, 0.7},
		{0.0, 0.6, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0}	},		-- right tall hill
	{	{0.0, 0.2, 0.0, 1.0},
		{0.0, 0.2, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0},
		{0.0, 0.0, 0.0, 1.0}	},		-- ground
};

local felysConstructVertices = function(brightness, disturbance)
	local srcQuads  = nil;
	local srcColors = nil;
	if brightness > 2.5 then
		srcQuads  = felysSunsetQuadsFree;
		srcColors = felysSunsetColorsFree;
	elseif brightness > 1.5 then
		srcQuads  = felysSunsetQuadsAngry;
		srcColors = felysSunsetColorsAngry;
	elseif brightness > 0.5 then
		srcQuads  = felysSunsetQuadsLight;
		srcColors = felysSunsetColorsLight;
	else 
		srcQuads  = felysSunsetQuadsDark;
		srcColors = felysSunsetColorsDark;
	end
	local verts = {};
	
	for i = 1,#srcQuads do
		if not disturbance then
			disturbThisX = 1;
			disturbThisY = 1;
		else
			Trace("Disturbance "..i..": "..disturbance[i]);
			disturbThisX = 1 - disturbance[i]*0.2;
			disturbThisY = 1 + disturbance[i]*0.2;
		end
		local ctsz = srcQuads[i];
		
		for corner = 1,4 do
			local xsign = (corner == 2 or corner == 3) and 1 or -1;
			local ysign = (corner == 3 or corner == 4) and 1 or -1;
			local pos = {(ctsz[1][1] + disturbThisX*xsign*ctsz[2][1]/2) * sw, (ctsz[1][2] + disturbThisY*ysign*ctsz[2][2]/2) * sh, 0}
			local col = srcColors[i][corner];
			verts[#verts + 1] = {pos, col};		
			
--			Trace("## ["..i.."][1] = {"..verts[i][1][1]..", "..verts[i][1][2]..", "..verts[i][1][3].."}!");
--			Trace("## ["..i.."][2] = {"..verts[i][2][1]..", "..verts[i][2][2]..", "..verts[i][2][3]..", "..verts[i][2][4].."}!");

		end
	end
	
	return verts
end

local felysBG = Def.ActorMultiVertex {
	Name = "felysBG",
	InitCommand = function(self)
		local verts = felysConstructVertices(1, nil);
		self:aux(1)
			:xy(0, 0)
			:draworder(-100)
			:SetVertices(verts)
			:SetDrawState{Mode = "DrawMode_Quads", First = 1, Num = -1}
			:visible(true);
	end,
	MorphCommand = function(self)
		Trace("Morphing!");
		local BPS = GAMESTATE:GetSongBPS();	
		local randos = {};
		for i = 1,#felysSunsetQuadsLight do
			randos[#randos + 1] = math.random() - 0.5;
		end
		local verts = felysConstructVertices(self:getaux(), randos);
		self:decelerate(4.0 / BPS)
			:SetVertices(verts)
			:queuecommand("Morph");
	end,
	FastMorphCommand = function(self)
		Trace("Quickly Morphing!");
		local BPS = GAMESTATE:GetSongBPS();	
		local randos = {};
		for i = 1,#felysSunsetQuadsLight do
			randos[#randos + 1] = math.random() - 0.5;
		end
		local verts = felysConstructVertices(self:getaux(), randos);
		self:decelerate(2.0 / BPS)
			:SetVertices(verts)
			:queuecommand("Morph");
	end,
	DimCommand = function(self)
		Trace("Dimming!");
		local BPS = GAMESTATE:GetSongBPS();	
		local verts = felysConstructVertices(0, nil);
		self:aux(0)
			:smooth(32.0 / BPS)
			:SetVertices(verts);
	end,
	BrightCommand = function(self)
		Trace("Brightening!");
		local BPS = GAMESTATE:GetSongBPS();	
		local verts = felysConstructVertices(1, nil);
		self:aux(1)
			:smooth(64.0 / BPS)
			:SetVertices(verts);
	end,
	AngerCommand = function(self)
		Trace("Angering!");
		local BPS = GAMESTATE:GetSongBPS();	
		local verts = felysConstructVertices(2, nil);
		self:aux(2)
			:smooth(80.0 / BPS)
			:SetVertices(verts);
	end,
	FreeCommand = function(self)
		Trace("Flying!");
		local BPS = GAMESTATE:GetSongBPS();	
		local verts = felysConstructVertices(3, nil);
		self:aux(3)
			:accelerate(16.0 / BPS)
			:SetVertices(verts);
	end,
	FastAngerCommand = function(self)
		Trace("Quick to Angering!");
		local BPS = GAMESTATE:GetSongBPS();	
		local verts = felysConstructVertices(2, nil);
		self:aux(2)
			:accelerate(32.0 / BPS)
			:SetVertices(verts);
	end,
}
--felysBG = Def.ActorFrame{};	-- DEBUG ONLY
table.insert(theBoys, felysBG);

local felysOL = Def.Quad {
	Name = "felysOL",
	InitCommand = function(self)
		local verts = felysConstructVertices(1, nil);
		self:SetWidth(sw)
			:SetHeight(sh)
			:Center()
			:draworder(100)
			:diffuse(1.0, 1.0, 1.0, 1.0)
			:blend("BlendMode_Modulate")
			:visible(true);
	end,
	BassCommand = function(self)
		local BPS = GAMESTATE:GetSongBPS();	
		self:decelerate(1.0/BPS)
			:diffuse(1.0, 0.5, 0.5, 1.0)
			:accelerate(1.0/BPS)
			:diffuse(1.0, 1.0, 1.0, 1.0)
			:sleep(2.0/BPS)
			:queuecommand("Bass");
	end
}
table.insert(theBoys, felysOL);

--
--		Proxy up the players.
--
local DefaultProxyP1 = Def.ActorProxy {					
	Name = "DefaultProxyP1",
	BeginCommand=function(self)
		local p = SCREENMAN:GetTopScreen():GetChild('PlayerP1');
		if p then self:SetTarget(p); else self:hibernate(1573); end
	end,
	OnCommand=function(self)
		self:xy(0, 0);
	end
}
table.insert(theBoys, DefaultProxyP1);

local DefaultProxyP2 = Def.ActorProxy {					
	Name = "DefaultProxyP2",
	BeginCommand=function(self)
		local p = SCREENMAN:GetTopScreen():GetChild('PlayerP2');
		if p then self:SetTarget(p); else self:hibernate(1573); end
	end,
	OnCommand=function(self)
		self:xy(0, 0);
	end
}
table.insert(theBoys, DefaultProxyP2);


-------------------------------------------------------------------------------
--
-- 		Judgment proxies
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

-------------------------------------------------------------------------------
--
--		Some ghosting!
--
local ghostColors = {{1.0, 0.5, 0.0, 1.0},
					 {1.0, 0.0, 0.0, 1.0},
					 {1.0, 0.0, 0.5, 1.0}};
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
							:diffuse({1,1,1,0.98})
							:visible(true);
					end,
					StopTrailMessageCommand=function(self)
						self:diffuse({1,1,1,0.0});
					end,
					StartTrailMessageCommand=function(self)
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

-------------------------------------------------------------------------------
--
-- 		This is where the shit will be happening.
--
local BTIUtil_Scale = function(t, inLower, inUpper, outLower, outUpper)
	local ti = (t - inLower) / (inUpper - inLower);
	return outLower + ti * (outUpper - outLower);
end

local felysStaggerColumnsA = {
	-- {beat-1, column staggering}
	-- Columns tween in one beat before the first notes hit.
	-- First and second stay together on +0, third is +0.75, fourth is +1.5
	{224, {1, 2, 4, 3}},
	{228, {2, 4, 1, 3}},
	{232, {1, 3, 2, 4}},
	{236, {2, 4, 3, 1}},
	{240, {2, 3, 4, 1}},
	{244, {3, 4, 1, 2}},
	{248, {1, 3, 4, 2}},
	{252, {2, 3, 4, 1}},
	{256, {1, 2, 3, 4}},
	{260, {3, 4, 1, 2}},
	{264, {2, 4, 3, 1}},
	{268, {1, 3, 4, 2}},
	{272, {2, 3, 1, 4}},
	{276, {1, 2, 4, 3}},
	{280, {2, 3, 1, 4}},
	{284, {2, 4, 1, 3}},	
};
local felysStaggerLead = 1.0;
local felysStaggerBeats = {0, 0, 0.75, 1.5};
local felysStaggerIndex = 0;


local felysRotationA = {
	-- {beat-1, player rotation}
	-- Playfields rotate almost immediately on beat.
	-- First rotation for P1, second for P2.
	-- Individual elements as x,y,z - all degrees.
	{416, {{0,  10, -10}, {0,   0,  -5}}},
	{420, {{0,   0,   5}, {0, -10,  10}}},
	{424, {{0,  10, -10}, {0,   0,  -5}}},
	{428, {{0, -10,   0}, {0,  10,   0}}},
	{429, {{0, -15, -10}, {0,  15,  10}}},
	
	{432, {{0,   0,   5}, {0, -10,  10}}},
	{436, {{0,  10, -10}, {0,   0,  -5}}},
	{440, {{0,   0,   5}, {0, -10,  10}}},
	{444, {{0, -10,   0}, {0,  10,   0}}},
	{445, {{0, -15, -10}, {0,  15,  10}}},
	
	{448, {{0,  15, -10}, {0,   0,  -5}}},
	{452, {{0,   0,   5}, {0, -15,  10}}},
	{456, {{0,  15, -10}, {0,   0,  -5}}},
	{460, {{0, -15,   0}, {0,  15,   0}}},
	{461, {{0, -20, -10}, {0,  20,  10}}},
	
	{464, {{0,   0,   5}, {0, -15,  10}}},
	{468, {{0,  15, -10}, {0,   0,  -5}}},
	{472, {{0,   0,   5}, {0, -15,  10}}},
	{476, {{0, -15,   0}, {0,  15,   0}}},
	-- no 477	
	
	{480, {{0,  20, -10}, {0,   0,  -5}}},
	{484, {{0,   0,   5}, {0, -20,  10}}},
	{488, {{0,  20, -10}, {0,   0,  -5}}},
	{492, {{0, -20,   0}, {0,  20,   0}}},
	{493, {{0, -25, -10}, {0,  25,  10}}},
	
	{496, {{0,   0,   5}, {0, -25,  10}}},
	{500, {{0,  25, -10}, {0,   0,  -5}}},
	{504, {{0,   0,   5}, {0, -25,  10}}},
	{508, {{0, -25,   0}, {0,  25,   0}}},
	{509, {{0, -30, -10}, {0,  30,  10}}},	
	
	{512, {{0,  30, -10}, {0,   0,  -5}}},
	{516, {{0,   0,   5}, {0, -30,  10}}},
	{520, {{0,  30, -10}, {0,   0,  -5}}},
	{524, {{0, -30,   0}, {0,  30,   0}}},
	{525, {{0, -45, -10}, {0,  45,  10}}},
};
local felysRotationLead = 0.25;
local felysRotationIndex = 0;


local felysGfxHQ = Def.Quad {
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
			-- Hide the actual playfields. Let the proxies do the work.
			for i,v in ipairs(plr) do
				if v then
					v:visible(true)
					 :decelerate(16.0 / BPS)
					 :y(sh/2 - 30)
					 :z(0);
				end
				
				for ghostIndex = 1,#ghostColors do
					self:GetParent():GetChild("GhostP"..i.."_"..ghostIndex):diffusealpha(0);
				end
			end
							
			fgcurcommand = fgcurcommand + 1;
		end
		if overtime >= 32.0 and fgcurcommand ==  1 then
			-- The sun sets.
			for i,v in ipairs(plr) do
				if v then
					v:accelerate(16.0 / BPS)
					 :x(sw/2);
				end
			end
			self:GetParent():GetChild("felysBG"):finishtweening()
												:queuecommand("Dim");
				
			fgcurcommand = fgcurcommand + 1;
		end
		if overtime >= 80.0 and fgcurcommand ==  2 then
			-- fire temple is...........ANGERY
			for i,v in ipairs(plr) do
			end
			self:GetParent():GetChild("felysBG"):finishtweening()
												:queuecommand("Anger");
				
			fgcurcommand = fgcurcommand + 1;
		end
		if overtime >= 160.0 and fgcurcommand ==  3 then
			-- fire temple is getting ANGERIER
			for i,v in ipairs(plr) do
			end
			self:GetParent():GetChild("felysBG"):finishtweening()
												:queuecommand("Morph");
			self:GetParent():GetChild("felysOL"):finishtweening()
												:queuecommand("Bass");
				
			fgcurcommand = fgcurcommand + 1;
		end
		if overtime >= 192.0 and fgcurcommand ==  4 then
			-- fire temple is getting SO angery
			for i,v in ipairs(plr) do
				
				for ghostIndex = 1,#ghostColors do
					self:GetParent():GetChild("GhostP"..i.."_"..ghostIndex):linear(32.0 / BPS):diffusealpha(1);
				end
			end
			self:GetParent():GetChild("felysOL"):finishtweening();
			
			fgcurcommand = fgcurcommand + 1;
		end		
		if overtime >= 223.0 and fgcurcommand ==  5 then
			-- fire temple is getting EVEN ANGERIEST
			local staggerInfo = felysStaggerColumnsA[felysStaggerIndex+1];
			if overtime >= staggerInfo[1] - felysStaggerLead then				
				for i,v in ipairs(plr) do
					if v then
						colActors = v:GetChild("NoteField"):GetColumnActors();
						
						for j = 1,4 do
							colActors[ staggerInfo[2][j] ]:decelerate(felysStaggerLead/BPS)
														  :y(-64 * felysStaggerBeats[j] * cspdA)
														  :sleep(1.5/BPS)
														  :decelerate(1.0/BPS)
														  :y(0);
						end
					end
				end				
				self:GetParent():GetChild("felysBG"):finishtweening()
													:queuecommand("Morph");
												
				felysStaggerIndex = felysStaggerIndex + 1;
			end
			
			if felysStaggerIndex >= #felysStaggerColumnsA then
				fgcurcommand = fgcurcommand + 1;
			end
		end
		if overtime >= 304.0 and fgcurcommand ==  6 then
			-- fire temple is not angry for now
			for i,v in ipairs(plr) do				
				for ghostIndex = 1,#ghostColors do
					self:GetParent():GetChild("GhostP"..i.."_"..ghostIndex):linear(15.0 / BPS):diffusealpha(0);
				end
			end
			self:GetParent():GetChild("felysBG"):finishtweening()
												:queuecommand("Free");
			
			fgcurcommand = fgcurcommand + 1;
		end	
		if overtime >= 384.0 and fgcurcommand ==  7 then
			-- fire temple is gettin ANGERY AGAIN
			for i,v in ipairs(plr) do				
				for ghostIndex = 1,#ghostColors do
					self:GetParent():GetChild("GhostP"..i.."_"..ghostIndex):linear(32.0 / BPS):diffusealpha(1);
				end
			end
			self:GetParent():GetChild("felysBG"):finishtweening()
												:queuecommand("FastAnger");
			
			fgcurcommand = fgcurcommand + 1;
		end	
		if overtime >= 415.0 and fgcurcommand ==  8 then
			-- fire temple is BACK and ANGERYer THAN EVER BEFORE
			local rotationInfo = felysRotationA[felysRotationIndex+1];
			if overtime >= rotationInfo[1] - felysRotationLead then				
				for i,v in ipairs(plr) do
					if v then
						local rotationHere = rotationInfo[2][i];
						v:finishtweening()
						 :decelerate(felysRotationLead/BPS)
						 :rotationx(rotationHere[1])
						 :rotationy(rotationHere[2])
						 :rotationz(rotationHere[3])
						 :sleep(1.5/BPS)
						 :decelerate(1.0/BPS)
						 :rotationx(0)
						 :rotationy(0)
						 :rotationz(0);						
					end
				end
				self:GetParent():GetChild("felysBG"):finishtweening()
													:queuecommand("Morph2");
													
				felysRotationIndex = felysRotationIndex + 1;
			end
			
			if felysRotationIndex >= #felysRotationA then
				fgcurcommand = fgcurcommand + 1;
			end
		end
		if overtime >= 528.0 and fgcurcommand ==  9 then
			-- fire temple is not angery anymore!! thank god
			for i,v in ipairs(plr) do				
				for ghostIndex = 1,#ghostColors do
					self:GetParent():GetChild("GhostP"..i.."_"..ghostIndex):linear(16.0 / BPS):diffusealpha(0);
				end
			end
			self:GetParent():GetChild("felysBG"):finishtweening()
												:queuecommand("Free");
			
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
table.insert(theBoys, felysGfxHQ);


-------------------------------------------------------------------------------
--
--		Manage arrow mods for the whole song here.
--
local modsTable = {
	-- [1]: beat start
	-- [2]: mod type
	-- [3]: mod strength (out of unity),
	-- [4]: mod approach (in beats to complete)
	-- [5]: player application (1 = P1, 2 = P2, 3 = both, 0 = neither)
		
		{   0.0,	"ScrollSpeed",	 cspd,    2.0,	3}, 
		
		{   9.0,	"Stealth",		  1.0,    7.0,	3}, 
		{  16.0,	"Stealth",		  0.0,    8.0,	3}, 
		{  24.0,	"Dark",			  1.0,    8.0,	3}, 
		{  25.0,	"Stealth",		  1.0,    7.0,	3}, 
		{  32.0,	"Stealth",		  0.0,    8.0,	3}, 
		
		{  56.0,	"ScrollSpeed",	  1.0,    8.0,	3}, 
		{  56.0,	"Brake",		  1.0,    8.0,	3}, 
		{  60.0,	"Dark",			  0.0,    8.0,	3}, 
		
		{  64.0,	"ScrollSpeed",	 cspd,    4.0,	3}, 
		{  64.0,	"Brake",		  0.0,    4.0,	3}, 
		{  64.0,	"Dark",			  1.0,    4.0,	3}, 
		
		{ 108.0,	"Dark",			  0.0,    4.0,	3}, 
		{ 110.0,	"Wave",			  1.5,    2.0,	3}, 
		{ 112.0,	"Wave",			  0.0,    0.5,	3}, 
		{ 114.0,	"Brake",		  0.8,    2.0,	3}, 
		{ 118.0,	"Brake",		  0.0,    2.0,	3}, 
		
		{ 118.0,	"Wave",			  1.5,    2.0,	3}, 
		{ 120.0,	"Wave",			  0.0,    0.5,	3}, 
		{ 122.0,	"Brake",		  0.8,    2.0,	3}, 
		{ 126.0,	"Brake",		  0.0,    2.0,	3}, 
		
		{ 126.0,	"Wave",			  1.5,    2.0,	3}, 
		{ 128.0,	"Wave",			  0.0,    0.5,	3}, 
		
		{ 134.0,	"Wave",			  1.5,    2.0,	3}, 
		{ 136.0,	"Wave",			  0.0,    0.5,	3}, 
		
		{ 142.0,	"Wave",			  1.5,    2.0,	3}, 
		{ 144.0,	"Wave",			  0.0,    2.0,	3}, 
		
		{ 146.0,	"Wave",			  1.5,    2.0,	3}, 
		{ 148.0,	"Wave",			  0.0,    2.0,	3}, 
		
		{ 150.0,	"Wave",			  1.5,    2.0,	3}, 
		{ 152.0,	"Wave",			  0.0,    2.0,	3}, 
		
		{ 154.0,	"Wave",			  1.5,    2.0,	3}, 
		{ 156.0,	"Wave",			  0.0,    1.0,	3}, 
		{ 157.0,	"Wave",			  1.5,    1.0,	3}, 
		{ 158.0,	"Wave",			  0.0,    2.0,	3}, 		
		
		{ 192.0,	"Dark",			  0.7,   32.0,	3}, 
		
		{ 220.0,	"ScrollSpeed",	cspdA,    3.0,	3}, 
		{ 220.0,	"Centered",		  1.0,    3.0,	3}, 
		
		{ 256.0,	"Tiny",			  0.5,    2.0,	3},
--		{ 258.0,	"Boost",		  0.5,    0.5,	3},
		{ 258.5,	"Tiny",			  0.0,    1.0,	3},
--		{ 259.0,	"Boost",		  0.0,    0.5,	3},
		
		{ 272.0,	"Tiny",			  0.5,    2.0,	3},
--		{ 274.0,	"Boost",		  0.5,    0.5,	3},
		{ 274.5,	"Tiny",			  0.0,    1.0,	3},
--		{ 275.0,	"Boost",		  0.0,    0.5,	3},
		
		{ 284.0,	"ScrollSpeed",	 cspd,    4.0,	3}, 
		{ 284.0,	"Centered",		  0.0,    4.0,	3}, 
		
		{ 304.0,	"Tilt",			  1.0,    8.0,	1},
		{ 304.0,	"Tilt",			 -1.0,    8.0,	2},
		{ 312.0,	"Tilt",			  0.5,    4.0,	1},
		{ 312.0,	"Tilt",			 -0.5,    4.0,	2},
		{ 316.0,	"Tilt",			  0.0,    2.0,	3},
		
		{ 320.0,	"Tipsy",		  0.5,   64.0,	3},
		{ 320.0,	"Tornado",		  0.3,   64.0,	3},
		
		
		{ 348.0,	"Dark",			  0.7,    0.01,	3},
		{ 348.0,	"Sudden",		  1.0,    0.01,	3},
		{ 348.0,	"SuddenOffset",	 -0.7,    0.01,	3},
		{ 348.0,	"Centered",		  1.7,    3.0,	3},
		{ 348.5,	"Dark",			  0.0,    2.0,	3},
		{ 351.0,	"Centered",		  0.0,    1.0,	3},
		{ 351.0,	"Sudden",		  0.0,    1.0,	3},
		{ 351.0,	"SuddenOffset",	  0.0,    1.0,	3},
		
		{ 376.0,	"Beat",			  1.0,    8.0,	3},
		{ 384.0,	"Beat",			  0.0,    1.0,	3},
		{ 384.0,	"Tipsy",		  0.0,   32.0,	3},
		{ 384.0,	"Tornado",		  0.0,   32.0,	3},
		
		{ 416.0,	"Mini",			  0.5,    0.01,	1},
		{ 416.0,	"Mini",			 -0.3,    0.01,	2},
		{ 417.0,	"Mini",			  0.0,    2.0,	3},
		
		{ 420.0,	"Mini",			 -0.3,    0.01,	1},
		{ 420.0,	"Mini",			  0.5,    0.01,	2},
		{ 421.0,	"Mini",			  0.0,    2.0,	3},
		
		{ 424.0,	"Mini",			  0.5,    0.01,	1},
		{ 424.0,	"Mini",			 -0.3,    0.01,	2},
		{ 425.0,	"Mini",			  0.0,    2.0,	3},
		
		{ 428.0,	"Tiny",			  0.5,    0.01,	1},
		{ 428.0,	"Tiny",			 -0.3,    0.01,	2},
		{ 429.0,	"Tiny",			 -0.3,    0.01,	1},
		{ 429.0,	"Tiny",			  0.5,    0.01,	2},
		{ 429.0,	"Stealth",		  0.8,    0.01,	3},
		{ 430.0,	"Tiny",			  0.0,    2.0,	3},
		{ 430.0,	"Stealth",		  0.0,    1.0,	3},
		
		{ 432.0,	"Mini",			  0.5,    0.01,	2},
		{ 432.0,	"Mini",			 -0.3,    0.01,	1},
		{ 433.0,	"Mini",			  0.0,    2.0,	3},
		
		{ 436.0,	"Mini",			 -0.3,    0.01,	2},
		{ 436.0,	"Mini",			  0.5,    0.01,	1},
		{ 437.0,	"Mini",			  0.0,    2.0,	3},
		
		{ 440.0,	"Mini",			  0.5,    0.01,	2},
		{ 440.0,	"Mini",			 -0.3,    0.01,	1},
		{ 441.0,	"Mini",			  0.0,    2.0,	3},
		
		{ 444.0,	"Tiny",			  0.5,    0.01,	2},
		{ 444.0,	"Tiny",			 -0.3,    0.01,	1},
		{ 444.0,	"Stealth",		  0.4,    3.0,	3},
		{ 444.5,	"Dizzy",		 -1.0,    0.5,	3},
		{ 446.0,	"Tiny",			  0.0,    2.0,	3},
		{ 447.0,	"Stealth",		  0.0,    1.0,	3},
		{ 447.0,	"Dizzy",		  0.0,    0.8,	3},
		
		{ 448.0,	"Mini",			  0.6,    0.01,	1},
		{ 448.0,	"Mini",			 -0.4,    0.01,	2},
		{ 449.0,	"Mini",			  0.0,    2.0,	3},
		
		{ 452.0,	"Mini",			 -0.4,    0.01,	1},
		{ 452.0,	"Mini",			  0.6,    0.01,	2},
		{ 453.0,	"Mini",			  0.0,    2.0,	3},
		
		{ 456.0,	"Mini",			  0.6,    0.01,	1},
		{ 456.0,	"Mini",			 -0.4,    0.01,	2},
		{ 457.0,	"Mini",			  0.0,    2.0,	3},
		
		{ 460.0,	"Tiny",			  0.6,    0.01,	1},
		{ 460.0,	"Tiny",			 -0.4,    0.01,	2},
		{ 461.0,	"Tiny",			 -0.4,    0.01,	1},
		{ 461.0,	"Tiny",			  0.6,    0.01,	2},
		{ 461.0,	"Stealth",		  0.8,    0.01,	3},
		{ 462.0,	"Tiny",			  0.0,    2.0,	3},
		{ 462.0,	"Stealth",		  0.0,    1.0,	3},
		
		{ 464.0,	"Mini",			  0.6,    0.01,	2},
		{ 464.0,	"Mini",			 -0.4,    0.01,	1},
		{ 465.0,	"Mini",			  0.0,    2.0,	3},
		
		{ 468.0,	"Mini",			 -0.4,    0.01,	2},
		{ 468.0,	"Mini",			  0.6,    0.01,	1},
		{ 469.0,	"Mini",			  0.0,    2.0,	3},
		
		{ 472.0,	"Mini",			  0.6,    0.01,	2},
		{ 472.0,	"Mini",			 -0.4,    0.01,	1},
		{ 473.0,	"Mini",			  0.0,    2.0,	3},
		
		{ 476.0,	"Tiny",			  0.6,    0.01,	2},
		{ 476.0,	"Tiny",			 -0.4,    0.01,	1},
		{ 477.0,	"Tiny",			 -0.4,    0.01,	2},
		{ 477.0,	"Tiny",			  0.6,    0.01,	1},
		{ 477.0,	"Stealth",		  0.8,    0.01,	3},
		{ 478.0,	"Tiny",			  0.0,    2.0,	3},
		{ 478.0,	"Stealth",		  0.0,    1.0,	3},
		
		{ 480.0,	"Mini",			  0.7,    0.01,	1},
		{ 480.0,	"Mini",			 -0.5,    0.01,	2},
		{ 481.0,	"Mini",			  0.0,    2.0,	3},
		
		{ 484.0,	"Mini",			 -0.5,    0.01,	1},
		{ 484.0,	"Mini",			  0.7,    0.01,	2},
		{ 485.0,	"Mini",			  0.0,    2.0,	3},
		
		{ 488.0,	"Mini",			  0.7,    0.01,	1},
		{ 488.0,	"Mini",			 -0.5,    0.01,	2},
		{ 489.0,	"Mini",			  0.0,    2.0,	3},
		
		{ 492.0,	"Tiny",			  0.7,    0.01,	1},
		{ 492.0,	"Tiny",			 -0.5,    0.01,	2},
		{ 493.0,	"Tiny",			 -0.5,    0.01,	1},
		{ 493.0,	"Tiny",			  0.7,    0.01,	2},
		{ 493.0,	"Stealth",		  0.8,    0.01,	3},
		{ 494.0,	"Tiny",			  0.0,    2.0,	3},
		{ 494.0,	"Stealth",		  0.0,    1.0,	3},
		
		{ 496.0,	"Mini",			  0.7,    0.01,	2},
		{ 496.0,	"Mini",			 -0.5,    0.01,	1},
		{ 497.0,	"Mini",			  0.0,    2.0,	3},
		
		{ 500.0,	"Mini",			 -0.5,    0.01,	2},
		{ 500.0,	"Mini",			  0.7,    0.01,	1},
		{ 501.0,	"Mini",			  0.0,    2.0,	3},
		
		{ 504.0,	"Mini",			  0.7,    0.01,	2},
		{ 504.0,	"Mini",			 -0.5,    0.01,	1},
		{ 505.0,	"Mini",			  0.0,    2.0,	3},
		
		{ 508.0,	"Tiny",			  0.7,    0.01,	2},
		{ 508.0,	"Tiny",			 -0.5,    0.01,	1},
		{ 509.0,	"Tiny",			 -0.5,    0.01,	2},
		{ 509.0,	"Tiny",			  0.7,    0.01,	1},
		{ 509.0,	"Stealth",		  0.8,    0.01,	3},
		{ 510.0,	"Tiny",			  0.0,    2.0,	3},
		{ 510.0,	"Stealth",		  0.0,    1.0,	3},
		
		{ 512.0,	"Mini",			  0.9,    0.01,	1},
		{ 512.0,	"Mini",			 -0.6,    0.01,	2},
		{ 513.0,	"Mini",			  0.0,    2.0,	3},
		
		{ 516.0,	"Mini",			 -0.6,    0.01,	1},
		{ 516.0,	"Mini",			  0.9,    0.01,	2},
		{ 517.0,	"Mini",			  0.0,    2.0,	3},
		
		{ 520.0,	"Mini",			  0.9,    0.01,	1},
		{ 520.0,	"Mini",			 -0.6,    0.01,	2},
		{ 521.0,	"Mini",			  0.0,    2.0,	3},
		
		{ 524.0,	"Tiny",			  0.9,    0.01,	1},
		{ 524.0,	"Tiny",			 -0.6,    0.01,	2},
		{ 525.0,	"Tiny",			 -0.6,    0.01,	1},
		{ 525.0,	"Tiny",			  0.9,    0.01,	2},
		{ 525.0,	"Stealth",		  0.8,    0.01,	3},
		{ 526.0,	"Tiny",			  0.0,    2.0,	3},
		{ 526.0,	"Stealth",		  0.0,    1.0,	3},
				
		{ 528.0,	"Dark",			  0.8,   16.0,	3},
		
		{ 566.0,	"Stealth",		  0.9,    0.01,	3},
		{ 566.5,	"Stealth",		  0.0,    1.5,	3},
		
		{ 590.0,	"Flip",			  0.0,    3.0,	2},
		{ 590.0,	"Flip",			  0.0,    3.0,	1},
		{ 590.0,	"Invert",		  0.5,    3.0,	2},
		{ 590.0,	"Invert",		 -0.5,    3.0,	1},
		{ 593.0,	"Flip",			  0.5,    4.0,	2},
		{ 593.0,	"Flip",			 -0.5,    4.0,	1},
		{ 593.0,	"Invert",		 -0.5,    4.0,	2},
		{ 593.0,	"Invert",		  0.5,    4.0,	1},
		{ 597.0,	"Flip",			 -0.5,    4.0,	2},
		{ 597.0,	"Flip",			  0.5,    4.0,	1},
		{ 597.0,	"Invert",		  0.5,    4.0,	2},
		{ 597.0,	"Invert",		 -0.5,    4.0,	1},
		{ 601.0,	"Flip",			  0.0,    3.0,	3},
		{ 601.0,	"Invert",		  0.0,    3.0,	3},
		
		{ 607.0,	"Invert",		  0.5,    0.01,	1},
		{ 607.0,	"Invert",		 -0.5,    0.01,	2},
		{ 607.1,	"Invert",		  0.0,    0.9,	3},
		{ 609.0,	"Flip",			  0.5,    0.01,	1},
		{ 609.0,	"Flip",			 -0.5,    0.01,	2},
		{ 609.1,	"Flip",			  0.0,    0.9,	3},
		{ 610.0,	"Tornado",		  1.0,    2.0,	3},
		{ 610.0,	"Boost",		  0.5,    2.0,	3},
		{ 612.0,	"Tornado",		  0.0,    16.0,	3},
		{ 612.0,	"Boost",		  0.0,    12.0,	3},
		{ 626.0,	"Brake",		  0.9,    4.0,	3},
		
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
					local BPS = GAMESTATE:GetSongBPS();
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

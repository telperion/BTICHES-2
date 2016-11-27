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

local felysConstructVertices = function(brightness, disturbance)
	local srcQuads  = nil;
	local srcColors = nil;
	if brightness > 0.5 then
		srcQuads  = felysSunsetQuadsLight;
		srcColors = felysSunsetColorsLight;
	elseif brightness > -0.5 then 
		srcQuads  = felysSunsetQuadsDark;
		srcColors = felysSunsetColorsDark;
	else
		srcQuads  = felysSunsetQuadsAngry;
		srcColors = felysSunsetColorsAngry;
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
		self:decelerate(2.0 / BPS)
			:SetVertices(verts);
	end,
	DimCommand = function(self)
		Trace("Dimming!");
		local BPS = GAMESTATE:GetSongBPS();	
		local verts = felysConstructVertices(0, nil);
		self:aux(0)
			:smooth(64.0 / BPS)
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
		local verts = felysConstructVertices(-1, nil);
		self:aux(-1)
			:smooth(64.0 / BPS)
			:SetVertices(verts);
	end
}
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
			:diffuse(1.0, 1.0, 1.0, 1.0);					
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
		
--		Trace("> making scary "..quantColor.." note #"..i);
		felysNotes[#felysNotes + 1] = NOTESKIN:LoadActorForNoteSkin("Down", "Tap Note", "cyber") .. {
			Name = "ScaryNote"..quantColor.."_"..i,
			InitCommand = function(self)
				self:visible(true)
					:xy(sw/2 + pos[1], sh/2 + pos[2])
					:texturetranslate(texArrows[quantColor], 0);
			end,
		};
--		Trace(">>> made scary "..quantColor.." note #"..i);
	end
	Trace(">>> made "..quantCount.." scary "..quantColor.." notes");
	stronk = stronk + 64;
end

for i = 1,#felysNotes do
--	table.insert(theBoys, felysNotes[i]);
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
			
--		table.insert(theBoys, aftMemory);
--		table.insert(theBoys, aftOutput);
--		table.insert(theBoys, ghostBoy);
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
			-- Hide the actual playfields. Let the proxies do the work.
			for i,v in ipairs(plr) do
				if v then
					v:visible(false)
					 :decelerate(16.0 / BPS)
					 :y(sh/2 - 30)
					 :z(0);
				end
			end
			self:GetParent():GetChild("felysBG"):queuecommand("Dim")
												:queuecommand("Anger");
			self:GetParent():GetChild("felysOL"):sleep(4.0/BPS)
												:queuecommand("Bass");
				
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
		
		{   8.0,	"Dark",			  1.0,    4.0,	3}, 
		
		
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

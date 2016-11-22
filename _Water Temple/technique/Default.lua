-------------------------------------------------------------------------------
--
--		Special Content to Exercise the Player's Waterbending Technique
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
--
-- 		Some graphical doods 'n' dads 'n' doodads.
--
local SQRT3 = math.sqrt(3.0);
local LOG2  = math.log(2.0);
local enjoyTriangleSize 	= 20;			-- Length of equilateral triangle tile side, in pixels.
local enjoyTriangleAscent   = enjoyTriangleSize * (SQRT3 / 2);
local enjoyBGFieldSpan		= math.ceil(      sw / enjoyTriangleSize);		-- The BG field is this many triangles wide.
local enjoyBGFieldWidth 	= 				enjoyBGFieldSpan + 1;			-- The BG field requires this many triangles to cover.
local enjoyBGFieldHeight 	= math.ceil(0.5 * sh / enjoyTriangleAscent);	-- The BG field is this many DOUBLE triangles tall.
local enjoyBGFieldTexScale	= enjoyBGFieldSpan / (1 + enjoyBGFieldSpan);	-- The BG field texture coordinates are scaled by this much from center.

-- Literally take a dump in a dump TRUCK.
local tw = math.exp(math.ceil(math.log(sw)/LOG2) * LOG2);
local th = math.exp(math.ceil(math.log(sh)/LOG2) * LOG2);
Trace("### Are you shitting in my asshole with this textures " ..
	  "constrained to powers of 2 bullshit!! tw = "..tw..", th = "..th..".");
local cx = sw/2;
local cy = sh/2;
local BTIUtil_ScaleTexX = function(x)
	return (x - cx)/sw * enjoyBGFieldTexScale + 0.5;
end
local BTIUtil_ScaleTexY = function(y)
	return (y - cy)/sh * enjoyBGFieldTexScale + 0.5;
end
local BTIUtil_ScaleTex = function(x, y)
	return {BTIUtil_ScaleTexX(x) * sw/tw, BTIUtil_ScaleTexY(y) * sh/th};
end

local oneStripVertices = {
		{{-0.5 * enjoyTriangleSize,	0.0, 0}, {1,1,1,0.9}, {0, 0}}
	};
for i = 0,enjoyBGFieldWidth-1 do
	oneStripVertices[#oneStripVertices + 1] = {{ i      * enjoyTriangleSize,	1.0 * enjoyTriangleAscent, 	0}, {1,1,1,0.9}, {0, 0}};
	oneStripVertices[#oneStripVertices + 1] = {{(i+0.5) * enjoyTriangleSize,	0.0, 						0}, {1,1,1,0.9}, {0, 0}};
end
for i = 1,#oneStripVertices do
	oneStripVertices[i][3] = BTIUtil_ScaleTex(oneStripVertices[i][1][1], oneStripVertices[i][1][2]);
end

local enjoyBG = Def.ActorFrame{
	Name = "enjoyBG",
	InitCommand = function(self)
		self:xy(0, 0);
		for i = 1,#oneStripVertices,2 do
			Trace("## ["..i.."][1] = {"..oneStripVertices[i][1][1]..", "..oneStripVertices[i][1][2]..", "..oneStripVertices[i][1][3].."}!");
			Trace("## ["..i.."][2] = {"..oneStripVertices[i][2][1]..", "..oneStripVertices[i][2][2]..", "..oneStripVertices[i][2][3]..", "..oneStripVertices[i][2][4].."}!");
			Trace("## ["..i.."][3] = {"..oneStripVertices[i][3][1]..", "..oneStripVertices[i][3][2].."}!");
		end
	end,
	OnCommand = function(self)		
		local rowChildren = {}
		for moniker, starlet in pairs(self:GetChildren()) do
			if moniker:find("enjoyBGRow") then
				Trace("## Found BG row " .. moniker .. "!");
				rowChildren[#rowChildren+1] = starlet;
			end
		end
		
		Trace ("## sw = "..sw..", sh = "..sh.."!!");
		
		for r = 1,enjoyBGFieldHeight do
			rowChildren[2*r-1]:SetVertices(oneStripVertices)
							  :visible(true);
			for i = 1,#oneStripVertices,2 do
				oneStripVertices[i][1][2] = oneStripVertices[i][1][2] + 2 * enjoyTriangleAscent;
				oneStripVertices[i][3] = BTIUtil_ScaleTex(oneStripVertices[i][1][1], oneStripVertices[i][1][2]);
				Trace("## ["..i.."][1] = {"..oneStripVertices[i][1][1]..", "..oneStripVertices[i][1][2]..", "..oneStripVertices[i][1][3].."}!");
				Trace("## ["..i.."][2] = {"..oneStripVertices[i][2][1]..", "..oneStripVertices[i][2][2]..", "..oneStripVertices[i][2][3]..", "..oneStripVertices[i][2][4].."}!");
				Trace("## ["..i.."][3] = {"..oneStripVertices[i][3][1]..", "..oneStripVertices[i][3][2].."}!");
			end
			
			rowChildren[2*r  ]:SetVertices(oneStripVertices)
							  :visible(true);
			for i = 2,#oneStripVertices,2 do
				oneStripVertices[i][1][2] = oneStripVertices[i][1][2] + 2 * enjoyTriangleAscent;
				oneStripVertices[i][3] = BTIUtil_ScaleTex(oneStripVertices[i][1][1], oneStripVertices[i][1][2]);
				Trace("## ["..i.."][1] = {"..oneStripVertices[i][1][1]..", "..oneStripVertices[i][1][2]..", "..oneStripVertices[i][1][3].."}!");
				Trace("## ["..i.."][2] = {"..oneStripVertices[i][2][1]..", "..oneStripVertices[i][2][2]..", "..oneStripVertices[i][2][3]..", "..oneStripVertices[i][2][4].."}!");
				Trace("## ["..i.."][3] = {"..oneStripVertices[i][3][1]..", "..oneStripVertices[i][3][2].."}!");
			end
		end
	end
};
for r = 1,2*enjoyBGFieldHeight do
	enjoyBG[#enjoyBG + 1] = Def.ActorMultiVertex {
		Name = "enjoyBGRow"..r,
		InitCommand = function(self)
			self:visible(false)
				:xy(0, 0)
				:SetDrawState{Mode = "DrawMode_Strip", First = 1, Num = -1};
		end
	};
end
table.insert(theBoys, enjoyBG);


function BTIUtil_Reflect(matriarch, depthString) 
	depthString = depthString or ""
	local childCount = 0
	if matriarch ~= nil then
		if matriarch["GetChildren"] ~= nil then
			if matriarch:GetChildren() then
				for k,v in pairs(matriarch:GetChildren()) do
					Trace(">>>\t" .. depthString .. k .. " (type " .. type(v) .. ")")
					if #k ~= 0 then
						childCount = childCount + BTIUtil_Reflect(v, depthString .. "\t")
					end
				end
			end
		end
	end
	return childCount
end


local enjoyBGTexSet = false;
local enjoyBGTex = Def.ActorFrameTexture {	
	InitCommand = function(self)
		self:SetWidth(sw)
			:SetHeight(sh)
			:xy(0, 0)
			:EnableAlphaBuffer(true)
			:Create();
	end,
	OnCommand = function(self)
		-- Set myself as the texture of two sprites.
		local texSelf = self:GetTexture();
		if texSelf then
			Trace("### OK, then.");
			if not enjoyBGTexSet then
				local enjoyBGHandle = self:GetParent():GetChild("enjoyBG"):GetChildren();
				for starlet in pairs(enjoyBGHandle) do
					enjoyBGHandle[starlet]:SetTexture( texSelf );
					Trace("### " .. starlet .. ": oh my!!");
				end
				Trace("### OK, then!!");
				enjoyBGTexSet = true;
			
				--self:GetParent():GetChild("enjoyTestSprite"):SetTexture( texSelf );
				local tcw = texSelf:GetTextureWidth();
				local tch = texSelf:GetTextureHeight();
				--Trace("### Texture coordinate rectangle: {L="..tcr[1]..", R="..tcr[2]..", T="..tcr[3]..", B="..tcr[4].."}!");
				Trace("### Texture size: {W="..tcw..", H="..tch.."}!");
				Trace("### Window  size: {W="..sw..", H="..sh.."}!");
			end
		end
		
		for i,v in ipairs(plr) do
			if not v then
				plr[i] = SCREENMAN:GetTopScreen():GetChild('PlayerP' .. i);
				v = plr[i];				
			end
			BTIUtil_Reflect(v);
			Trace("### " .. i .. ": " .. (plr[i] and "yes" or "no") .. ": oh wow!!");
			self:GetChild("P" .. i .. "Clone"):SetTarget(v)
											  :xy(0, 0);
		end
	end,
	Def.Quad {
		Name = "oh my god",
		InitCommand = function(self)
			self:SetWidth(sw)
				:SetHeight(sh)
				:xy(sw/2, sh/2)
				:diffuse({1.0, 1.0, 1.0, 0.5});
		end
	},
	Def.ActorProxy {Name = "P1Clone"},
	Def.ActorProxy {Name = "P2Clone"}
};
table.insert(theBoys, enjoyBGTex);

local enjoyTestSprite = Def.Sprite {
	Name = "enjoyTestSprite",
	InitCommand = function(self)
		self:xy(sw/2, sh/2);
	end
};
--table.insert(theBoys, enjoyTestSprite);


-------------------------------------------------------------------------------
--
-- 		More proxies than the Middle East during the Cold War
--
local enjoyP1ProxA = Def.ActorProxy {
	Name = "P1CloneA",
	InitCommand = function(self)
	end,
	OnCommand = function(self)
		McCoy = SCREENMAN:GetTopScreen():GetChild('PlayerP1');
		if McCoy then
			Trace(self:GetName() .. " is alive!!");
			self:SetTarget(McCoy)
				:xy(0, 0);
		end
	end
}
table.insert(theBoys, enjoyP1ProxA);

local enjoyP1ProxB = Def.ActorProxy {
	Name = "P1CloneB",
	InitCommand = function(self)
	end,
	OnCommand = function(self)
		McCoy = SCREENMAN:GetTopScreen():GetChild('PlayerP1');
		if McCoy then
			Trace(self:GetName() .. " is alive!!");
			self:SetTarget(McCoy)
				:xy(0, 0);
		end
	end
}
table.insert(theBoys, enjoyP1ProxB);

local enjoyP2ProxA = Def.ActorProxy {
	Name = "P2CloneA",
	InitCommand = function(self)
	end,
	OnCommand = function(self)
		McCoy = SCREENMAN:GetTopScreen():GetChild('PlayerP2');
		if McCoy then
			Trace(self:GetName() .. " is alive!!");
			self:SetTarget(McCoy)
				:xy(0, 0);
		end
	end
}
table.insert(theBoys, enjoyP2ProxA);

local enjoyP2ProxB = Def.ActorProxy {
	Name = "P2CloneB",
	InitCommand = function(self)
	end,
	OnCommand = function(self)
		McCoy = SCREENMAN:GetTopScreen():GetChild('PlayerP2');
		if McCoy then
			Trace(self:GetName() .. " is alive!!");
			self:SetTarget(McCoy)
				:xy(0, 0);
		end
	end
}
table.insert(theBoys, enjoyP2ProxB);


-------------------------------------------------------------------------------

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

		
		if overtime >=   0.0 and fgcurcommand ==  0 then
			-- Start moving players toward the center.
			for i,v in ipairs(plr) do
				if v then
					v:visible(false);
					v:decelerate(8.0 / BPS):x(sw/2):z(0);
				end
			end
			
			fgcurcommand = fgcurcommand + 1;
		end
		if overtime >=  12.0 and fgcurcommand ==  1 then
			-- oh damn now what's going on
			for i,v in ipairs(plr) do
				if v then
					v:decelerate(4.0 / BPS):x(sw/2 + 64*i-96);
				end
			end
			
			fgcurcommand = fgcurcommand + 1;
		end
		if overtime >=  16.0 and fgcurcommand ==  2 then
			-- take time to smell the rosetations
			local enjoyTheta = overtime * math.pi / 2.0;
			local enjoyRadius = 32.0;
			
			-- around and around! shit boy
			for i,v in ipairs(plr) do
				if v then
					local sideSign = (i == 2) and 1 or -1;
					v:x(sw/2 + enjoyRadius * sideSign * math.cos(enjoyTheta));
					v:z(       enjoyRadius * sideSign * math.sin(enjoyTheta));
				end
			end
		end
		if overtime >=  32.0 and fgcurcommand ==  2 then
			-- okay that is QUITE ENOUGH
			for i,v in ipairs(plr) do
				if v then
					v:x(sw/2 + 32*i-48);
					v:z(0);
					v:SetLife(0.8);
				end
			end
			
			fgcurcommand = fgcurcommand + 1;
		end
		if overtime >=  48.0 and fgcurcommand ==  3 then
			-- boy i die!! shit boy...
			local enjoyTheta = overtime * math.pi / 2.0;
			
			for i,v in ipairs(plr) do
				if v then					
					for j,w in ipairs(v:GetChild("NoteField"):GetColumnActors()) do
						w:diffusealpha(0.5 + 0.5 * math.sin(enjoyTheta + math.pi / 2.0 * j));
					end
				end
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
table.insert(theBoys, enjoyGfxHQ);


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
		
		{ 0.0,	"Flip",			-0.5,     2.0, 3}, 
		{ 4.0,	"Invert",		 0.0,     2.0, 3}, 
		{ 64.0,	"Split",		 0.1,     2.0, 3}, 
		{ 72.0,	"Split",		-0.1,     2.0, 3}, 
		{ 80.0,	"Split",		 0.0,     1.0, 3}, 
		{ 80.0,	"Flip",			-0.25,    1.0, 3}, 
		{ 80.0,	"Invert",		 0.0,     1.0, 3}
	};
local modsLaunched = 0;
local modsWait = 0;
local modsLeadBy = 0.03;

local enjoyModsHQ = Def.Quad {
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
		
		if modsLaunched >= #modsTable then
			Trace('>>> modsHQ: Hibernated!!');
			self:hibernate(600);
			do return end
		else
			-- Trace('>>> modsHQ: ' .. modsLaunched);
			-- Check the next line of the mods table.
			modNext = modsTable[modsLaunched + 1];
			
			if overtime + modsLeadBy >= modNext[1] then
				-- TODO: this assumes the effect applies over a constant BPM section!!
				local BPS = GAMESTATE:GetSongBPS();
				Trace('>>> modsHQ: ' .. modsLaunched .. ' @ time = ' .. overtime);
				
				for _,pe in pairs(GAMESTATE:GetEnabledPlayers()) do
					if (modNext[5] == 1 or modNext[5] == 3) then								-- TODO: FIXME
						pops = GAMESTATE:GetPlayerState(pe):GetPlayerOptions("ModsLevel_Song");
						
						-- Calculate approach (in units of the value per second):
						-- a = (value final - value initial) * (beats per second) / (beats for transition + ``machine epsilon``)
						-- Has to be done individually for each player, just in case they're coming from different initial values :(
						opVal, opApproach = pops[ modNext[2] ]( pops );
						if opApproach == 0 then -- SOMEONE FUCKED UP AND IT WASN'T ME.
							newApproach = BPS;
						else
							newApproach = math.abs(modNext[3] - opVal) * BPS / (modNext[4] + 0.001);
						end
											pops[ modNext[2] ]( pops, modNext[3], newApproach );
						Trace('>>> modsHQ: ' .. opVal      .. ' @ rate = ' .. opApproach ..  ' for ' .. pe);
						Trace('>>> modsHQ: ' .. modNext[3] .. ' @ rate = ' .. newApproach .. ' for ' .. pe .. ' [New!]');
					end
				end
				
				modsLaunched = modsLaunched + 1;
			else
				-- Trace('>>> modsHQ: ' .. overtime .. ' < ' .. modNext[1]);
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
table.insert(theBoys, enjoyModsHQ);

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
			P1:GetChild("Combo"):hibernate(1573);
		end
		local P2 = hamburger:GetChild("PlayerP2");
		if P2 then 
			P2:GetChild("Combo"):hibernate(1573);
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

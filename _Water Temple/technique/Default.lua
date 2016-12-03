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

local allVertices = {};
local morphedVertices = {};
-- Lua with that stealth shallow copy. fuck thou and the referential horse thee rode in on
deepcopy = function(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
local enjoyBG = Def.ActorFrame{
	Name = "enjoyBG",
	InitCommand = function(self)
		self:xy(0, 0);
		for i = 1,#oneStripVertices,2 do
--			Trace("## ["..i.."][1] = {"..oneStripVertices[i][1][1]..", "..oneStripVertices[i][1][2]..", "..oneStripVertices[i][1][3].."}!");
--			Trace("## ["..i.."][2] = {"..oneStripVertices[i][2][1]..", "..oneStripVertices[i][2][2]..", "..oneStripVertices[i][2][3]..", "..oneStripVertices[i][2][4].."}!");
--			Trace("## ["..i.."][3] = {"..oneStripVertices[i][3][1]..", "..oneStripVertices[i][3][2].."}!");
		end
	end,
	OnCommand = function(self)		
		local rowChildren = {}
		for moniker, starlet in pairs(self:GetChildren()) do
			rn = tonumber(string.match(moniker, "enjoyBGRow([0-9]+)"));
			if rn then
				Trace("## Found BG row " .. moniker .. "!");
				rowChildren[rn] = starlet;
			end
		end
		
		Trace ("## sw = "..sw..", sh = "..sh.."!!");
		
		for r = 1,enjoyBGFieldHeight do			
			allVertices[#allVertices + 1] = deepcopy(oneStripVertices);
			rowChildren[2*r-1]:SetVertices(oneStripVertices)
							  :visible(true);
			for i = 1,#oneStripVertices,2 do
				oneStripVertices[i][1][2] = oneStripVertices[i][1][2] + 2 * enjoyTriangleAscent;
				oneStripVertices[i][3] = BTIUtil_ScaleTex(oneStripVertices[i][1][1], oneStripVertices[i][1][2]);
--				Trace("## ["..i.."][1] = {"..oneStripVertices[i][1][1]..", "..oneStripVertices[i][1][2]..", "..oneStripVertices[i][1][3].."}!");
--				Trace("## ["..i.."][2] = {"..oneStripVertices[i][2][1]..", "..oneStripVertices[i][2][2]..", "..oneStripVertices[i][2][3]..", "..oneStripVertices[i][2][4].."}!");
--				Trace("## ["..i.."][3] = {"..oneStripVertices[i][3][1]..", "..oneStripVertices[i][3][2].."}!");
			end
			
			allVertices[#allVertices + 1] = deepcopy(oneStripVertices);
			rowChildren[2*r  ]:SetVertices(oneStripVertices)
							  :visible(true);
			for i = 2,#oneStripVertices,2 do
				oneStripVertices[i][1][2] = oneStripVertices[i][1][2] + 2 * enjoyTriangleAscent;
				oneStripVertices[i][3] = BTIUtil_ScaleTex(oneStripVertices[i][1][1], oneStripVertices[i][1][2]);
--				Trace("## ["..i.."][1] = {"..oneStripVertices[i][1][1]..", "..oneStripVertices[i][1][2]..", "..oneStripVertices[i][1][3].."}!");
--				Trace("## ["..i.."][2] = {"..oneStripVertices[i][2][1]..", "..oneStripVertices[i][2][2]..", "..oneStripVertices[i][2][3]..", "..oneStripVertices[i][2][4].."}!");
--				Trace("## ["..i.."][3] = {"..oneStripVertices[i][3][1]..", "..oneStripVertices[i][3][2].."}!");
			end
		end
		
		morphedVertices = deepcopy(allVertices);
	end,
	MorphCommand = function(self)
		local BPS = GAMESTATE:GetSongBPS();
		
		local rowChildren = {}
		for moniker, starlet in pairs(self:GetChildren()) do
			rn = tonumber(string.match(moniker, "enjoyBGRow([0-9]+)"));
			if rn then
				Trace("## Morphing BG row " .. moniker .. " (" .. rn .. ")!");
				rowChildren[rn] = starlet;
			end
		end
		
		for r = 1,enjoyBGFieldHeight*2 do
			local osv = morphedVertices[r];
			for i = 1,#osv do 
				if r == 1 or (i+r) % 2 == 1 then				
					osv[i][3] = BTIUtil_ScaleTex(osv[i][1][1], osv[i][1][2]);
					osv[i][3][1] = osv[i][3][1] + 0.8 * (math.random() - 0.5) * (sw/tw) / enjoyBGFieldWidth;
					osv[i][3][2] = osv[i][3][2] + 0.4 * (math.random() - 0.5) * (sh/th) / enjoyBGFieldHeight;
				else
					osv[i][3] = morphedVertices[r-1][i][3];
				end
				
--				Trace("## ["..i.."][1] = {"..osv[i][1][1]..", "..osv[i][1][2]..", "..osv[i][1][3].."}!");
--				Trace("## ["..i.."][2] = {"..osv[i][2][1]..", "..osv[i][2][2]..", "..osv[i][2][3]..", "..osv[i][2][4].."}!");
--				Trace("## ["..i.."][3] = {"..osv[i][3][1]..", "..osv[i][3][2].."}!");

			end
			rowChildren[r]:smooth(4.0 / BPS)
						  :SetVertices(osv);
		end		
		
		self:sleep(2.0 / BPS)
			:queuecommand("Morph2");
	end,
	Morph2Command = function(self)			
		local BPS = GAMESTATE:GetSongBPS();
		
		morphedVertices = deepcopy(allVertices);
		self:sleep(2.0 / BPS)
			:queuecommand("Morph");
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
local enjoyBGTexReflect = nil;
local enjoyBGTex = Def.ActorFrameTexture {	
	Name = "enjoyBGTex",
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
--			BTIUtil_Reflect(v);
--			Trace("### " .. i .. ": " .. (plr[i] and "yes" or "no") .. ": oh wow!!");
			self:GetChild("P" .. i .. "Clone"):SetTarget(v)
											  :xy(0, 0)
											  :visible(true);
		end
	end,
	Def.Sprite {
		Name = "oh my god",
		Texture = "water.png",
		InitCommand = function(self)
			self:SetWidth(sw)
				:SetHeight(sh)
				:xy(sw/2, sh/2)
				:diffuse({1.0, 1.0, 1.0, 0.7});
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
local enjoyProxies = {}

for playerNumber = 1,2 do
	for proxyIndex = 0,4 do
		enjoyProxies[#enjoyProxies+1] = Def.ActorFrame {
			Name = "P"..playerNumber.."Frame"..string.char(proxyIndex + string.byte("A")),
			InitCommand = function(self)
				self:xy(sw/2, sh/2)
					:visible(false);
			end,
			
			Def.ActorProxy {
				Name = "P"..playerNumber.."Clone"..string.char(proxyIndex + string.byte("A")),
				InitCommand = function(self)
				end,
				OnCommand = function(self)
					McCoy = SCREENMAN:GetTopScreen():GetChild('PlayerP'..playerNumber);
					if McCoy then
						Trace(self:GetName() .. " is alive!!");
						self:SetTarget(McCoy)
							:xy(-McCoy:GetX(), -McCoy:GetY());
					end
				end
			}
		}
	end
end		

for _,ep in pairs(enjoyProxies) do
	table.insert(theBoys, ep);
end



--
-- Judgment proxies
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
		-- Who's the AFT?
		for moniker,starlet in pairs(self:GetParent():GetChildren()) do
			Trace("OwO whats this? "..moniker);
			if string.find(moniker, "enjoyBGTex") then
				Trace("found it!! "..moniker);
				enjoyBGTexReflect = starlet;
				break;
			end
		end
		Trace("we tried...");
		self:queuecommand("Update");
	end,
	UpdateCommand = function(self)
		-- Most things are determined by beat, believe it or not.		
		local overtime = GAMESTATE:GetSongBeat();
		
		-- TODO: this assumes the effect applies over a constant BPM section!!
		local BPS = GAMESTATE:GetSongBPS();
		
		-- take time to smell the rosetations
		local enjoyTheta = overtime * math.pi / 2.0;
		local enjoyRadius = 32.0;
	
		
		-- Who's interesting today?
		if overtime >=  0.0 and fgcurcommand ==  0 then
			-- Hide the actual playfields. Let the proxies do the work.
			for i,v in ipairs(plr) do
				if v then
					v:visible(false)
					 :decelerate(16.0 / BPS):y(sh/2 - 30):z(0);
				end
			end
			
			self:GetParent():GetChild("enjoyBG"):queuecommand("Morph");
			
			fgcurcommand = fgcurcommand + 1;
		end
		if overtime >=  96.0 and fgcurcommand ==  1 then
			-- Start moving players toward the center.
			for i,v in ipairs(plr) do
				if v then
					v:accelerate(28.0 / BPS):x(sw/2);
				end
			end
			
			fgcurcommand = fgcurcommand + 1;
		end
--		if overtime >=  48.0 and fgcurcommand ==  3 then
--			-- boy i die!! shit boy...
--			local enjoyTheta = overtime * math.pi / 2.0;
--			
--			for i,v in ipairs(plr) do
--				if v then					
--					for j,w in ipairs(v:GetChild("NoteField"):GetColumnActors()) do
--						w:diffusealpha(0.5 + 0.5 * math.sin(enjoyTheta + math.pi / 2.0 * j));
--					end
--				end
--			end
--		end
		if overtime >= 126.75 and fgcurcommand ==  2 then
			-- oh shit!!			
			for i,v in ipairs(plr) do
				local sideGuide = (i == 2) and 0.75 or 0.25;
				if v then
					v:visible(false):x(sideGuide * sw);
				end
			end
			
			for i = 1,2 do
				local sideSign = (i == 2) and 1 or -1;
				enjoyBGTexReflect:GetChild("P"..i.."Clone"):visible(false);
				self:GetParent():GetChild("P"..i.."FrameA"):visible(true)
														   :decelerate(0.25 / BPS)
														   :x(sw/2 + enjoyRadius * sideSign);
			end
			
			fgcurcommand = fgcurcommand + 1;
		end
		if overtime >= 128.0  and fgcurcommand ==  3 then			
			-- around and around! shit boy
			for i = 1,2 do
				local sideSign = (i == 2) and 1 or -1;
				self:GetParent():GetChild("P"..i.."FrameA"):x(sw/2 + enjoyRadius * sideSign * math.cos(enjoyTheta));
				self:GetParent():GetChild("P"..i.."FrameA"):z(       enjoyRadius * sideSign * math.sin(enjoyTheta) + enjoyRadius);
			end
			
			if overtime >= 160.0 then
				fgcurcommand = fgcurcommand + 1;
			end
		end
		if overtime >= 160.0  and fgcurcommand ==  4 then			
			-- shit boy! around and around
			for i = 1,2 do
				local sideSign = (i == 2) and 1 or -1;
				self:GetParent():GetChild("P"..i.."FrameA"):x(sw/2 + enjoyRadius * sideSign * math.cos(enjoyTheta));
				self:GetParent():GetChild("P"..i.."FrameA"):z(     - enjoyRadius * sideSign * math.sin(enjoyTheta) + enjoyRadius);
			end
			
			if overtime >= 191.0 then				
				for i = 1,2 do
					local sideSign = (i == 2) and 1 or -1;
					self:GetParent():GetChild("P"..i.."FrameA"):decelerate(1.0 / BPS):xy(sw/2, sh/2 + enjoyRadius * sideSign);
				end
				fgcurcommand = fgcurcommand + 1;
			end
		end
		if overtime >= 192.0  and fgcurcommand ==  5 then			
			-- up and down! shit boy
			for i = 1,2 do
				local sideSign = (i == 2) and 1 or -1;
				self:GetParent():GetChild("P"..i.."FrameA"):y(sh/2 + enjoyRadius * sideSign * math.cos(enjoyTheta));
				self:GetParent():GetChild("P"..i.."FrameA"):z(       enjoyRadius * sideSign * math.sin(enjoyTheta) + enjoyRadius);
			end
			
			if overtime >= 224.0 then
				fgcurcommand = fgcurcommand + 1;
			end
		end
		if overtime >= 224.0  and fgcurcommand ==  6 then			
			-- shit boy! up and down
			for i = 1,2 do
				local sideSign = (i == 2) and 1 or -1;
				self:GetParent():GetChild("P"..i.."FrameA"):y(sh/2 + enjoyRadius * sideSign * math.cos(enjoyTheta)):x(sw/2);
				self:GetParent():GetChild("P"..i.."FrameA"):z(     - enjoyRadius * sideSign * math.sin(enjoyTheta) + enjoyRadius);
			end
			
			if overtime >= 252.0 then				
				for i = 1,2 do
					local sideSign = (i == 2) and 1 or -1;
					self:GetParent():GetChild("P"..i.."FrameA"):decelerate(3.0 / BPS):xy(sw/2, sh/2):z(0);
				end
				fgcurcommand = fgcurcommand + 1;
			end
		end		
		if overtime >= 255.0  and fgcurcommand ==  7 then			
			-- switch to the water again
			for i = 1,2 do
				local sideSign = (i == 2) and 1 or -1;				
									if plr[i] then   plr[i]:finishtweening():x(sw/2); end
				enjoyBGTexReflect:GetChild("P"..i.."Clone"):visible(true);
				self:GetParent():GetChild("P"..i.."FrameA"):visible(false);
			end
			
			fgcurcommand = fgcurcommand + 1;
		end
		if overtime >= 384.0  and fgcurcommand ==  8 then			
			-- YO SKRILL DROP IT HARD
			for i,v in ipairs(plr) do
				local sideGuide = (i == 2) and 0.75 or 0.25;
				if v then
					v:visible(false):x(sideGuide * sw);
				end
			end
			
			for i = 1,2 do
				local proxyNames = {'A', 'B', 'C', 'D'};
				local McCoy = SCREENMAN:GetTopScreen():GetChild('PlayerP'..i);
				local sideSign = (i == 2) and 1 or -1;
				
				for proxyIndex,proxyID in ipairs(proxyNames) do
					local thisProxyFrame = self:GetParent():GetChild("P"..i.."Frame"..proxyID);
					local thisProxyClone = thisProxyFrame:GetChild(  "P"..i.."Clone"..proxyID);
					thisProxyClone:y(-sh * 0.75 - McCoy:GetY());
					thisProxyFrame:visible(true)
								  :xy(sw/2, sh * 1.25 - 30)
								  :baserotationx(180 * (2 * proxyIndex - i) / #proxyNames)
								  :baserotationz(10 * sideSign)
								  :linear(32.0 / BPS)
								  :rotationx(180 * 32 / #proxyNames);
				end
				
				enjoyBGTexReflect:GetChild("P"..i.."Clone"):visible(false);
			end
			
			fgcurcommand = fgcurcommand + 1;
		end
		if overtime >= 416.0  and fgcurcommand ==  9 then			
			-- YO SKROPP DROP IT HROP
			for i = 1,2 do
				local proxyNames = {'A', 'B', 'C', 'D'};
				local sideSign = (i == 2) and 1 or -1;
				for proxyIndex,proxyID in ipairs(proxyNames) do
					local thisProxyFrame = self:GetParent():GetChild("P"..i.."Frame"..proxyID);
					thisProxyFrame:decelerate(32.0 / BPS)
								  :rotationx(180 * 4 / #proxyNames);
				end
			end
			
			fgcurcommand = fgcurcommand + 1;
		end
		if overtime >= 444.0  and fgcurcommand == 10 then			
			-- YR SKRKS DON'T DR THAT ANY MORE
			for i = 1,2 do
				local proxyNames = {'A', 'B', 'C', 'D'};
				local McCoy = SCREENMAN:GetTopScreen():GetChild('PlayerP'..i);
				local sideSign = (i == 2) and 1 or -1;
				for proxyIndex,proxyID in ipairs(proxyNames) do
					local thisProxyFrame = self:GetParent():GetChild("P"..i.."Frame"..proxyID);
					local thisProxyClone = thisProxyFrame:GetChild(  "P"..i.."Clone"..proxyID);
					thisProxyClone:y(-McCoy:GetY());
					thisProxyFrame:y(sh/2 - 30)
								  :baserotationx(0):rotationx(0)
								  :baserotationz(0);				
				end
			end
			
			fgcurcommand = fgcurcommand + 1;
		end
		if overtime >= 448.0  and fgcurcommand == 11 then			
			-- around and around! shit boy
			for i = 1,2 do
				local proxyNames = {'A', 'B', 'C', 'D'};
				for proxyIndex,proxyID in ipairs(proxyNames) do
					local sidePhase = (i * 0.5 - proxyIndex) * math.pi;
					local thisProxyFrame = self:GetParent():GetChild("P"..i.."Frame"..proxyID);
					thisProxyFrame:visible(proxyIndex < 3)
								  :x(sw/2 + enjoyRadius * math.cos(enjoyTheta + sidePhase))
								  :z(       enjoyRadius * math.sin(enjoyTheta + sidePhase) + enjoyRadius);
				end
			end
			
			if overtime >= 480.0 then
				fgcurcommand = fgcurcommand + 1;
			end
		end
		if overtime >= 480.0  and fgcurcommand == 12 then			
			-- shit boy! around and around
			for i = 1,2 do
				local proxyNames = {'A', 'B'};
				for proxyIndex,proxyID in ipairs(proxyNames) do
					local sidePhase = (i * 0.5 - proxyIndex) * math.pi;
					local thisProxyFrame = self:GetParent():GetChild("P"..i.."Frame"..proxyID);
					if overtime >= 511.0 then
						thisProxyFrame:decelerate(1.0 / BPS)
									  :xy(sw/2, sh/2 + enjoyRadius * math.cos(sidePhase));
					else
						thisProxyFrame:x(sw/2 + enjoyRadius * math.cos(enjoyTheta + sidePhase))
									  :z(     - enjoyRadius * math.sin(enjoyTheta + sidePhase) + enjoyRadius);
					end
				end
			end
			
			if overtime >= 511.0 then
				fgcurcommand = fgcurcommand + 1;
			end
		end
		if overtime >= 512.0  and fgcurcommand == 13 then			
			-- up and down! shit boy
			for i = 1,2 do
				local proxyNames = {'A', 'B'};
				for proxyIndex,proxyID in ipairs(proxyNames) do
					local sidePhase = (i * 0.5 - proxyIndex) * math.pi;
					local thisProxyFrame = self:GetParent():GetChild("P"..i.."Frame"..proxyID);
					thisProxyFrame:y(sh/2 + enjoyRadius * math.cos(enjoyTheta + sidePhase))
								  :z(       enjoyRadius * math.sin(enjoyTheta + sidePhase) + enjoyRadius);
				end
			end
			
			if overtime >= 544.0 then
				fgcurcommand = fgcurcommand + 1;
			end
		end
		if overtime >= 544.0  and fgcurcommand == 14 then			
			-- shit boy! up and down
			for i = 1,2 do
				local proxyNames = {'A', 'B'};
				for proxyIndex,proxyID in ipairs(proxyNames) do
					local sidePhase = (i * 0.5 - proxyIndex) * math.pi;
					local thisProxyFrame = self:GetParent():GetChild("P"..i.."Frame"..proxyID);
					if overtime >= 564.0 then
						thisProxyFrame:z(0)
									  :decelerate(4.0 / BPS)
									  :xy(sw * (-0.25 + 0.5 * i), sh/2);
					else
						thisProxyFrame:y(sh/2 + enjoyRadius * math.cos(enjoyTheta + sidePhase))
									  :z(     - enjoyRadius * math.sin(enjoyTheta + sidePhase) + enjoyRadius);
					end
				end
			end
			
			if overtime >= 564.0 then
				fgcurcommand = fgcurcommand + 1;
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
local cspd = 2.2;
local modsTable = {
	-- [1]: beat start
	-- [2]: mod type
	-- [3]: mod strength (out of unity),
	-- [4]: mod approach (in beats to complete)
	-- [5]: player application (1 = P1, 2 = P2, 3 = both, 0 = neither)
		
		{   0.0,	"ScrollSpeed",	 cspd,    2.0,	3}, 
		
		{  64.0,	"Tornado",		 0.5,     4.0,	3}, 
		{  68.0,	"Tornado",		 0.0,     3.0,	3}, 
		{  72.0,	"Tornado",		 0.5,     4.0,	3}, 
		{  76.0,	"Tornado",		 0.0,     3.0,	3}, 
		{  80.0,	"Tornado",		-0.5,     4.0,	3}, 
		{  84.0,	"Tornado",		 0.0,     3.0,	3}, 
		{  88.0,	"Tornado",		 0.5,     3.0,	3}, 
		{  92.0,	"Tornado",		 0.0,     3.0,	3}, 
		
		{  96.0,	"Roll",			 0.5,    28.0,	3},
		
		{ 120.0,	"Flip",			 0.5,     4.0,	3}, 
		{ 120.0,	"Dark",			 1.0,     4.0,	3}, 
		{ 120.0,	"Stealth",		 0.9,     4.0,	3}, 
		 
		{ 124.0,	"Roll",			 0.0,     0.5,	3}, 		
		{ 124.0,	"Dark",			 0.0,     0.25,	3}, 
		{ 125.0,	"Flip",			-0.25,    0.25,	3}, 
		{ 125.0,	"Invert",		 0.75,    0.25,	3}, 
		{ 126.0,	"Invert",		 0.0,     0.25,	3}, 
		{ 126.25,	"Stealth",		 0.0,     0.75,	3}, 
--		{   0.0,	"Sudden",		 1.0,     2.0,	3}, 
--		{   0.0,	"SuddenOffset",	 0.8,     2.0,	3}, 

		{ 248.0,	"Flip",			 0.0,     7.0,	3}, 
		{ 252.0,	"Centered",		 0.5,     3.0,	3}, 
		{ 252.0,	"Hidden",		 0.9,     4.0,	3}, 
		{ 252.0,	"Boost",		-3.0,     4.0,	3}, 
		{ 288.0,	"Centered",		 0.0,    32.0,	3}, 
		{ 288.0,	"Hidden",		 0.0,    32.0,	3}, 
		{ 288.0,	"Boost",		 0.0,    16.0,	3}, 
		
		{ 320.0,	"Tornado",		 0.5,     8.0,	3}, 
		{ 328.0,	"Tornado",		-0.5,     8.0,	3}, 
		{ 336.0,	"Tornado",		 0.5,     8.0,	3}, 
		{ 344.0,	"Tornado",		 0.0,     8.0,	3}, 
				
		{ 352.0,	"Drunk",		-0.5,     0.01,	3}, 
		{ 352.0,	"Split",		 0.1,     0.01,	1}, 
		{ 352.0,	"Split",		-0.1,     0.01,	2}, 
		{ 352.5,	"Drunk",		 0.0,     3.5,	3}, 
		{ 352.5,	"Split",		 0.0,     3.5,	3}, 
				
		{ 356.0,	"Drunk",		 0.5,     0.01,	3}, 
		{ 356.0,	"Alternate",	-0.1,     0.01,	1}, 
		{ 356.0,	"Alternate",	 0.1,     0.01,	2}, 
		{ 356.5,	"Drunk",		 0.0,     3.5,	3}, 
		{ 356.5,	"Alternate",	 0.0,     3.5,	3}, 
				
		{ 360.0,	"Drunk",		-0.5,     0.01,	3}, 
		{ 360.0,	"Alternate",	 0.1,     0.01,	1}, 
		{ 360.0,	"Alternate",	-0.1,     0.01,	2}, 
		{ 360.5,	"Drunk",		 0.0,     1.5,	3}, 
		{ 360.5,	"Alternate",	 0.0,     1.5,	3}, 
				
		{ 362.0,	"Drunk",		 0.5,     0.01,	3}, 
		{ 362.0,	"Split",		-0.1,     0.01,	1}, 
		{ 362.0,	"Split",		 0.1,     0.01,	2}, 
		{ 362.5,	"Drunk",		 0.0,     1.5,	3}, 
		{ 362.5,	"Split",		 0.0,     1.5,	3}, 
				
		{ 364.0,	"Drunk",		-0.5,     0.01,	3}, 
		{ 364.0,	"Split",		 0.1,     0.01,	1}, 
		{ 364.0,	"Split",		-0.1,     0.01,	2}, 
		{ 364.5,	"Drunk",		 0.0,     0.5,	3}, 
		{ 364.5,	"Split",		 0.0,     0.5,	3}, 				
		{ 365.0,	"Drunk",		 0.5,     0.01,	3}, 
		{ 365.0,	"Alternate",	-0.1,     0.01,	1}, 
		{ 365.0,	"Alternate",	 0.1,     0.01,	2}, 
		{ 365.5,	"Drunk",		 0.0,     0.5,	3}, 
		{ 365.5,	"Alternate",	 0.0,     0.5,	3}, 				
		{ 366.0,	"Drunk",		-0.5,     0.01,	3}, 
		{ 366.0,	"Alternate",	 0.1,     0.01,	1}, 
		{ 366.0,	"Alternate",	-0.1,     0.01,	2}, 
		{ 366.5,	"Drunk",		 0.0,     0.5,	3}, 
		{ 366.5,	"Alternate",	 0.0,     0.5,	3}, 				
		{ 367.0,	"Drunk",		 0.5,     0.01,	3}, 
		{ 367.0,	"Split",		-0.1,     0.01,	1}, 
		{ 367.0,	"Split",		 0.1,     0.01,	2}, 
		{ 367.5,	"Drunk",		 0.0,     0.5,	3}, 
		{ 367.5,	"Split",		 0.0,     0.5,	3}, 
		
		{ 368.0,	"Drunk",		-0.3,     0.01,	3}, 
		{ 368.25,	"Drunk",		 0.0,     0.25,	3}, 
		{ 368.5,	"Drunk",		 0.3,     0.01,	3}, 
		{ 368.75,	"Drunk",		 0.0,     0.25,	3}, 
		{ 369.0,	"Drunk",		-0.4,     0.01,	3}, 
		{ 369.25,	"Drunk",		 0.0,     0.25,	3}, 
		{ 369.5,	"Drunk",		 0.4,     0.01,	3}, 
		{ 369.75,	"Drunk",		 0.0,     0.25,	3}, 
		{ 370.0,	"Drunk",		-0.5,     0.01,	3}, 
		{ 370.25,	"Drunk",		 0.0,     0.25,	3}, 
		{ 370.5,	"Drunk",		 0.5,     0.01,	3}, 
		{ 370.75,	"Drunk",		 0.0,     0.25,	3}, 
		{ 371.0,	"Drunk",		-0.6,     0.01,	3}, 
		{ 371.25,	"Drunk",		 0.0,     0.25,	3}, 
		{ 371.5,	"Drunk",		 0.6,     0.01,	3}, 
		{ 371.75,	"Drunk",		 0.0,     0.25,	3}, 
		
		{ 372.0,	"Drunk",		-0.7,     0.01,	3}, 
		{ 372.25,	"Drunk",		 0.0,     0.25,	3}, 
		{ 372.5,	"Drunk",		 0.7,     0.01,	3}, 
		{ 372.75,	"Drunk",		 0.0,     0.25,	3}, 
		{ 373.0,	"Drunk",		-0.8,     0.01,	3}, 
		{ 373.25,	"Drunk",		 0.0,     0.25,	3}, 
		{ 373.5,	"Drunk",		 0.8,     0.01,	3}, 
		{ 373.75,	"Drunk",		 0.0,     0.25,	3}, 
		{ 374.0,	"Drunk",		-0.9,     0.01,	3}, 
		{ 374.25,	"Drunk",		 0.0,     0.25,	3}, 
		{ 374.5,	"Drunk",		 0.9,     0.01,	3}, 
		{ 374.75,	"Drunk",		 0.0,     0.25,	3}, 
		{ 375.0,	"Drunk",		-1.0,     0.01,	3}, 
		{ 375.25,	"Drunk",		 0.0,     0.25,	3}, 
		{ 375.5,	"Drunk",		 1.0,     0.01,	3}, 
		{ 375.75,	"Drunk",		 0.0,     0.25,	3}, 
		
		{ 376.0,	"Split",		-1.0,     1.5,	3}, 
		{ 376.0,	"Reverse",		 1.0,     1.5,	3}, 
		{ 378.0,	"Split",		 0.0,     1.5,	3}, 
		{ 380.0,	"Centered",		 2.0,     2.0,	3}, 
		{ 381.5,	"Reverse",		 0.0,     2.0,	3}, 
		{ 383.0,	"Centered",		 0.0,     1.0,	3}, 
		{ 383.0,	"Sudden",		 1.0,     2.0,	3}, 
		{ 383.0,	"SuddenOffset",	 1.0,     2.0,	3}, 
		
		{ 398.0,	"Drunk",		 0.5,     0.25,	1}, 
		{ 398.0,	"Drunk",		-0.5,     0.25,	2}, 
		{ 398.5,	"Drunk",		-0.5,     0.25,	1}, 
		{ 398.5,	"Drunk",		 0.5,     0.25,	2}, 
		{ 399.0,	"Drunk",		 0.5,     0.25,	1}, 
		{ 399.0,	"Drunk",		-0.5,     0.25,	2}, 
		{ 399.5,	"Drunk",		-0.5,     0.25,	1}, 
		{ 399.5,	"Drunk",		 0.5,     0.25,	2}, 
		{ 400.0,	"Drunk",		 0.0,     0.25,	3}, 
				 
		{ 412.0,	"Dizzy",		-0.8,     0.25,	1}, 
		{ 412.0,	"Dizzy",		 0.8,     0.25,	2}, 
		{ 414.0,	"Dizzy",		 0.8,     0.25,	1}, 
		{ 414.0,	"Dizzy",		-0.8,     0.25,	2}, 
		{ 415.0,	"Dizzy",		 0.0,     1.0,	3}, 
					
		{ 432.0,	"Sudden",		 0.0,     8.0,	3}, 
		{ 432.0,	"SuddenOffset",	 0.0,     8.0,	3}, 
		{ 440.0,	"Flip",			 0.25,    4.0,	3}, 
		{ 440.0,	"Invert",		 0.25,    4.0,	3}, 
		{ 445.0,	"Flip",			-0.25,    0.25,	3}, 
		{ 445.0,	"Invert",		 0.75,    0.25,	3}, 
		{ 446.0,	"Invert",		 0.0,     0.4,	3}, 
		
		{ 448.0,	"Drunk",		 0.7,    32.0,	1}, 
		{ 448.0,	"Drunk",		-0.7,    32.0,	2}, 
		
		{ 512.0,	"Wave",			 0.5,    32.0,	3}, 
		{ 512.0,	"Drunk",		 0.0,    32.0,	3}, 

		{ 564.0,	"Wave",			 0.0,     4.0,	3}, 
		{ 564.0,	"Flip",			 0.0,     4.0,	3}, 
		
		
		{ 576.0,	"Tornado",		-3.0,     3.0,	1}, 
		{ 576.0,	"Tornado",		 3.0,     3.0,	2}, 
		{ 576.0,	"Bumpy",		 3.0,     3.0,	3}, 
		{ 576.0,	"Boost",		 3.0,     3.0,	3}, 
		
		
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

local COVENANT_VENTHYR = 2;
local CURRENCY_INFUSED_RUBY = 1820;
local ITEM_REPAIR_KIT = 181363;
local MAP_REVENDRETH = 1525;

local mirrorGroups = { 61879, 61883, 61885, 61886 };

local armorTypes = { "Cloth", "Leather", "Mail", "Plate" };

local travelNetworkSets = {
    ["Cloth"] = 2064, -- Soulbreaker's Burnished Vestments
    ["Leather"] = 2069, -- Burnished Death Shroud Armor
    ["Mail"] = 2073, -- Fearstalker's Burnished Battlegear
    ["Plate"] = 2076 -- Dread Sentinel's Burnished Battleplate
};

local mirrorsByGroup = {
    [1] = {
        { label = "Cliff North of Sinfall", group = 1, hint = "Inside a room with a cooking pot on the north wall.", x = 0.2949, y = 0.3726 },
        { label = "Dominance Keep", group = 1, hint = "Inside a room with spiders; enter from the south.", x = 0.2715, y = 0.2163 },
        { label = "Dredhollow", group = 1, hint = "Inside a building with sleeping wildlife.", x = 0.4041, y = 0.7334 }
    },
    [2] = {
        { label = "Charred Ramparts", group = 2, hint = "At ground level.", x = 0.3909, y = 0.5218 },
        { label = "Stonevigil Overlook", group = 2, hint = "In the building with the burning stagecoach in front.", x = 0.5880, y = 0.6780 },
        { label = "Halls of Atonement", group = 2, hint = "In a room with a Depraved Tutor and dredgers.", x = 0.7097, y = 0.4363 }
    },
    [3] = {
        { label = "Halls of Atonement", group = 3, hint = "At the bottom of the crypt in the room on the right.", x = 0.7258, y = 0.4365 },
        { label = "Dredhollow", group = 3, hint = "Inside the house with the wildlife fighting.", x = 0.4030, y = 0.7716 },
        { label = "Caretaker's Manor", group = 3, hint = "Inside the building with the elite mobs.", x = 0.7717, y = 0.6545 }
    },
    [4] = {
        { label = "Dominance Keep", group = 4, hint = "In a room with a Dominance Soulbender.", x = 0.2960, y = 0.2589 },
        { label = "The Shrouded Asylum", group = 4, hint = "Just inside the entrance of the large building, on the right.", x = 0.2075, y = 0.5426 },
        { label = "Redelav District", group = 4, hint = "At the bottom of the crypt in the room on the left.", x = 0.5512, y = 0.3567 }
    }
};

function GetActiveMirrorGroup()
    local covenantID = C_Covenants.GetActiveCovenantID();
    if covenantID ~= COVENANT_VENTHYR then
        return nil;
    end

    for groupNumber, questID in pairs(mirrorGroups) do
        C_QuestLog.RemoveWorldQuestWatch(questID);
        local available = C_QuestLog.AddWorldQuestWatch(questID);
        C_QuestLog.RemoveWorldQuestWatch(questID);
        local completed = C_QuestLog.IsQuestFlaggedCompleted(questID);
        
        if available or completed then
            return groupNumber;
        end
    end

    return nil;
end

local function AddTomTomWaypoint(button, mapID, title, x, y)
	if TomTom then
		TomTom:AddWaypoint(mapID, x, y, {
			title = title,
			persistent = nil,
			minimap = true,
			world = true,
            from = "Broken Mirrors"
		});
	end
end

BrokenMirrorsMapDataProviderMixin = CreateFromMixins(MapCanvasDataProviderMixin);

function BrokenMirrorsMapDataProviderMixin:OnEvent(event, ...)
	self:RefreshAllData();
end

function BrokenMirrorsMapDataProviderMixin:RemoveAllData()
    self:GetMap():RemoveAllPinsByTemplate("BrokenMirrorsPinTemplate");
end

function BrokenMirrorsMapDataProviderMixin:RefreshAllData(fromOnShow)
    self:RemoveAllData();
    
    local mapID = self:GetMap():GetMapID();

    if not mapID or mapID ~= MAP_REVENDRETH then
        return;
    end
    
    local activeMirrorGroup = GetActiveMirrorGroup();

    if not activeMirrorGroup then
        return;
    end

    local mirrors = mirrorsByGroup[activeMirrorGroup];
    if mirrors then
        for _, mirror in ipairs(mirrors) do
            local pin = self:GetMap():AcquirePin("BrokenMirrorsPinTemplate", mirror);
            pin.dataProvider = self;
            pin:SetPosition(mirror.x, mirror.y);
        end
    end
end

BrokenMirrorsPinMixin = CreateFromMixins(MapCanvasPinMixin);

function BrokenMirrorsPinMixin:OnLoad()
    self:SetScalingLimits(1, 0.7, 1.3);
    self:UseFrameLevelType("PIN_FRAME_LEVEL_NEIGHBORHOOD_MAP_OBJECTS");
end

function BrokenMirrorsPinMixin:OnAcquired(mirror)
    self.mirror = mirror;
end

function BrokenMirrorsPinMixin:OnMouseEnter()
    local x, y = self:GetCenter();
	local parentX, parentY = self:GetParent():GetCenter();
	if (x > parentX) then
		GameTooltip:SetOwner(self, "ANCHOR_LEFT");
	else
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	end

    GameTooltip:SetText(self.mirror.label, 1, 1, 1, true);
    GameTooltip:AddLine("Broken Mirror - Group "..self.mirror.group, 0, 1, 0, true);
    GameTooltip:AddLine(self.mirror.hint);
    GameTooltip:AddLine(" ");

    for i, armorType in ipairs(armorTypes) do
        local setID = travelNetworkSets[armorType];
        local appearances = C_TransmogSets.GetSetPrimaryAppearances(setID);

        if appearances then
            local numCollected = 0;
            local numTotal = 0;
            
            for _, v in ipairs(appearances) do
                if v.collected then
                    numCollected = numCollected + 1;
                end
                numTotal = numTotal + 1;
            end
            
            if numCollected >= numTotal then
                GameTooltip:AddDoubleLine(armorType, numTotal.."/"..numTotal, 0, 1, 0, 0, 1, 0);
            else
                allCollected = false;
                GameTooltip:AddDoubleLine(armorType, numCollected.."/"..numTotal, 1, 1, 1, 1, 1, 1);
            end
        end
    end

    local rubies = C_CurrencyInfo.GetCurrencyInfo(CURRENCY_INFUSED_RUBY);
    GameTooltip:AddLine(" ");

    local repairKits = 0;
    for containerIndex = 0, 4 do
        local slotCount = C_Container.GetContainerNumSlots(containerIndex);
        for slotIndex = 1, slotCount do
            local bagItem = C_Container.GetContainerItemInfo(containerIndex, slotIndex);
            if bagItem then
                if bagItem.itemID == ITEM_REPAIR_KIT then
                    repairKits = repairKits + bagItem.stackCount;
                end
            end
        end
    end

    local colorRGBR, colorRGBG, colorRGBB, qualityString = C_Item.GetItemQualityColor(Enum.ItemQuality.Rare);

    if repairKits < 3 then
        GameTooltip:AddDoubleLine(
            "Handcrafted Mirror Repair Kit",
            repairKits,
            colorRGBR, colorRGBG, colorRGBB,
            1, 0, 0
        );
    else
        GameTooltip:AddDoubleLine(
            "Handcrafted Mirror Repair Kit",
            repairKits,
            colorRGBR, colorRGBG, colorRGBB,
            1, 1, 1
        );
    end

    if rubies.quantity < 30 then
        GameTooltip:AddDoubleLine(rubies.name, rubies.quantity.."/"..rubies.maxQuantity, 1, 1, 1, 1, 0, 0);
    else
        GameTooltip:AddDoubleLine(rubies.name, rubies.quantity.."/"..rubies.maxQuantity, 1, 1, 1, 1, 1, 1);
    end
	
    GameTooltip:Show();
end

function BrokenMirrorsPinMixin:OnMouseLeave()
    GameTooltip:Hide();
end

function BrokenMirrorsPinMixin:OnMouseClickAction(button)
    AddTomTomWaypoint(
        button,
        MAP_REVENDRETH,
        self.mirror.label,
        self.mirror.x,
        self.mirror.y
    );
end

WorldMapFrame:AddDataProvider(BrokenMirrorsMapDataProviderMixin);

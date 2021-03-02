EasyDestroy = EasyDestroy

local frame = CreateFrame("Frame", "ED_Blacklist", InterfaceOptionsFramePanelContainer)
local needsUpdate = false
frame.name = "Blacklist"
frame.parent = EasyDestroy.AddonName
frame:Hide()

-- On Load do Mixin of item frames 

-- Item Template Frame should have fields:
-- .link, .ilvl, .name, .quality
-- I think the end goal will be to match on 1) Item ID 2) Item Quality and 3) Item Level.
-- That means we'll need to save all 3 of those values in the blacklist.
local function ItemInBlacklist(itemid, itemname, quality, ilvl)
    for k, v in ipairs(EasyDestroy.Data.Blacklist) do
        if v and v.itemid and v.itemid == itemid then
            if v.legendary and v.legendary == itemname then
                return true
            elseif not v.legendary and v.quality==quality and v.ilvl == ilvl then
                return true
            end
        end
    end
    return false
end

local function GetItemsInBags()
    local itemList = {}

    for i, item in ipairs(EasyDestroy.GetBagItems()) do
		local matchfound = nil
		local typematch = false

        if item:GetStaticBackingItem() then
            item.location = item:GetItemLocation()

            while (true) do

                for k, v in ipairs(ED_ACTION_FILTERS[ED_ACTION_DISENCHANT]) do
					if v.itype == item.classID then
						if not v.stype then
							typematch = true
						elseif v.stype == item.subclassID then
							typematch = true
						end
					end
				end

                if not typematch then
                    break
                elseif item.classID == LE_ITEM_CLASS_ARMOR and item.subclassID == LE_ITEM_ARMOR_COSMETIC then
                    break
                elseif ItemInBlacklist(item.itemID, item:GetItemName(), item.quality, item.level) then
                    break
                elseif tContains(ED_DEFAULT_BLACKLIST, item.id) then
                    break
                end
                tinsert(itemList, item)
                break
            end
        end
    end

    return itemList
end

local function GetItemsInBlacklist()
    --[[
        blacklists will be saved as a list of item id's.
        To show the item in the frame, we'll need to get the items link from GetItemInfo to get the ID.
    ]]
    local itemList = {}
    local blacklist = EasyDestroy.Data.Blacklist or {}
    -- sort blacklists by item name (or legendary name if available) and then ilvl
    for k, item in EasyDestroy.spairs(blacklist, function(t,a,b) 
        return ( (t[a].legendary or t[a].name) == (t[b].legendary or t[b].name) and t[a].ilvl < t[b].ilvl) or 
        ((t[a].legendary or t[a].name) < (t[b].legendary or t[b].name ) ) end) do
    --for k, item in pairs(blacklist) do
        local a = EasyDestroyItem:New(nil, nil, item.link)
        a.quality = a.quality or item.quality
        a.level = a.level or item.ilvl
        a.itemID = a.itemID or item.itemid
        a.name = a.name or item.name
        --a.itemid, a.itemname, a.itemlink, a.itemqual, a.ilvl = item.itemid, item.name, item.link, item.quality, item.ilvl
        --a.itemid, a.itemname, a.itemlink, a.itemqual = item.itemid, GetItemInfo(item.itemid)
        -- Overwrite with the quality level of the item we added.

        -- if item and item.legendary then
        --     a.itemname = item.legendary
        --     a.itemqual = 5 --legendary``````````````````````````
        -- end

        tinsert(itemList, a)
    end

    --table.sort(itemList, function(a, b) return (a.itemname==b.itemname and a.ilvl<b.ilvl) or (a.ilvl<b.ilvl) end)
    return itemList
end

local function OnClickBagItem(self, button)

    if button ~= "LeftButton" then return end

    -- tinsert(EasyDestroy.Data.Blacklist, self.item:ToTable())

    EasyDestroy.API.Blacklist.AddItem(self.item)

    needsUpdate = true

end

local function OnClickBlacklistItem(self, button)

    if button ~= "LeftButton" then return end

    EasyDestroy.Debug("Remove Item From Blacklist", self.item:GetItemName(), self.item.itemID)

    EasyDestroy.API.Blacklist.RemoveItem(self.item)

end

local function OnFrameShow()
    local leftframe = CreateFrame("Frame", nil, frame)
    leftframe:SetHeight(248)
    leftframe:SetPoint("LEFT", frame, 16, 0)
    leftframe:SetPoint("RIGHT", frame, -24, 0)
    leftframe:SetPoint("TOP", frame, 0, -20)
    leftframe:SetPoint("BOTTOM", frame, "CENTER", 0, 16)
    local bagitems = leftframe:CreateFontString(leftframe, "OVERLAY", "GameFontHighlight")
    bagitems:SetPoint("BOTTOMLEFT", leftframe, "TOPLEFT", -4, 0)
    bagitems:SetText("Items in Bag:")
    local bihelp = leftframe:CreateFontString(leftframe, "OVERLAY", "GameFontHighlight")
    bihelp:SetPoint("BOTTOMRIGHT", leftframe, "TOPRIGHT", 4, 0)
    bihelp:SetText("To add/remove items from the Items Backlist, just click the item in the windows below.")
    -- EasyDestroy:CreateBG(leftframe, 0, 1, 0)

    local rightframe = CreateFrame("Frame", nil, frame)
    rightframe:SetHeight(248)
    rightframe:SetPoint("LEFT", frame, 16, 0)
    rightframe:SetPoint("RIGHT", frame, -24, 0)
    rightframe:SetPoint("TOP", frame, "CENTER", 0, -16)
    rightframe:SetPoint("BOTTOM", frame, 0, 20)
    local blitems = rightframe:CreateFontString(rightframe, "OVERLAY", "GameFontHighlight")
    blitems:SetPoint("BOTTOMLEFT", rightframe, "TOPLEFT", -4, 0)
    blitems:SetText("Items in Blacklist:")
    local blwarn = rightframe:CreateFontString(rightframe, "OVERLAY", "GameFontHighlight")
    blwarn:SetPoint("BOTTOMRIGHT", rightframe, "TOPRIGHT", 4, 0)
    blwarn:SetText("NOTE: This blacklist does not list items filtered by 'blacklist' type filters.")
    -- EasyDestroy:CreateBG(rightframe, 0, 0, 1)

    local itemsInBags = CreateFrame("Frame", "EDBLBagItems", leftframe, "EasyDestroyItemScrollTemplate")
    itemsInBags:Show()
    itemsInBags:Initialize(GetItemsInBags, 10, 24, OnClickBagItem)
    frame.itemsInBags = itemsInBags

    local itemsInBlacklist = CreateFrame("Frame", "EDBLBlacklistItems", rightframe, "EasyDestroyItemScrollTemplate")
    itemsInBlacklist:Show()
    itemsInBlacklist:Initialize(GetItemsInBlacklist, 10, 24, OnClickBlacklistItem)
    frame.itemsInBlacklist = itemsInBlacklist

    itemsInBags.ScrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        itemsInBags:OnVerticalScroll(offset)
    end)

    itemsInBlacklist.ScrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        itemsInBlacklist:OnVerticalScroll(offset)
    end)

    itemsInBags:ScrollUpdate()
    itemsInBlacklist:ScrollUpdate()

    frame:SetScript("OnUpdate", function()
        if needsUpdate == true then 
            -- itemsInBags.UpdateItemList = true
            -- itemsInBags:ScrollUpdate()

            -- itemsInBlacklist.UpdateItemList = true
            -- itemsInBlacklist:ScrollUpdate()
            EasyDestroy.UI.UpdateBlacklistWindow()
            needsUpdate = false
        end
    end)

    -- Only run this code the very first time we show the frame
    frame:SetScript("OnShow", nil)
end

function EasyDestroy.UI.UpdateBlacklistWindow()
    local itemsInBags = _G['EDBLBagItems']
    if itemsInBags then
        itemsInBags.UpdateItemList = true
        itemsInBags:ScrollUpdate()
    end

    local itemsInBlacklist = _G['EDBLBlacklistItems']
    if itemsInBlacklist then
        itemsInBlacklist.UpdateItemList = true
        itemsInBlacklist:ScrollUpdate()
    end

end

frame:SetScript("OnShow", OnFrameShow)

EasyDestroy.ItemInBlacklist = ItemInBlacklist
InterfaceOptions_AddCategory(frame)

EasyDestroy_OpenBlacklist:SetScript("OnClick", function()
    InterfaceOptionsFrame_OpenToCategory(frame)
    InterfaceOptionsFrame_OpenToCategory(frame)
end)
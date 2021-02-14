EasyDestroy = EasyDestroy
local addonName, addonSpace = ...

local frame = CreateFrame("Frame", "ED_Blacklist", InterfaceOptionsFramePanelContainer)
local needsUpdate = false
frame.name = EasyDestroy.AddonName
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
    local item = {}
    for bag = 0, NUM_BAG_SLOTS do
        for slot=1, GetContainerNumSlots(bag) do
            wipe(item)
            item.link = select(7, GetContainerItemInfo(bag, slot));
			if item.link then 
				item.name, _, item.quality, item.level, _, item._type, item._subtype, item.stack, item.slot, item.icon, item.price, item.type, item.subtype = GetItemInfo(item.link);
                item.id = GetContainerItemID(bag, slot);
                item.iskeystone = C_Item.IsItemKeystoneByID(item.id)
                item.location = ItemLocation:CreateFromBagAndSlot(bag, slot)
                item.ilvl = select(1, GetDetailedItemLevelInfo(item.link))
                if not item.name and not item.iskeystone then -- Because unlike Jim Croce, Mythic Keystones do not, in fact, have a name.
                    item.name = "Blizzard Didn't Name This Item"
                elseif item.iskeystone then
                    item.name = "Keystone"
                end

                -- Default Item Filter: Only include armor/weapons
                local typematch = false
                for k, v in ipairs(EasyDestroy.DestroyFilters[EasyDestroy.DestroyAction]) do
                    if v.itype == item.type then
                        if not v.stype then
                            typematch = true
                        elseif v.stype == item.subtype then
                            typematch = true
                        end
                    end
                end

                -- because LUA sucks in some regards and I don't want to have the worlds longest if statement,
                -- this little "hack" allows the break statements in the loop to more or less act as a "continue"
                -- by ending the "loop" early if an item fails a check. If an item passes all the checks then
                -- the "loop" ends anyways.
                local passCheck = true
                while(true) do
                    if not typematch then
                        passCheck = false
                        break
                    elseif item.type == LE_ITEM_CLASS_ARMOR and item.subtype == LE_ITEM_ARMOR_COSMETIC then
                        passCheck = false
                        break
                    elseif ItemInBlacklist(item.id, item.name, item.quality, item.ilvl) then
                        passCheck = false
                        break
                    elseif tContains(ED_DEFAULT_BLACKLIST, item.id) then
                        passCheck = false
                        break
                    end
                    break
                end

                -- data.itemlink, data.itemname, data.itemqual, (data.ilvl or nil)
                if passCheck then
                    tinsert(itemList, {bag=bag, slot=slot, itemlink=item.link, itemname=item.name, itemqual=item.quality, itemloc=item.location, ilvl=item.ilvl})
				end
                
                -- Eventually will need to filter out items already on the blacklist
                --tinsert(itemList, {itemkey=itemkey, bag=bag, slot=slot, itemlink=item.link, itemname=item.name, itemloc=item.location})
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
        local a = {}
        a.itemid, a.itemname, a.itemlink, a.itemqual, a.ilvl = item.itemid, item.name, item.link, item.quality, item.ilvl
        --a.itemid, a.itemname, a.itemlink, a.itemqual = item.itemid, GetItemInfo(item.itemid)
        -- Overwrite with the quality level of the item we added.

        if item and item.legendary then
            a.itemname = item.legendary
            a.itemqual = 5 --legendary
        end

        tinsert(itemList, a)
    end

    --table.sort(itemList, function(a, b) return (a.itemname==b.itemname and a.ilvl<b.ilvl) or (a.ilvl<b.ilvl) end)
    return itemList
end

local function isItemShadowlandsLegendary(itemstring)
    local splitLink = {strsplit(':', itemstring)}
    local bonusIDCount = splitLink[14]
    if bonusIDCount and tonumber(bonusIDCount) and tonumber(bonusIDCount) > 0 then
        for i=15, 15 + bonusIDCount do
            for k, v in ipairs(ED_LEGENDARY_IDS) do
                if v and v.name and v.bonus_id then
                    if splitLink[i] and tonumber(splitLink[i]) and v.bonus_id == tonumber(splitLink[i]) then
                        return v.name
                    end
                end
            end
        end
    end
    return nil
end

local function OnClickBagItem(self)
    local itemid = GetContainerItemID(self.info.bag, self.info.slot);
    print("Add Item to Blacklist", self.info.itemname, itemid)
    local tbl = {}
    local legendary = isItemShadowlandsLegendary(self.info.itemlink)
    tbl.itemid = itemid
    tbl.legendary = legendary
    tbl.quality = C_Item.GetItemQuality(self.info.itemloc)
    tbl.ilvl = GetDetailedItemLevelInfo(self.info.itemlink)
    tbl.link = self.info.itemlink
    tbl.name = self.info.itemname
    tinsert(EasyDestroy.Data.Blacklist, tbl)
    needsUpdate = true
    EasyDestroy.FilterChanged = true
end

local function OnClickBlacklistItem(self)
    print("Remove Item From Blacklist", self.info.itemname, self.info.itemid)
    for k, v in ipairs(EasyDestroy.Data.Blacklist) do
        -- if regular item, match on itemid, quality, ilvl
        -- if legendary item, match on itemid and name
        if v and ((v.itemid == self.info.itemid and v.quality == self.info.itemqual and v.ilvl == self.info.ilvl) or (v.legendary and v.itemid==self.info.itemid and v.legendary==self.info.itemname)) then
            tremove(EasyDestroy.Data.Blacklist, k)
            needsUpdate = true
            EasyDestroy.FilterChanged = true
        end
    end
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
            itemsInBags.UpdateItemList = true
            itemsInBags:ScrollUpdate()

            itemsInBlacklist.UpdateItemList = true
            itemsInBlacklist:ScrollUpdate()
            needsUpdate = false
        end
    end)

    -- Only run this code the very first time we show the frame
    frame:SetScript("OnShow", nil)
end

frame:SetScript("OnShow", OnFrameShow)

EasyDestroy.ItemInBlacklist = ItemInBlacklist
InterfaceOptions_AddCategory(frame)

EasyDestroy_OpenBlacklist:SetScript("OnClick", function()
    InterfaceOptionsFrame_OpenToCategory(EasyDestroy.AddonName)
    InterfaceOptionsFrame_OpenToCategory(EasyDestroy.AddonName)
end)
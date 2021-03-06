EasyDestroy.UI.Blacklist = {}

local frame = CreateFrame("Frame", "ED_Blacklist", InterfaceOptionsFramePanelContainer)
frame.name = "Blacklist"
frame.parent = EasyDestroy.AddonName
frame:Hide()

local protected = {}

function EasyDestroy.UI.Blacklist.__init()

    frame:SetScript("OnShow", protected.OnFrameShow)

    InterfaceOptions_AddCategory(frame)
    
    EasyDestroy_OpenBlacklist:SetScript("OnClick", function()
        InterfaceOptionsFrame_OpenToCategory(frame)
        InterfaceOptionsFrame_OpenToCategory(frame)
    end)

end

function protected.GetItemsInBags()
    local itemList = {}

    for i, item in ipairs(EasyDestroy.Inventory.GetInventory()) do
		local matchfound = nil
		local typematch = false

        if item:GetStaticBackingItem() then
            item.location = item:GetItemLocation()

            while (true) do

                for k, v in ipairs(EasyDestroy.Config.ItemTypeFilterByFlags(EasyDestroy.Data.Options.Actions)) do
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
                elseif EasyDestroy.Blacklist.HasItem(item) then
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

function protected.GetItemsInBlacklist()
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

        local a = EasyDestroyItem:New(nil, nil, item.link)
        a.quality = a.quality or item.quality
        a.level = a.level or item.ilvl
        a.itemID = a.itemID or item.itemid
        a.name = a.name or item.name

        tinsert(itemList, a)
    end

    return itemList
end

function protected.OnClickBagItem(self, button)

    if button ~= "LeftButton" then return end

    EasyDestroy.Blacklist.AddItem(self.item)

end

function protected.OnClickBlacklistItem(self, button)

    if button ~= "LeftButton" then return end

    EasyDestroy.Debug("Remove Item From Blacklist", self.item:GetItemName(), self.item.itemID)

    EasyDestroy.Blacklist.RemoveItem(self.item)

end

function protected.OnFrameShow()
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

    local itemsInBags = CreateFrame("Frame", "EDBLBagItems", leftframe, "EasyDestroyItemScrollTemplate")
    itemsInBags:Show()
    itemsInBags:Initialize(protected.GetItemsInBags, 10, 24, protected.OnClickBagItem)
    frame.itemsInBags = itemsInBags

    local itemsInBlacklist = CreateFrame("Frame", "EDBLBlacklistItems", rightframe, "EasyDestroyItemScrollTemplate")
    itemsInBlacklist:Show()
    itemsInBlacklist:Initialize(protected.GetItemsInBlacklist, 10, 24, protected.OnClickBlacklistItem)
    frame.itemsInBlacklist = itemsInBlacklist

    itemsInBags.ScrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        itemsInBags:OnVerticalScroll(offset)
    end)

    itemsInBlacklist.ScrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        itemsInBlacklist:OnVerticalScroll(offset)
    end)

    -- First time we show we need to get the item lists
    itemsInBags:ItemListUpdate()
    itemsInBlacklist:ItemListUpdate()

    -- Update the frames
    itemsInBags:ScrollUpdate()
    itemsInBlacklist:ScrollUpdate()

    EasyDestroy.RegisterCallback(frame, "ED_BLACKLIST_UPDATED", function()
        itemsInBags:ItemListUpdate()
        itemsInBags:ScrollUpdate()
        itemsInBlacklist:ItemListUpdate()
        itemsInBlacklist:ScrollUpdate()
    end)

    EasyDestroy.RegisterCallback(frame, "ED_INVENTORY_UPDATED_DELAYED", function()
        itemsInBags:ItemListUpdate()
        itemsInBags:ScrollUpdate()
    end)

    -- Only run this code the very first time we show the frame
    frame:SetScript("OnShow", nil)
end

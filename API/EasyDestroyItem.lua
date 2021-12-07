-- ######################################################################
-- # ITEMS CLASS SO I DON'T HAVE SO MUCH RANDOM BULLSHIT EVERYWHERE     #
-- # Items should have "base" information and they should have filter   #
-- # information. 
-- ######################################################################

EasyDestroyItem = {}
EasyDestroyItem.__index = EasyDestroyItem
function EasyDestroyItem:_NewFromLink(link)

    -- private function to handle caching of new items from links
    
    local cache = EasyDestroyItem.EasyDestroyCacheID(0, 0, link)

    if cache and EasyDestroy.Cache.ItemCache[cache] then
        return EasyDestroy.Cache.ItemCache[cache]
    else
        return Item:CreateFromItemLink(link)
    end

end

function EasyDestroyItem:_NewFromBagAndSlot(bag, slot)

    -- private function to handle caching of new items from bags/slots

    local ilink = select(7, GetContainerItemInfo(bag, slot))
    local cache = EasyDestroyItem.EasyDestroyCacheID(bag, slot, ilink)

    if cache and EasyDestroy.Cache.ItemCache[cache] then
        return EasyDestroy.Cache.ItemCache[cache]
    else
        return Item:CreateFromBagAndSlot(bag, slot)
    end

end

function EasyDestroyItem:New(bag, slot, link)

    local self
    
    if (bag == nil or slot == nil) and link then
        self = EasyDestroyItem:_NewFromLink(link)
    else
        self = EasyDestroyItem:_NewFromBagAndSlot(bag, slot)
    end

    setmetatable(self, EasyDestroyItem)

    self.bag = bag or 0
    self.slot = slot or 0

    --[[ The cake is a lie. Nothing to do here. ]]
    if self:IsItemEmpty() then
        return nil
    end

    local itemLoc = ItemLocation:CreateFromBagAndSlot(self.bag, self.slot)

    self.itemLink = self:GetItemLink()
    self.itemID = self:GetItemID()
    self.level = self:GetCurrentItemLevel()
    self.quality = self:GetItemQuality()
    self.isKeystone = C_Item.IsItemKeystoneByID(self.itemID or self.itemLink)
    self.classID, self.subclassID, self.bindtype, self.expansion = select(12, GetItemInfo(self:GetItemLink()))
    self.name = self:GetItemName()
    self.soulbound = C_Item.IsBound(itemLoc)
    self.count = 1

    self.maxStackSize  = select(8, GetItemInfo(self:GetItemLink()))

    EasyDestroy.Cache.ItemCache[EasyDestroyItem.EasyDestroyCacheID(self.bag, self.slot, self.itemLink)] = self
    return self
end

function EasyDestroyItem:Update(bag, slot)
    self.bag = bag
    self.slot = slot
    if bag ~= nil or slot ~= nil then
        self.itemLocation = ItemLocation:CreateFromBagAndSlot(bag, slot)
    end

end

function EasyDestroyItem:SetValueByKey(key, value)
    self[key] = value
end

function EasyDestroyItem:HaveTransmog()
	local appearance = C_TransmogCollection.GetItemInfo(self.itemLink);
	if appearance then 
		local sources = C_TransmogCollection.GetAppearanceSources(appearance);
		if sources then
			for k, v in pairs(sources) do
				if v.isCollected then
					return true
				end
			end
		end
	end
	return false
end

function EasyDestroyItem:IsItemShadowlandsLegendary()
    local splitLink = {strsplit(':', self.itemLink)}
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

function EasyDestroyItem:ToTable()

    return {
        itemid = self.itemID,
        legendary = self:IsItemShadowlandsLegendary(),
        quality = self.quality,
        ilvl = self.level,
        link = self.itemLink,
        name = self:GetItemName()
    }

end

-- static method
function EasyDestroyItem.EasyDestroyCacheID(bag, slot, link)
	
	-- Create Cache ID from bag, slot, quality, and item link

	if type(bag) ~= "number" or type(slot) ~= "number" or type(link) ~= "string" then 
		error(
			string.format("Usage: EasyDestroy.EasyDestroyCacheID(bag, slot, itemLink)\n (%s, %s, %s)", bag or "nil", slot or "nil", link or "nil")
		)
	end
	return string.format("%i:%i:%s", bag, slot, link)

end
--[[ 

    Classes used by the addon to homogenize access to various data structures.
    Namely Filters, FilterCriteria, and Items.

]]

EasyDestroyFilterCriteria = {}
EasyDestroyFilterCriteria.__index = EasyDestroyFilterCriteria

function EasyDestroyFilterCriteria:New(name, key, height)
    local self = {}
    setmetatable(self, EasyDestroyFilterCriteria)
    self.name = name
    self.key = key
    self.height = height
    self.parent = _G[EDFILTER_SCROLL_CHILD]
    self.frame = nil
    self.scripts = {}

    return self
end

function EasyDestroyFilterCriteria:GetName()
    if self.name and self.name ~= nil and self.name ~= "" and type(self.name) == "string" then
        return self.name
    else
        error("Unable to get filter name")
    end
end

function EasyDestroyFilterCriteria:GetFilterFrame()

    return self.frame

end

function EasyDestroyFilterCriteria:GetKey()
    if self.key and self.key ~= nil then
        return self.key
    else
        error("No key found for filter " .. self:GetName())
    end
end

function EasyDestroyFilterCriteria:IsShown()
    if self.frame then
        return self.frame:IsShown()
    end
    return false
end

function EasyDestroyFilterCriteria:Toggle()
    if not self.frame then
        error("Unable to toggle filter frame. Not yet created. " .. self:GetName())
    end

    if self.frame:IsShown() then
        self.frame:Hide()
    else
        self.frame:Show()
    end
end

--[[ abstract functions ]]
function EasyDestroyFilterCriteria:Check()
    error("Filter " .. self.GetName() .. " does not yet have a Check function implemented.")
end

function EasyDestroyFilterCriteria:GetValues()
    error("Filter " .. self.GetName() .. " does not yet have a Getvalues function implemented.")
end

function EasyDestroyFilterCriteria:SetValues()
    error("Filter " .. self.GetName() .. " does not yet have a SetValues function implemented.")
end

function EasyDestroyFilterCriteria:Clear()
    error("Filter " .. self.GetName() .. " does not yet have a Clear function implemented.")
end


-- ######################################################################
-- # ITEMS CLASS SO I DON'T HAVE SO MUCH RANDOM BULLSHIT EVERYWHERE     #
-- # Items should have "base" information and they should have filter   #
-- # information. 
-- ######################################################################
EasyDestroyItem = {}
EasyDestroyItem.__index = EasyDestroyItem

function EasyDestroyItem:New(bag, slot, link, itemid)

    local self
    if (bag == nil or slot == nil) and link then
        self = Item:CreateFromItemLink(link)
    elseif (bag == nil or slot == nil) and itemid then 
        self = Item:CreateFromItemID(itemid)
    else
        self = Item:CreateFromBagAndSlot(bag, slot)
    end
    setmetatable(self, EasyDestroyItem)

    self.bag = bag
    self.slot = slot

    --[[ The cake is a lie. Nothing to do here. ]]
    if self:IsItemEmpty() then
        return nil
    end

    self.itemLink = self:GetItemLink()
    self.itemID = self:GetItemID()
    self.level = self:GetCurrentItemLevel()
    self.quality = self:GetItemQuality()
    self.isKeystone = C_Item.IsItemKeystoneByID(self.itemID or self.itemLink)
    self.classID, self.subclassID, self.bindtype, self.expansion = select(12, GetItemInfo(self:GetItemLink()))
    self.name = self:GetItemName()
    self.count = 1

    self.maxStackSize  = select(8, GetItemInfo(self:GetItemLink()))
    --self.guid = C_Item.GetItemGUID(self:GetItemLocation())

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

function EasyDestroyItem:GetValueByKey(key)
    if self and self[key] then
        return self[key]
    else
        error(string.format("Unable to locate item information with key (%s)", key))
    end
end

function EasyDestroyItem:CompareByKey(k, v)

    if self and self[k] then
        return self[k] == v
    elseif not self[k] then
        error(string.format("Unable to compare Item with value(%s). Key (%s) not found.", v, k))
    end

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


EasyDestroyFilter = {}
EasyDestroyFilter.__index = EasyDestroyFilter

function EasyDestroyFilter:New(ftype, name)

    -- Accepts a type, and name. Only used when actually creating a new filter.
    -- If no type provided, error out.
    -- If no name provided, use the filterID.
    
    local self = {}
    setmetatable(self, EasyDestroyFilter)
    
    if type(ftype) ~= "number" or (ftype~= ED_FILTER_TYPE_SEARCH and ftype ~= ED_FILTER_TYPE_BLACKLIST) then
        error("EasyDestroyFilter: Must provide a proper filter type.")
    end

    self.filterID = self:GetNextFilterID()
    self.name = nil

    if name and name ~= "" then
        self.name = name
    else
        self.name = self.filterID
    end

    self.filterType = ftype
    self.criteria = {}
    self.favorite = false
    self.actions = nil

    if EasyDestroy.Favorites.UsingCharacterFavorites() then
        self.favorite = false
    else
        self.favorite = self.favorite or false
    end    

    return self
end

function EasyDestroyFilter:Load(fid)

    if type(fid) ~= "string" then
        error("Usage: EasyDestroyFilter:Load(FilterID)", 2)
    end

    if EasyDestroy.Data.Filters and not EasyDestroy.Data.Filters[fid] then
        error(string.format("FilterID (%s) does not exist.", fid))
    end

    --  If it's already cached, we'll just send out the cached one.
    if EasyDestroy.Cache.FilterCache and EasyDestroy.Cache.FilterCache[fid] then
        return EasyDestroy.Cache.FilterCache[fid]
    end

    local self = {}
    setmetatable(self, EasyDestroyFilter)

    -- you can't call new on an already made filter
    self.New = function() return end

    self.filterID = fid
    local savedData = EasyDestroy.Data.Filters[fid]

    self.name = savedData.properties.name
    self.filterType = savedData.properties.type
    self.criteria = savedData.filter
    self.favorite = savedData.properties.favorite
    self.actions = savedData.properties.actions or nil

    return self

end

function EasyDestroyFilter:SetName(name)
    if not name or type(name) ~= "string" then
        error("Usage: EasyDestroyFilter:SetName(string)")
    end
        
    if name and name ~= "" then
        self.name = name
    else
        self.name = self.filterID
    end
end

function EasyDestroyFilter:GetName()
    if self.name and type(self.name) == "string" then
        return self.name
    else
        return self.filterID
    end
end

function EasyDestroyFilter:SetFavorite(state)
    if state == nil or type(state) ~= "boolean" then
        error("Usage: EasyDestroyFilter:SetFavorite(bool)")
    end

    if EasyDestroy.Favorites.UsingCharacterFavorites() then
        self.favorite = false
    else
        self.favorite = state
    end
end

function EasyDestroyFilter:GetFavorite()
    if self.favorite == nil or type(self.favorite) ~= "boolean" then
        error("Code Error: Invalid Filter Favorite Value Set")
    end

    return self.favorite
end

function EasyDestroyFilter:SetType(ftype)
    if ftype == nil or type(ftype) ~= "number" then
        error("Usage: EasyDestroyFilter:SetType(number)")
    end

    self.filterType = ftype
end

function EasyDestroyFilter:GetType()
    if not self.filterType or type(self.filterType) ~= "number" then
        error("Code Error: Invalid Filter Type Set")
    end

    return self.filterType
end

function EasyDestroyFilter:GetProperties()
    return {name=self.name, type=self.filterType, favorite=self.favorite}
end

function EasyDestroyFilter:SetProperties(name, ftype, fav)
    self:SetName(name)
    self:SetType(ftype)
    self:SetFavorite(fav)
end

function EasyDestroyFilter:GetCriteria()
    return self.criteria
end

function EasyDestroyFilter:ToTable()
    local outTable = {}
    outTable.properties = self:GetProperties()
    outTable.filter = self:GetCriteria()
    outTable.fid = self.filterID
    return outTable
end


function EasyDestroyFilter:GetNextFilterID()

    -- find the last used FilterID and add 1 to it

    local lastID = 0
    for k, v in pairs(EasyDestroy.Data.Filters) do
        local n = tonumber(string.gsub(k, "FilterID", "") or 0)
        if n > lastID then 
            lastID = n
        end
    end

	return "FilterID" .. tostring(lastID + 1)

end

function EasyDestroyFilter:SetActions(action, unset)
	for k, v in pairs(EasyDestroy.Enum.Actions) do
		if v == action then
			if not unset then
				self.actions = bit.bor(self.actions, action)
			else
				self.actions = bit.band(self.actions, bit.bnot(action))
			end
		end
	end
end

function EasyDestroyFilter:ToggleAction(action)
	for k, v in pairs(EasyDestroy.Enum.Actions) do
		if v == action then
			self.actions = bit.bxor(self.actions, action)
		end
	end
end


function EasyDestroyFilter:LoadCriteriaFromWindow()
    wipe(self.criteria)
    for i, registeredFilter in ipairs(EasyDestroy.CriteriaStack) do
		local val = registeredFilter:GetValues()
		if val ~= nil then 
			self.criteria[registeredFilter:GetKey()] = val
		end
	end
end

function EasyDestroyFilter:SetCriteria(criteriaTable)

    wipe(self.criteria)

    for k, v in pairs(criteriaTable) do
        if v ~= nil then
            self.criteria[k] = v
        end
    end

end

function EasyDestroyFilter:GetCriterionByKey(key)
    if key and self.criteria and self.criteria[key] then
        return self.criteria[key]
    end
    return nil
end

function EasyDestroyFilter:GetActions()
    if self.actions ~= nil then
        return self.actions
    end

    return EasyDestroy.Enum.Actions.Disenchant
end

function EasyDestroyFilter:SaveToData()
    
    -- Now that we want to save the criteria the user has selected 
    -- we'll pull it all in one last time and then set it in the filter

    self:SetCriteria(EasyDestroy.UI.GetCriteria())
    
    -- Generate the table-formatted filter for saving
    EasyDestroy.Data.Filters[self.filterID] = self:ToTable()

    -- Reload the filter
    EasyDestroy.UI.ReloadFilter(self.filterID)

end

function EasyDestroyFilter:Validate(skipFavoriteCheck)
    local filterName = EasyDestroy.UI.GetFilterName()
    local favChecked = EasyDestroy.UI.GetFavoriteChecked()

    local favoriteFid = EasyDestroy.Favorites.GetFavorite()
	local nameFid = EasyDestroy.FindFilterWithName(filterName)

    if nameFid and nameFid ~= self.filterID then
		return false, ED_ERROR_NAME, filterName
    elseif favoriteFid and favoriteFid ~= nil and EasyDestroy.Favorites.UsingCharacterFavorites() and not skipFavoriteCheck then
		if favoriteFid ~= self.filterID and favChecked then
			return false, ED_ERROR_FAVORITE
		end
    elseif favoriteFid and favoriteFid ~= nil and self:GetFavorite() and not skipFavoriteCheck then
		EasyDestroy.Debug(favoriteFid, self.filterID, "Checking for filter id match.")
		if favoriteFid ~= self.filterID and favChecked then
			return false, ED_ERROR_FAVORITE
		end
	end

    return true, ED_ERROR_NONE, ''

end
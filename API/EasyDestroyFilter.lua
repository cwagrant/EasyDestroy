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

function EasyDestroyFilter:GetFilterID()

    return self.filterID

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


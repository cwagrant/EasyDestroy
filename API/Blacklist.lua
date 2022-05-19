EasyDestroy.Blacklist = {}
local protected ={}

protected.SessionBlacklist = {}

function EasyDestroy.Blacklist.AddSessionItem(item)
	
	if EasyDestroy.Blacklist.HasSessionItem(item) then return end

	tinsert(protected.SessionBlacklist, item:ToTable())

	EasyDestroy.Events:Fire("ED_BLACKLIST_UPDATED")

end

function EasyDestroy.Blacklist.HasSessionItem(item)

    for k, v in ipairs(protected.SessionBlacklist) do

        if protected.IsItemMatch(item, v) then 
			return true
		end

    end

	return false
end

function EasyDestroy.Blacklist.ClearSession()

	wipe(protected.SessionBlacklist)

	EasyDestroy.Events:Fire("ED_BLACKLIST_UPDATED")

end

function EasyDestroy.Blacklist.AddItem(item)
    
	-- don't want to add multiple versions of someone gets click-happy on the UI side of things.
	if EasyDestroy.Blacklist.HasItem(item) then return end

	tinsert(EasyDestroy.Data.Blacklist, item:ToTable())

	EasyDestroy.Events:Fire("ED_BLACKLIST_UPDATED")

end

function EasyDestroy.Blacklist.HasItem(item)

    for k, v in ipairs(EasyDestroy.Data.Blacklist) do

		if protected.IsItemMatch(item, v) then 
			return true
		end

    end

    return false

end

function EasyDestroy.Blacklist.RemoveItem(item)

	for k, v in ipairs(EasyDestroy.Data.Blacklist) do

		if protected.IsItemMatch(item, v) then 
			tremove(EasyDestroy.Data.Blacklist, k)
		end

    end

	EasyDestroy.Events:Fire("ED_BLACKLIST_UPDATED")

end

function EasyDestroy.Blacklist.InFilterBlacklist(item)

	local filterRegistry = EasyDestroy.CriteriaRegistry
	local criteriaTable = {}
	local matchesAny = false
	for fid, blacklist in pairs(EasyDestroy.Data.Filters) do
		if blacklist.properties.type == ED_FILTER_TYPE_BLACKLIST then
			wipe(criteriaTable)
			for k, v in pairs(blacklist.filter) do
				if filterRegistry[k].Blacklist ~= nil and type(filterRegistry[k].Blacklist == "function") then
					if filterRegistry[k]:Blacklist(v, item) then
						tinsert(criteriaTable, true)
					else
						tinsert(criteriaTable, false)
					end
				elseif filterRegistry[k]:Check(v, item) then
					--print(blacklist.properties.name, filterRegistry[k].name, v, item.link)
					tinsert(criteriaTable, true)
				else
					tinsert(criteriaTable, false)			
				end
			end
			if not tContains(criteriaTable, false) then 
				matchesAny = true	
			end
		end
		-- short circuit on a match
		if matchesAny then
			return true
		end
	end
	return matchesAny
	
end

function protected.IsItemMatch(item, listEntry)

	if listEntry and listEntry.itemid and listEntry.itemid == item:GetItemID() then

		if listEntry.legendary and listEntry.legendary == item:GetItemName() then 
			return true
		elseif listEntry.quality == item.quality and listEntry.ilvl == item.level then
			if listEntry.name and listEntry.name == item:GetItemName() then
				return true
			elseif not listEntry.name then 
				-- found a match on everything else, and no name is saved in the db (legacy)
				return true
			end
		end
	end

	return false

end
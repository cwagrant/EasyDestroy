EasyDestroy.Blacklist = {}

local _API = EasyDestroy.Blacklist
EasyDestroy.Blacklist.name = "EasyDestroy.Blacklist"

function EasyDestroy.Blacklist.AddSessionItem(item)
	
	tinsert(EasyDestroy.SessionBlacklist, item:ToTable())

	EasyDestroy.Events:Fire("ED_BLACKLIST_UPDATED")

end

function EasyDestroy.Blacklist.HasSessionItem(item)

    for k, v in ipairs(EasyDestroy.SessionBlacklist) do
        -- if regular item, match on itemid, quality, ilvl
        -- if legendary item, match on itemid and name
        if v and ((v.itemid == item.itemID and v.quality == item.quality and v.ilvl == item.level) or (v.legendary and v.itemid==item.itemID and v.legendary==item:GetItemName())) then
            return true
        end
    end

	return false
end

function EasyDestroy.Blacklist.AddItem(item)
    	
	tinsert(EasyDestroy.Data.Blacklist, item:ToTable())

	EasyDestroy.Events:Fire("ED_BLACKLIST_UPDATED")

end

function EasyDestroy.Blacklist.HasItem(item)

    for k, v in ipairs(EasyDestroy.Data.Blacklist) do

        if v and v.itemid and v.itemid == item:GetItemID() then

            if v.legendary and v.legendary == item:GetItemName() then 
                return true
            elseif v.quality == item.quality and v.ilvl == item.level then
                if v.name and v.name == item:GetItemName() then
                    return true
                elseif not v.name then 
                    -- found a match on everything else, and no name is saved in the db (legacy)
                    return true
                end
            end
        end

    end

    return false

end

function EasyDestroy.Blacklist.RemoveItem(item)

	for k, v in ipairs(EasyDestroy.Data.Blacklist) do
        -- if regular item, match on itemid, quality, ilvl
        -- if legendary item, match on itemid and name
		--- TODO: Update this & Add to use the same logic as HasItem in regards to item names
        if v and ((v.itemid == item.itemID and v.quality == item.quality and v.ilvl == item.level) or (v.legendary and v.itemid==item.itemID and v.legendary==item:GetItemName())) then
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
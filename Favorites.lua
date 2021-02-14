--[[ Logic for the Favoriting System ]]


function EasyDestroyFilters_FavoriteIconOnClick()
    --[[
	Sets the checked/unchecked state of the favorite icon.

    If setting to checked and the user has an existing favorite
    AND we are not using character favorites, then clear their
    chosen favorite.

    TODO: Is the part about unsetting a faovrite wanted here?
    I think that's already handled in the save functionality.
    ]]
	if EasyDestroyFilters_FavoriteIcon:GetChecked() then
		EasyDestroyFilters_FavoriteIcon:SetChecked(false)
	else
		local existingFavorite = EasyDestroy_GetFavorite()
		if existingFavorite and existingFavorite ~= nil then
			if not EasyDestroy_UsingCharacterFavorites() then
				EasyDestroy.Data.Filters[existingFavorite].properties.favorite = false
			end
		end
		EasyDestroyFilters_FavoriteIcon:SetChecked(true)
	end
end

function EasyDestroy_GetFavorite()
    --[[
	If the user has character specific favorites set AND the character has a favorite
	then we'll return the FID set in the character's data.
	
	If the user has character specific favorites set and the character has no favorite
	or the favorite no longer exists, then we'll return nil.

	If character specific favorites are off then set the favorite based on if one exists.
    ]]
	if EasyDestroy.Data.Options.CharacterFavorites and EasyDestroy.CharacterData then
		if EasyDestroy.CharacterData.FavoriteID and EasyDestroy.Data.Filters[EasyDestroy.CharacterData.FavoriteID] then
			local filter = EasyDestroy.Data.Filters[EasyDestroy.CharacterData.FavoriteID] or nil
			if filter ~= nil then
				if filter.properties.type == ED_FILTER_TYPE_BLACKLIST then
					EasyDestroy_UnsetFavorite()
					return nil
				else
					return EasyDestroy.CharacterData.FavoriteID
				end
			end
		end
		-- if we didn't find one, then lets return nil
		return nil
	end

	if GetTableSize(EasyDestroy.Data.Filters)>0 then
		for k, filterObj in pairs(EasyDestroy.Data.Filters) do
			if filterObj.properties.favorite then
				return k
			end
		end
	end
	return nil
end

function EasyDestroy_UsingCharacterFavorites()
    --[[ Returns whether or not Character Favorites is being used. ]]
	if EasyDestroy.Data.Options.CharacterFavorites then
		return true
	end
	return false
end

function EasyDestroy_UnsetFavorite()
    --[[ 
    If Character Favorites are turned on, set to nil.
    Otherwise loop through existing filters and if any are set as
    a favorite, unfavorite them. 
    ]]
	if EasyDestroy.Data.Options.CharacterFavorites and EasyDestroy.CharacterData then
		EasyDestroy.CharacterData.FavoriteID = nil
		return
	end

	if GetTableSize(EasyDestroy.Data.Filters)>0 then
		for k, filterObj in pairs(EasyDestroy.Data.Filters) do
			if filterObj.properties.favorite then
				EasyDestroy.Data.Filters[k].properties.favorite = false
			end
		end
	end
end

function EasyDestroyFilters_ClearFavorite(fid)
	if EasyDestroy.Data.Options.CharacterFavorites and EasyDestroy.CharacterData then
		if EasyDestroy.CharacterData.FavoriteID then
			EasyDestroy.CharacterData.FavoriteID = nil
			return
		end
	elseif not EasyDestroy.Data.Options.CharacterFavorites and fid then
		EasyDestroy.Data.Filters[fid].properties.favorite = false
	else
		for fid, filter in pairs(EasyDestroy.Data.Filters) do
			filter.properties.favorite=false
		end
	end
	
end
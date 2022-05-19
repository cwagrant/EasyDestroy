--[[ Logic for the Favoriting System ]]
EasyDestroy.Favorites = {}
function EasyDestroy.Favorites.GetFavorite()
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
					EasyDestroy.Favorites.UnsetFavorite()
					return nil
				else
					return EasyDestroy.CharacterData.FavoriteID
				end
			end
		end
		-- if we didn't find one, then lets return nil
		return nil
	end

	if EasyDestroy.GetTableSize(EasyDestroy.Data.Filters)>0 then
		for k, filterObj in pairs(EasyDestroy.Data.Filters) do
			if filterObj.properties.favorite then
				return k
			end
		end
	end
	return nil
end

function EasyDestroy.Favorites.UsingCharacterFavorites()
    --[[ Returns whether or not Character Favorites are being used. ]]
	if EasyDestroy.Data.Options.CharacterFavorites then
		return true
	end
	return false
end

function EasyDestroy.Favorites.UnsetFavorite()
    --[[ 
    If Character Favorites are turned on, set to nil.
    Otherwise loop through existing filters and if any are set as
    a favorite, unfavorite them. 
    ]]
	if EasyDestroy.Data.Options.CharacterFavorites and EasyDestroy.CharacterData then
		EasyDestroy.CharacterData.FavoriteID = nil
		return
	end

	if EasyDestroy.GetTableSize(EasyDestroy.Data.Filters)>0 then
		for k, filterObj in pairs(EasyDestroy.Data.Filters) do
			if filterObj.properties.favorite then
				EasyDestroy.Data.Filters[k].properties.favorite = false
				-- Need to update the cache as well.
				if EasyDestroy.Cache.FilterCache and EasyDestroy.Cache.FilterCache[k] then
					EasyDestroy.Cache.FilterCache[k]:SetFavorite(false)
				end
			end
		end
	end
end

function EasyDestroy.Favorites.ClearUserFavorite()
	EasyDestroy.CharacterData.FavoriteID = nil
end
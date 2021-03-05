EasyDestroy.API.Filters = {}

local _API = EasyDestroy.API.Filters
_API.name = "EasyDestroy.API.Filters"

function _API.FindFilterWithName(filterName)

	-- This could maybe be moved to the filters class? But it's more of a static function

	if EasyDestroy.Data.Filters then
		for fid, filter in pairs(EasyDestroy.Data.Filters) do

			if filter.properties.name == filterName then

				return fid, filter

			end

		end
	end

	return nil
end

function _API.DeleteFilter(FilterID)

	EasyDestroy.Data.Filters[FilterID] = nil

	EasyDestroy.Events:Fire("FiltersUpdated")

end

function _API.SaveFilter(filter)

	EasyDestroy.Data.Filters[filter:GetFilterID()] = filter:ToTable()

	EasyDestroy.Events:Fire("FiltersUpdated")

end
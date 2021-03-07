EasyDestroy.Config = {}

local protected = {}
protected.FrameRegistry = {}

function EasyDestroy.Config.ItemTypeFilterByFlags(flag)

	local out = {}

	if flag == nil then flag = EasyDestroy.Enum.Actions.Disenchant end 

	for k, v in pairs(EasyDestroy.Dict.Actions) do 
		local chk = bit.band(k, flag)
		if chk > 0 then
			for k,v in pairs(v.itemTypes) do
				tinsert(out, v)
			end
		end
	end

	return out

end

function EasyDestroy.RegisterFrame(frame, ftype)
    if protected.FrameRegistry then
        protected.FrameRegistry[ftype] = protected.FrameRegistry[ftype] or {}
        tinsert(protected.FrameRegistry[ftype], frame)
    end
end

function EasyDestroy.GetRegisteredFrames()

	return protected.FrameRegistry

end

function EasyDestroy.GetRegisteredFramesByKey(key)

	return protected.FrameRegistry[key] or {}

end
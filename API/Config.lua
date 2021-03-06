EasyDestroy.Config = {}

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
    if EasyDestroy.FrameRegistry then
		EasyDestroy.Debug("EasyDestroy.RegisterFrame", ftype, frame:GetName())
        EasyDestroy.FrameRegistry[ftype] = EasyDestroy.FrameRegistry[ftype] or {}
        tinsert(EasyDestroy.FrameRegistry[ftype], frame)
    end
end
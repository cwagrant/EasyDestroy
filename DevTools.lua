-- recursive print a table
function pprint(tbl, level)
	local newlevel = level or 0
	newlevel = newlevel + 1
	if type(tbl) ~= "table" then
		print(tbl)
	else
		for k, v in pairs(tbl) do
			if type(v) == "table" then
				print(k)
				pprint(v, newlevel)
			else
				print(string.rep('    ', newlevel), k, v)
			end
		end
	end
end

-- convert arguments to EasyDestroy.Debug into concatenated strings
local function handler(...)
	local ret = ""
	for k, v in ipairs({...}) do
		if tostring(v) then v = tostring(v) end
		ret = ret .. v .. " "
	end

	return ret
end

-- send messages to the debug frame 
function EasyDestroy.Debug(...)

	if EasyDestroy.DebugActive then
		if EasyDestroy.DebugFrame then
			EasyDestroy.DebugFrame:AddMessage(date("[%H:%M:%S]") .. " " .. handler(...) .. "\n")
		else
			print(date(), ...)
		end

	end
end

-- create a frame for capturing debug messages
function EasyDestroy:CreateBG(frame, r, g, b)
	local bg = frame:CreateTexture(nil, "BACKGROUND");
	bg:SetAllPoints(true);
	bg:SetColorTexture(r, g, b, 0.5);
end

-- My own personal hell, err, chat window for debug messages.
if EasyDestroy.DebugActive then
	local f = CreateFrame("Frame", nil, UIParent, "UIPanelDialogTemplate")
	f:SetPoint("CENTER")
	f:SetHeight(300)
	f:SetWidth(600)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)

	local c = CreateFrame("ScrollingMessageFrame", nil, f )
	c:SetPoint("TOPLEFT", 10, -28)
	c:SetPoint("BOTTOMRIGHT", -10, 8)
	c:SetFontObject("GameFontNormal")
	c:SetTextColor(1,1,1,1)
	c:SetFading(false)
	c:SetJustifyH("LEFT")
	c:SetMaxLines(1000)
	c:EnableMouseWheel(true)
	c:SetScript("OnMouseWheel", FloatingChatFrame_OnMouseScroll)
	c:Show()

	c:AddMessage("TEST")
	EasyDestroy.DebugFrame = c

	-- function EasyDestroy.Events:OnUsed(target, eventname)

	-- 	EasyDestroy.Debug(tostring(eventname))

	-- end

	local function DBG(e)
		EasyDestroy.Debug(e)
	end

	-- Would probably be better if this went to a separate events frame

	EasyDestroy.RegisterCallback(f, "ED_NEW_CRITERIA_AVAILABLE", DBG)
	EasyDestroy.RegisterCallback(f, "ED_BLACKLIST_UPDATED", DBG)
	EasyDestroy.RegisterCallback(f, "ED_INVENTORY_UPDATED_DELAYED", DBG)
	EasyDestroy.RegisterCallback(f, "ED_FILTER_CRITERIA_CHANGED", DBG)
	EasyDestroy.RegisterCallback(f, "ED_FILTER_LOADED", DBG)
	EasyDestroy.RegisterCallback(f, "ED_FILTERS_AVAILABLE_CHANGED", DBG)

end


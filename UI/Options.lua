EasyDestroy.UI.Options = {}

local optionsFrame = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer)
optionsFrame.name = EasyDestroy.AddonName

local protected  = {}

function EasyDestroy.UI.Options.__init()

    optionsFrame:SetScript("OnShow", protected.OnOptionsShow)
    InterfaceOptions_AddCategory(optionsFrame)

end

function protected.ShowTooltip(frame, tt)

    GameTooltip:SetOwner(frame, "ANCHOR_TOP")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(tt, 1, 1, 1, 1)
    GameTooltip:Show()

end

function protected.CreateOptionsForFrame(frame, optionTable)

    local column, rowFirstFrame, rowLastFrame = 0, nil, nil

    for k, v in ipairs(optionTable) do
        column = 0
        if v and v.key and v.text then

            local f = CreateFrame("Frame", nil, frame, "EasyDestroyFramedCheckboxTemplate")
            f.allowresize = false
            f:SetLabel(v.text)
            f:SetWidth(v.width or 128)

            if not rowFirstFrame then
                f:SetPoint("TOPLEFT", 20, -20)
            else
                f:SetPoint("TOPLEFT", rowFirstFrame, "BOTTOMLEFT")
            end

            f:Show()
            if v.tooltip then 
                f.OnHover.SetTooltip = function(self) ShowTooltip(self, v.tooltip) end 
            --f:HookScript("OnEnter", function(self) ShowTooltip(self, v.tooltip) end )
            end

            if v.OnClick then f.Checkbutton:HookScript("OnClick", v.OnClick) end

            if v.optionType == "boolean" then 
                f:SetChecked(EasyDestroy.Data.Options[v.key])
            elseif v.value then
                if bit.band(EasyDestroy.Data.Options.Actions, v.value) > 0 then
                    f:SetChecked(true)
                end
            end

            rowFirstFrame = f
        else
            for i, j in ipairs(v) do
                if j and j.key and j.text then
                    local f = CreateFrame("Checkbutton", nil, frame, "EasyDestroyFramedCheckboxTemplate")
                    f.allowresize = false
                    f:SetLabel(j.text)
                    f:SetWidth(j.width or 128)

                    if not rowFirstFrame then
                        f:SetPoint("TOPLEFT", 20, -20)
                        rowFirstFrame = f
                    elseif column == 0 then
                        f:SetPoint("TOPLEFT", rowFirstFrame, "BOTTOMLEFT")
                        rowFirstFrame = f
                    else
                        f:SetPoint("LEFT", rowLastFrame, "RIGHT")
                    end
                    f:Show()
                    if j.tooltip then 
                        f.OnHover.SetTooltip = function(self) ShowTooltip(self, j.tooltip) end 
                    end
                    f:SetScript("OnLeave", function(self) GameTooltip:Hide() end)

                    if j.OnClick then f.Checkbutton:HookScript("OnClick", j.OnClick) end

                    if j.optionType == "boolean" then 
                        f:SetChecked(EasyDestroy.Data.Options[j.key])
                    elseif j.value then
                        if bit.band(EasyDestroy.Data.Options.Actions, j.value) > 0 then
                            f:SetChecked(true)
                        end
                    end

                    rowLastFrame = f
                    column = column + 1

                end
            end
        end
    end
end

function protected.OnOptionsShow()

    local baseFrame = CreateFrame("Frame", nil, optionsFrame)

    baseFrame:SetAllPoints()

    local easyDestroyOptionsTable = {
        {
            {
                key = "CharacterFavorites",
                text = "Character Favorites",
                OnClick = function(self) 
                    local dialog = StaticPopup_Show("ED_RELOAD_CURRENT_FILTER")
                    if dialog then dialog.data = self end
                end,
                tooltip = "Enables/Disables the use of character-specific favorites.\n\n|cFFFF2934Changing this will require reloading the current filter.|r",
                optionType = "boolean",
            },
            {
                key="AutoBlacklist",
                text = "Auto-Blacklist Non-Destroyables",
                width = 196,
                OnClick = function() EasyDestroy.Data.Options.AutoBlacklist = not EasyDestroy.Data.Options.AutoBlacklist end,
                tooltip = "If selected, when you try to destroy items that cannot be destroyed they will automatically be added to the blacklist.",
                optionType = "boolean",
            }
        }
    }
    local destroyOptionsTable = {
        {
            {
                key="allowdisenchant", 
                text="Allow Disenchanting", 
                tooltip="If selected Searches will show items that can be disenchanted.",
                OnClick = function(self) 
                    EasyDestroy.Data.Options.Actions = bit.bxor(EasyDestroy.Data.Options.Actions, EasyDestroy.Enum.Actions.Disenchant)
                    EasyDestroy.Events:Call("UpdateItemWindow")
                end,
                value = EasyDestroy.Enum.Actions.Disenchant,
            },
            {
                key="allowmilling", 
                text="Allow Milling", 
                tooltip="If selected Searches will show items that can be milled.", 
                OnClick = function(self) 
                    EasyDestroy.Data.Options.Actions = bit.bxor(EasyDestroy.Data.Options.Actions, EasyDestroy.Enum.Actions.Mill) 
                    EasyDestroy.Events:Call("UpdateItemWindow")
                end,
                value = EasyDestroy.Enum.Actions.Mill,
            },
            {
                key="allowprospecting", 
                text="Allow Prospecting", 
                tooltip="If selected Searches will show items that can be prospected.",
                OnClick = function(self) 
                    EasyDestroy.Data.Options.Actions = bit.bxor(EasyDestroy.Data.Options.Actions, EasyDestroy.Enum.Actions.Prospect) 
                    EasyDestroy.Events:Call("UpdateItemWindow")
                end,
                value = EasyDestroy.Enum.Actions.Prospect,
            },

        },
    }
    

    local addonOptions = CreateFrame("Frame", nil, baseFrame, BackdropTemplateMixin and "BackdropTemplate")
    addonOptions:SetPoint("TOPLEFT", 30, -30)
    addonOptions:SetPoint("RIGHT", -30, -30)
    addonOptions:SetHeight(60)
    addonOptions:SetBackdrop({
		bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile="Interface\\Buttons\\WHITE8x8", 
		edgeSize=1,
		tile=true, 
		tileEdge=false, 
		insets={left=1, right=1, top=1, bottom=1}
	})
    addonOptions:SetBackdropColor(0,0,0,0.5)
    addonOptions:SetBackdropBorderColor(0,0,0,1)
    addonOptions:Show()

    addonOptions.label = addonOptions:CreateFontString(addonOptions, "OVERLAY", "GameTooltipText")
    addonOptions.label:SetPoint("BOTTOMLEFT", addonOptions, "TOPLEFT", 4 , 2)
    addonOptions.label:SetText("EasyDestroy Options")

    protected.CreateOptionsForFrame(addonOptions, easyDestroyOptionsTable)

    local destroyOptions = CreateFrame("Frame", nil, baseFrame, BackdropTemplateMixin and "BackdropTemplate")
    destroyOptions:SetPoint("TOPLEFT", addonOptions, "BOTTOMLEFT", 0, -30)
    destroyOptions:SetPoint("TOPRIGHT", addonOptions, "BOTTOMRIGHT")
    destroyOptions:SetHeight(60)
    destroyOptions:SetBackdrop({
		bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile="Interface\\Buttons\\WHITE8x8", 
		edgeSize=1,
		tile=true, 
		tileEdge=false, 
		insets={left=1, right=1, top=1, bottom=1}
	})
    destroyOptions:SetBackdropColor(0,0,0,0.5)
    destroyOptions:SetBackdropBorderColor(0,0,0,1)
    destroyOptions:Show()

    destroyOptions.label = destroyOptions:CreateFontString(destroyOptions, "OVERLAY", "GameTooltipText")
    destroyOptions.label:SetPoint("BOTTOMLEFT", destroyOptions, "TOPLEFT", 4, 2)
    destroyOptions.label:SetText("Search & Destroy Options")

    protected.CreateOptionsForFrame(destroyOptions, destroyOptionsTable)

    optionsFrame:SetScript("OnShow", nil)
    baseFrame:Show()

end







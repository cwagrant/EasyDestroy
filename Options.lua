local optionsFrame = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer)
optionsFrame.name = EasyDestroy.AddonName

local function ShowTooltip(frame, tt)
    GameTooltip:SetOwner(frame)
    GameTooltip:ClearLines()
    GameTooltip:AddLine(tt, 1, 1, 1, 1)
    GameTooltip:Show()
end

local function OnOptionsShow()

    local baseFrame = CreateFrame("Frame", nil, optionsFrame)

    baseFrame:SetAllPoints()

    local checkboxOptions = {
        {
            {
                key="allowdisenchant", 
                text="Allow Disenchanting", 
                tooltip="If selected Searches will show items that can be disenchanted.",
                OnClick = function(self) 
                    EasyDestroy.Data.Options.Actions = bit.bxor(EasyDestroy.Data.Options.Actions, EasyDestroy.Enum.Actions.Disenchant)
                    EasyDestroy.UI.ItemWindow.Update()
                end,
                value = EasyDestroy.Enum.Actions.Disenchant,
            },
            {
                key="allowmilling", 
                text="Allow Milling", 
                tooltip="If selected Searches will show items that can be milled.", 
                OnClick = function(self) 
                    EasyDestroy.Data.Options.Actions = bit.bxor(EasyDestroy.Data.Options.Actions, EasyDestroy.Enum.Actions.Mill) 
                    EasyDestroy.UI.ItemWindow.Update()
                end,
                value = EasyDestroy.Enum.Actions.Mill,
            },
            {
                key="allowprospecting", 
                text="Allow Prospecting", 
                tooltip="If selected Searches will show items that can be prospected.",
                OnClick = function(self) 
                    EasyDestroy.Data.Options.Actions = bit.bxor(EasyDestroy.Data.Options.Actions, EasyDestroy.Enum.Actions.Prospect) 
                    EasyDestroy.UI.ItemWindow.Update()
                end,
                value = EasyDestroy.Enum.Actions.Prospect,
            },

        },
    }
    
    local column, rowFirstFrame, rowLastFrame = 0, nil, nil

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

    local charFav = CreateFrame("Frame", nil, addonOptions, "EasyDestroyFramedCheckboxTemplate")
    charFav:SetLabel("Character Favorites")
    charFav:SetPoint("TOPLEFT", 20, -15)
    charFav:SetChecked(EasyDestroy.Favorites.UsingCharacterFavorites())
    
    -- Toggle the character favorites selection

    charFav.Checkbutton:SetScript("OnClick", function()
        -- Realistically this needs a Dialog and force the user to reload UI after changing this
        -- EasyDestroy.Data.Options.CharacterFavorites = not EasyDestroy.Data.Options.CharacterFavorites
        StaticPopup_Show("ED_RELOAD_CURRENT_FILTER")
    end)

    EasyDestroy.UI.SetCharacterFavoriteFromOptions = function() charFav:SetChecked(EasyDestroy.Favorites.UsingCharacterFavorites()) end

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



    -- Turning the table above into an actual options menu
    for k, v in ipairs(checkboxOptions) do
        column = 0
        if v and v.key and v.text then

            local f = CreateFrame("Frame", nil, destroyOptions, "EasyDestroyFramedCheckboxTemplate")
            f.allowresize = false
            f:SetLabel(v.text)
            f:SetWidth(128)

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

            if v.value then
                if bit.band(EasyDestroy.Data.Options.Actions, v.value) > 0 then
                    f:SetChecked(true)
                end
            end

            rowFirstFrame = f
        else
            for i, j in ipairs(v) do
                if j and j.key and j.text then
                    local f = CreateFrame("Checkbutton", nil, destroyOptions, "EasyDestroyFramedCheckboxTemplate")
                    f.allowresize = false
                    f:SetLabel(j.text)
                    f:SetWidth(128)

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

                    if j.value then
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

    optionsFrame:SetScript("OnShow", nil)
    baseFrame:Show()

end

function EasyDestroy.GetActions()
    return EasyDestroy.Data.Options.Actions
end

optionsFrame:SetScript("OnShow", OnOptionsShow)
InterfaceOptions_AddCategory(optionsFrame)





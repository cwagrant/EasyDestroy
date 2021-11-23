--[[

    StaticPopupDialogs used in various areas
    
]]

StaticPopupDialogs["ED_CANT_DISENCHANT_BLACKLIST"] = {
	text = "You cannot disenchant items on the blacklist.|n|nYou are currently viewing or editing a blacklist filter.",
	button1 = "Okay",
	timeout = 30,
	whileDead = false,
	hideOnEscape = true,
	preferredIndex = 3,
}

StaticPopupDialogs["ED_CONFIRM_NEW_CHARACTER_FAVORITE"] = {
    text = "You already have a favorite filter. Do you want to make this your new favorite filter?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(self) EasyDestroy.CharacterData.FavoriteID = UIDropDownMenu_GetSelectedValue(EasyDestroyDropDown) end,
    OnCancel = function(self) EasyDestroyFilterSettings.Favorite:SetChecked(false) end,
    timeout = 30,
    whileDead = false,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["ED_BLACKLIST_NO_FAVORITE"] = {
    text = "You cannot set a blacklist as a favorite. If you continue, this filter will be no longer be favorited. |n|n|cFFFF0000This applies to all characters that have this filter as a favorite.",
    button1 = "Okay",
    button2 = "Cancel",
    OnAccept = function(self) 
        EasyDestroyFilterSettings.Favorite:SetChecked(false)
        EasyDestroyFilterSettings.Favorite:Disable()
        EasyDestroy.Favorites.UnsetFavorite()
    end,
    OnCancel = function(self)
        EasyDestroyFilterSettings.Blacklist:SetChecked(false)
    end,
    timeout = 30,
    whileDead = false,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["ED_SHOW_ALL_FILTERS"] = {
    text = "You do not currently have both Searches and Blacklists checked. |nChecking this box will cause both Searches and Blacklists to show under the Filter selection. Do you wish to continue?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(self) EasyDestroy.UI.Filters.SelectAllFilterTypes() end,
    timeout = 30,
    whileDead = false,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["ED_FILTER_UNIQUE_NAME"] = {
    text = "Filters require a unique name. %s is already used.|n|n|cFFFF0000Your filter has NOT been saved.|r",
    button1 = "Okay",
    -- OnAccept = function(self) return end,
    timeout = 30,
    whileDead = false,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["ED_RELOAD_CURRENT_FILTER"] = {
    text = "This requires reloading the current filter. Do you wish to proceed?",
    button1 = "Okay",
    button2 = "Cancel",
    OnAccept = function(self) 
        EasyDestroy.Data.Options.CharacterFavorites = not EasyDestroy.Data.Options.CharacterFavorites 
        EasyDestroy.UI.ReloadCurrentFilter()
    end, 
    OnCancel = function(self, data) data:SetChecked(EasyDestroy.Data.Options.CharacterFavorites) end,
    timeout = 30,
    whileDead = false,
    hideOnEscape = true,
    preferredIndex = 3,
}


StaticPopupDialogs["ED_3_0_FEATURE_ALERT"] = {
    text = [[EasyDestroy has been updated!
    
    In version 3.0 you now have the ability to Mill and Prospect items as well as Disenchanting.
    
    Additionally, there is an options window to configure this and other features! Click Okay to be taken to the new Options menu or Cancel to close this message.
    ]],
    button1 = "Okay",
    button2 = "Cancel",
    OnAccept = function(self) 
        InterfaceOptionsFrame_OpenToCategory("EasyDestroy")
        InterfaceOptionsFrame_OpenToCategory("EasyDestroy")
    end,
    OnCancel = function(self)
        EasyDestroy.Data.Alerts = EasyDestroy.Data.Alerts or {}
    end,
    timeout = 60,
    whileDead = false,
    hideOnEscape = false,
    preferredIndex = 3,
}
function ImportExportDialog (import, text, callback)
	if not EDImportExport then
		local f = CreateFrame("Frame", "EDImportExport", UIParent, "DialogBoxFrame")
		f:SetPoint("CENTER")
		f:SetSize(500, 300)
		
		f:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight", -- this one is neat
			edgeSize = 16,
			insets = { left = 8, right = 6, top = 8, bottom = 8 },
		})
		f:SetBackdropBorderColor(0, .44, .87, 0.5) -- darkblue
		
		-- Movable
		f:SetMovable(true)
		f:SetClampedToScreen(true)
		f:SetScript("OnMouseDown", function(self, button)
			if button == "LeftButton" then
				self:StartMoving()
			end
		end)
		f:SetScript("OnMouseUp", f.StopMovingOrSizing)
		
		-- ScrollFrame
		local sf = CreateFrame("ScrollFrame", "EDImportExportScrollFrame", EDImportExport, "UIPanelScrollFrameTemplate")
		sf:SetPoint("LEFT", 16, 0)
		sf:SetPoint("RIGHT", -32, 0)
		sf:SetPoint("TOP", 0, -16)
		sf:SetPoint("BOTTOM", EDImportExportButton, "TOP", 0, 0)
		
		-- EditBox
		local eb = CreateFrame("EditBox", "EDImportExportEditBox", EDImportExportScrollFrame)
		eb:SetSize(sf:GetSize())
		eb:SetMultiLine(true)
		eb:SetAutoFocus(false) -- dont automatically focus
		eb:SetFontObject("ChatFontNormal")
		eb:SetScript("OnEscapePressed", function() f:Hide() end)
		sf:SetScrollChild(eb)
		
		-- Resizable
		f:SetResizable(true)
		f:SetMinResize(150, 100)
		
		local rb = CreateFrame("Button", "EDImportExportResizeButton", EDImportExport)
		rb:SetPoint("BOTTOMRIGHT", -6, 7)
		rb:SetSize(16, 16)
		
		rb:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
		rb:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
		rb:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
		
		rb:SetScript("OnMouseDown", function(self, button)
			if button == "LeftButton" then
				f:StartSizing("BOTTOMRIGHT")
				self:GetHighlightTexture():Hide() -- more noticeable
			end
		end)
		rb:SetScript("OnMouseUp", function(self, button)
			f:StopMovingOrSizing()
			self:GetHighlightTexture():Show()
			eb:SetWidth(sf:GetWidth())
		end)

		f:Show()
	end
	
    EDImportExportButton:SetScript("OnClick", function()
        if import then
            callback(EDImportExportEditBox:GetText())
        end
        EDImportExport:Hide()
    end)

    if not import then
	    EDImportExportEditBox:SetText(text)
    else
        EDImportExportEditBox:SetText("")
        EDImportExportEditBox:SetAutoFocus(true) 
    end

	EDImportExport:Show()

    return EDImportExport
end
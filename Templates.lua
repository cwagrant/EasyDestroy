EasyDestroyItemsMixin = {}

function EasyDestroyItemsMixin:UpdateItemFrame(item, onclick)
    if self and item:GetStaticBackingItem() then
        item:ContinueWithCancelOnItemLoad(function()
            self.Icon:SetTexture(item:GetItemIcon())
            self.Item:SetText(item:GetItemName())
        end)
        --self.Item.itemLink = link

        if item.classID == LE_ITEM_CLASS_TRADEGOODS and item.count and item.count > 1 then 
            self.Item:SetText(item:GetItemName() .. " (" .. item.count .. ")")
            self.ItemLevel:SetText("")
        elseif item.level and item.level ~= nil and item.level ~= 0 then
            if item.level then
                self.ItemLevel:SetText("(" .. item.level .. ")")
            else
                self.ItemLevel:SetText("")
            end
        end

        local r,g,b = GetItemQualityColor(item.quality)
        self:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",})
        self:SetBackdropColor(r,g,b, 0.5)

        self:SetScript("OnClick", onclick)
    end      
end

function EasyDestroyItemsMixin:HideItemFrame()
    self.item = nil
    self:Hide()
    self:SetScript("OnClick", nil)
end


--[[ So that you don't have to remember which keys/names are used ]]
EasyDestroyEditBoxMixin = {}
function EasyDestroyEditBoxMixin:SetText(text)
    self.input:SetText(text)
end

function EasyDestroyEditBoxMixin:SetNumeric(bool)
    self.input:SetNumeric(bool)
end

function EasyDestroyEditBoxMixin:GetText()
    return self.input:GetText()
end

function EasyDestroyEditBoxMixin:GetNumber()
    return self.input:GetNumber()
end

function EasyDestroyEditBoxMixin:SetLabel(text)
    self.label:SetText(text)
end

EasyDestroyEditBoxRangeMixin = {}
function EasyDestroyEditBoxRangeMixin:SetFromText(text)
    self.inputfrom:SetText(text)
end

function EasyDestroyEditBoxRangeMixin:SetToText(text)
    self.inputto:SetText(text)
end

function EasyDestroyEditBoxRangeMixin:SetValues(textfrom, textto)
    self:SetFromText(textfrom)
    self:SetToText(textto)
end

function EasyDestroyEditBoxRangeMixin:GetFromText()
    return self.inputfrom:GetText()
end

function EasyDestroyEditBoxRangeMixin:GetToText()
    return self.inputto:GetText()
end

function EasyDestroyEditBoxRangeMixin:GetTextValues()
    return self.inputfrom:GetText(), self.inputto:GetText()
end

function EasyDestroyEditBoxRangeMixin:SetNumeric(bool)
    self.inputfrom:SetNumeric(bool)
    self.inputto:SetNumeric(bool)
end

function EasyDestroyEditBoxRangeMixin:GetFromNumber()
    return self.inputfrom:GetNumber()
end

function EasyDestroyEditBoxRangeMixin:GetToNumber()
    return self.inputto:GetNumber()
end

function EasyDestroyEditBoxRangeMixin:GetNumberValues()
    return self:GetFromNumber(), self:GetToNumber()
end

--[[

    CHECKBUTTON MIXIN

]]
EasyDestroyCheckboxMixin = {}
function EasyDestroyCheckboxMixin:SetLabel(text)
    self.label:SetText(text)
end


EasyDestroyFramedCheckboxMixin = {}
function EasyDestroyFramedCheckboxMixin:SetLabel(text)
    self.Checkbutton.label:SetText(text)
end

function EasyDestroyFramedCheckboxMixin:GetChecked()
    return self.Checkbutton:GetChecked()
end

function EasyDestroyFramedCheckboxMixin:SetChecked(bool)
    self.Checkbutton:SetChecked(bool)
end


-- function EasyDestroyCheckboxMixin:SetScript(...)

--     -- pass SetScript to the actual checkbutton

--     self.Checkbutton:SetScript(...)

-- end

-- function EasyDestroyCheckboxMixin:HookScript(...)

--     -- pass HookScript to the actual checkbutton

--     self.Checkbutton:HookScript(...)

-- end

-- function EasyDestroyCheckboxMixin:HasScript(...)

--     -- pass HasScript to the actual checkbutton

--     return self.Checkbutton:HasScript(...)

-- end




EasyDestroyScrollMixin = {}
function EasyDestroyScrollMixin:Initialize(listfunc, displayed, height, childfunc)
    if type(listfunc) == "function" then
        self.ListFunction = listfunc
    end

    if type(displayed) == "number" then
        self.MaxDisplayed = displayed
    end

    if type(height) == "number" then
        self.ChildHeight = height
    end

    if type(childfunc) == "function" then
        self.ChildOnClick = childfunc
    end

    self.UpdateItemList = true
    self.ItemList = {}

    self.ItemCount = 0

    -- We can display up to 10 items, if we're doing <10 then hide the remaining
    if self.MaxDisplayed < 10 then
        for i=self.MaxDisplayed+1,10,1 do 
            local f = _G[self:GetName() .. "Item" .. i]
            f:Hide()
            f:Disable()
        end
    end
end

function EasyDestroyScrollMixin:ScrollUpdate(callbackFunction)
    local itemList = nil

    if not self.ListFunction then return end

    --[[ 
        !!This significantly reduces memory usage!!
        
        Whenever an action that would modify the results of the
        ListFunction is made, then self.UpdateItemList should be
        set to true. Otherwise, cache the current list in 
        self.ItemList. 

        Basically, this makes it so that as a user scrolls, memory
        usage doesn't increase.
    ]]

    if self.UpdateItemList then
        EasyDestroy.Debug((self:GetName() or "EasyDestroyScrollMixin") .. ":ScrollUpdate", "UpdateItemList")
        itemList = self.ListFunction()
        self.UpdateItemList = false
        self.ItemList = itemList
    else
        EasyDestroy.Debug((self:GetName() or "EasyDestroyScrollMixin") .. ":ScrollUpdate", "Using Item Cache")
        itemList = self.ItemList
    end
    if not self and self.ScrollFrame then
        return
    end
    FauxScrollFrame_Update(self.ScrollFrame, #itemList, self.MaxDisplayed, self.ChildHeight)
	local offset = FauxScrollFrame_GetOffset(self.ScrollFrame)

	for i=1, self.MaxDisplayed, 1 do
		local index = offset+i
		local frame = _G[ self:GetName() .. "Item" .. i ]
        if index <= #itemList then
            local item = itemList[index]
            frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            frame:UpdateItemFrame(item, self.ChildOnClick or nil)
            frame:Show()
            frame.item = item
            -- needsUpdate = true
        else
            frame:HideItemFrame()
		end
	end

    if callbackFunction ~= nil and type(callbackFunction) == "function" then
		callbackFunction()
	end
    
    self.ItemCount = #itemList

end

function EasyDestroyScrollMixin:OnVerticalScroll(offset)
    FauxScrollFrame_OnVerticalScroll(self.ScrollFrame, offset, self.ChildHeight, function() self:ScrollUpdate() end)
end
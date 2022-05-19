EasyDestroyFilterCriteria = {}
EasyDestroyFilterCriteria.__index = EasyDestroyFilterCriteria

function EasyDestroyFilterCriteria:New(name, key, height)
    local self = {}
    setmetatable(self, EasyDestroyFilterCriteria)
    self.name = name
    self.key = key
    self.height = height
    self.parent = _G[EDFILTER_SCROLL_CHILD]
    self.frame = nil
    self.scripts = {}

    return self
end

function EasyDestroyFilterCriteria:GetName()
    if self.name and self.name ~= nil and self.name ~= "" and type(self.name) == "string" then
        return self.name
    else
        error("Unable to get filter name")
    end
end

function EasyDestroyFilterCriteria:GetFilterFrame()

    return self.frame

end

function EasyDestroyFilterCriteria:GetKey()
    if self.key and self.key ~= nil then
        return self.key
    else
        error("No key found for filter " .. self:GetName())
    end
end

function EasyDestroyFilterCriteria:IsShown()
    if self.frame then
        return self.frame:IsShown()
    end
    return false
end

function EasyDestroyFilterCriteria:Toggle()
    if not self.frame then
        error("Unable to toggle filter frame. Not yet created. " .. self:GetName())
    end

    if self.frame:IsShown() then
        self.frame:Hide()
    else
        self.frame:Show()
    end
end

--[[ abstract functions ]]
function EasyDestroyFilterCriteria:Check()
    error("Filter " .. self.GetName() .. " does not yet have a Check function implemented.")
end

function EasyDestroyFilterCriteria:GetValues()
    error("Filter " .. self.GetName() .. " does not yet have a Getvalues function implemented.")
end

function EasyDestroyFilterCriteria:SetValues()
    error("Filter " .. self.GetName() .. " does not yet have a SetValues function implemented.")
end

function EasyDestroyFilterCriteria:Clear()
    error("Filter " .. self.GetName() .. " does not yet have a Clear function implemented.")
end
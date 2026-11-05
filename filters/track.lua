local filter = EasyDestroyFilterCriteria:New("Upgrade Track", "track", 92)

-- Upgrade tracks, lowest to highest. Names must match the tooltip text.
local TRACKS = { "Explorer", "Adventurer", "Veteran", "Champion", "Hero", "Myth" }

-- Build a pattern from Blizzard's "Upgrade Level: %s %d/%d" tooltip line so we can pull the track name out.
local function FormatToPattern(fmt)
    fmt = fmt:gsub("[%(%)%.%+%-%*%?%[%]%^%$]", "%%%0")
    fmt = fmt:gsub("%%s", "(.-)"):gsub("%%d", "(%%d+)")
    return "^" .. fmt .. "$"
end

local UPGRADE_PATTERN = FormatToPattern(ITEM_UPGRADE_TOOLTIP_FORMAT_STRING or "Upgrade Level: %s %d/%d")

-- There's no reason a filter should show up more than once
-- So we can treat it as a singleton and just use this to
-- get any previous creations of the filter frame, or
-- create it if it's not yet been made
function filter:Initialize()
    -- We create the frame here, we'll leave the details on size/anchors to the Filters window.
    self.frame = self.frame or CreateFrame("Frame", nil, self.parent)

    self.label = self.frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    self.label:SetPoint("CENTER", self.frame, "TOP", 0, -10)
    self.label:SetText(self.name)

    self.checkboxes = self.checkboxes or {}
    self.scripts.OnClick = {}

    -- Two columns, filled top to bottom.
    local perColumn = math.ceil(#TRACKS / 2)
    for i, track in ipairs(TRACKS) do
        local checkbox = self.checkboxes[track] or CreateFrame("Frame", nil, self.frame, "EasyDestroyFramedCheckboxTemplate")
        local row = (i - 1) % perColumn
        if i <= perColumn then
            checkbox:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 24, -16 - (row * 24))
        else
            checkbox:SetPoint("TOPLEFT", self.frame, "TOP", 30, -16 - (row * 24))
        end
        checkbox:SetLabel(track)
        self.checkboxes[track] = checkbox
        tinsert(self.scripts.OnClick, checkbox.Checkbutton)
    end

    self.frame:Hide()

end

-- Reads the upgrade track name (e.g. "Champion") from the item's tooltip, or nil if it has none.
function filter:GetItemInfo(itemLink, bag, slot)
    local tooltipData = C_TooltipInfo.GetBagItem(bag, slot)
    if tooltipData and tooltipData.lines then
        for _, line in ipairs(tooltipData.lines) do
            local track = line.leftText and line.leftText:match(UPGRADE_PATTERN)
            if track then
                return track
            end
        end
    end
    return nil
end

-- check input vs item values
function filter:Check(inputtracks, item)
    if self.frame and item.track then
        return tContains(inputtracks, item.track)
    end
    return false
end

function filter:GetValues()
    if self.frame then
        local tracks = {}
        for _, track in ipairs(TRACKS) do
            if self.checkboxes[track]:GetChecked() then
                tinsert(tracks, track)
            end
        end
        if next(tracks) == nil then
            return nil
        else
            return tracks
        end
    end
    return nil
end

function filter:SetValues(values)
    if self.frame and values ~= nil then
        for _, track in ipairs(TRACKS) do
            self.checkboxes[track]:SetChecked(tContains(values, track))
        end
    end
end

function filter:Clear()
    if self.frame then
        for _, track in ipairs(TRACKS) do
            self.checkboxes[track]:SetChecked(false)
        end
    end
end

EasyDestroy.Filters.RegisterCriteria(filter)

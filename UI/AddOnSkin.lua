--[[
    Adds support for AddOnSkins by Azilroka
    AddOnSkins can be found at https://www.tukui.org/addons.php?id=3
]]

local AS = nil

if not IsAddOnLoaded("AddOnSkins") then return end

if AddOnSkins then
    AS = unpack(AddOnSkins)
end

function AS:EasyDestroy(event, addon)
    --[[ Major Frames ]]
    AS:SkinFrame(EasyDestroyFrame)
    AS:SkinFrame(EasyDestroyItems)
    AS:SkinFrame(EasyDestroySelectedFilters)

    --[[ Buttons ]]
    AS:SkinButton(EasyDestroyFilters_New)
    AS:SkinButton(EasyDestroyFilters_Delete)
    AS:SkinButton(EasyDestroyFilters_NewFromFilter)
    AS:SkinButton(EasyDestroyFilters_Save)
    AS:SkinButton(EasyDestroyButton)
    AS:SkinButton(EasyDestroy_ToggleConfigurator)
    AS:SkinButton(EasyDestroy_OpenBlacklist)

    --[[ Scroll Bars ]]
    AS:SkinScrollBar(EasyDestroySelectedFiltersScrollScrollBar)
    AS:SkinScrollBar(EasyDestroyItemsFrameScrollFrameScrollBar)

    --[[ Dropdowns ]]
    AS:SkinDropDownBox(EasyDestroyDropDown)
    AS:SkinDropDownBox(EasyDestroyFilterTypes)

    local function ApplySkins()

        for i, frame in ipairs(EasyDestroy.FrameRegistry.EditBox) do
            AS:SkinEditBox(frame)
        end

        for i, frame in ipairs(EasyDestroy.FrameRegistry.CheckButton) do
            AS:SkinCheckBox(frame)
        end

    end
    
    ApplySkins()


    --[[ Cleanup ]]
    AS:SkinCloseButton(EasyDestroyFrameClose)
    AS:StripTextures(EasyDestroyFrame.Title)
end

AS:RegisterSkin('EasyDestroy', AS.EasyDestroy)
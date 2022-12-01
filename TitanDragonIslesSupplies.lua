--[[
  TitanDragonIslesSupplies: A simple Display of current Dragon Isles Supplies value
  Author: Blakenfeder
--]]

-- Define addon base object
local TitanDragonIslesSupplies = {
  Const = {
    Id = "DragonIslesSupplies",
    Name = "TitanDragonIslesSupplies",
    DisplayName = "Titan Panel [Dragon Isles Supplies]",
    Version = "",
    Author = "",
  },
  IsInitialized = false,
}
function TitanDragonIslesSupplies.GetCurrencyInfo()
  local i = 0
  for i = 1, C_CurrencyInfo.GetCurrencyListSize(), 1 do
    info = C_CurrencyInfo.GetCurrencyListInfo(i)    
    if tostring(info.iconFileID) == "2065578" then
      return info
    end
  end
end
function TitanDragonIslesSupplies.Util_GetFormattedNumber(number)
  if number >= 1000 then
    return string.format("%d,%03d", number / 1000, number % 1000)
  else
    return string.format ("%d", number)
  end
end

-- Load metadata
TitanDragonIslesSupplies.Const.Version = GetAddOnMetadata(TitanDragonIslesSupplies.Const.Name, "Version")
TitanDragonIslesSupplies.Const.Author = GetAddOnMetadata(TitanDragonIslesSupplies.Const.Name, "Author")

-- Text colors (AARRGGBB)
local BKFD_C_BURGUNDY = "|cff993300"
local BKFD_C_GRAY = "|cff999999"
local BKFD_C_GREEN = "|cff00ff00"
local BKFD_C_ORANGE = "|cffff8000"
local BKFD_C_RED = "|cffff0000"
local BKFD_C_WHITE = "|cffffffff"
local BKFD_C_YELLOW = "|cffffcc00"

-- Text item colors (AARRGGBB)
local BKFD_C_COMMON = "|cffffffff"
local BKFD_C_UNCOMMON = "|cff1eff00"
local BKFD_C_RARE = "|cff0070dd"
local BKFD_C_EPIC = "|cffa335ee"
local BKFD_C_LEGENDARY = "|cffff8000"
local BKFD_C_ARTIFACT = "|cffe5cc80"
local BKFD_C_BLIZZARD = "|cff00ccff"

-- Load Library references
local LT = LibStub("AceLocale-3.0"):GetLocale("Titan", true)
local L = LibStub("AceLocale-3.0"):GetLocale(TitanDragonIslesSupplies.Const.Id, true)

-- Currency update variables
local BKFD_CQ_UPDATE_FREQUENCY = 0.0
local currencyCount = 0.0
local currencyMaximum
local seasonalCount = 0.0
local isSeasonal = false
local currencyDiscovered = false

function TitanPanelDragonIslesSuppliesButton_OnLoad(self)
  self.registry = {
    id = TitanDragonIslesSupplies.Const.Id,
    category = "Information",
    version = TitanDragonIslesSupplies.Const.Version,
    menuText = L["BKFD_TITAN_DIR_MENU_TEXT"], 
    buttonTextFunction = "TitanPanelDragonIslesSuppliesButton_GetButtonText",
    tooltipTitle = BKFD_C_COMMON..L["BKFD_TITAN_DIR_TOOLTIP_TITLE"],
    tooltipTextFunction = "TitanPanelDragonIslesSuppliesButton_GetTooltipText",
    icon = "Interface\\Icons\\inv_faction_warresources",
    iconWidth = 16,
    controlVariables = {
      ShowIcon = true,
      ShowLabelText = true,
    },
    savedVariables = {
      ShowIcon = 1,
      ShowLabelText = false,
      ShowColoredText = false,
    },
    -- frequency = 2,
  };


  self:RegisterEvent("PLAYER_ENTERING_WORLD");
  self:RegisterEvent("PLAYER_LOGOUT");
end

function TitanPanelDragonIslesSuppliesButton_GetButtonText(id)
  local currencyCountText
  if not currencyCount then
    currencyCountText = "0"
  else  
    currencyCountText = TitanDragonIslesSupplies.Util_GetFormattedNumber(currencyCount)
  end

  if (currencyMaximum and not(currencyMaximum == 0) and currencyCount and currencyMaximum == currencyCount) then
    currencyCountText = BKFD_C_RED..currencyCountText
  end

  return L["BKFD_TITAN_DIR_BUTTON_LABEL"], TitanUtils_GetHighlightText(currencyCountText)
end

function TitanPanelDragonIslesSuppliesButton_GetTooltipText()
  if (not currencyDiscovered) then
    return
      L["BKFD_TITAN_DIR_TOOLTIP_DESCRIPTION"].."\r"..
      " \r"..
      TitanUtils_GetHighlightText(L["BKFD_TITAN_DIR_TOOLTIP_NOT_YET_DISCOVERED"])
  end

  -- Set which total value will be displayed
  local tooltipCurrencyCount = currencyCount
  if (isSeasonal) then
    tooltipCurrencyCount = seasonalCount
  end

  -- Set how the total value will be displayed
  local totalValue = string.format(
    "%s/%s",
    TitanDragonIslesSupplies.Util_GetFormattedNumber(tooltipCurrencyCount),
    TitanDragonIslesSupplies.Util_GetFormattedNumber(currencyMaximum)
  )
  if (not currencyMaximum or currencyMaximum == 0) then
    totalValue = string.format(
      "%s",
      TitanDragonIslesSupplies.Util_GetFormattedNumber(tooltipCurrencyCount)
    )
  elseif (currencyMaximum == tooltipCurrencyCount) then
    totalValue = BKFD_C_RED..totalValue
  end
  
  local totalLabel = L["BKFD_TITAN_DIR_TOOLTIP_COUNT_LABEL_TOTAL_MAXIMUM"]
  if (isSeasonal) then
    totalLabel = L["BKFD_TITAN_DIR_TOOLTIP_COUNT_LABEL_TOTAL_SEASONAL"]
  elseif (not currencyMaximum or currencyMaximum == 0) then
    totalLabel = L["BKFD_TITAN_DIR_TOOLTIP_COUNT_LABEL_TOTAL"]
  end

  return
    L["BKFD_TITAN_DIR_TOOLTIP_DESCRIPTION"].."\r"..
    " \r"..
    totalLabel..TitanUtils_GetHighlightText(totalValue)
end

function TitanPanelDragonIslesSuppliesButton_OnUpdate(self, elapsed)
  BKFD_CQ_UPDATE_FREQUENCY = BKFD_CQ_UPDATE_FREQUENCY - elapsed;

  if BKFD_CQ_UPDATE_FREQUENCY <= 0 then
    BKFD_CQ_UPDATE_FREQUENCY = 1;

    local info = TitanDragonIslesSupplies.GetCurrencyInfo()
    if (info) then
      currencyDiscovered = true
      currencyCount = tonumber(info.quantity)
      currencyMaximum = tonumber(info.maxQuantity)
      seasonalCount = tonumber(info.totalEarned)
      isSeasonal = info.useTotalEarnedForMaxQty
    end

    TitanPanelButton_UpdateButton(TitanDragonIslesSupplies.Const.Id)
  end
end

function TitanPanelDragonIslesSuppliesButton_OnEvent(self, event, ...)
  if (event == "PLAYER_ENTERING_WORLD") then
    if (not TitanDragonIslesSupplies.IsInitialized and DEFAULT_CHAT_FRAME) then
      DEFAULT_CHAT_FRAME:AddMessage(
        BKFD_C_YELLOW..TitanDragonIslesSupplies.Const.DisplayName.." "..
        BKFD_C_GREEN..TitanDragonIslesSupplies.Const.Version..
        BKFD_C_YELLOW.." by "..
        BKFD_C_ORANGE..TitanDragonIslesSupplies.Const.Author)
      -- TitanDragonIslesSupplies.GetCurrencyInfo()
      TitanPanelButton_UpdateButton(TitanDragonIslesSupplies.Const.Id)
      TitanDragonIslesSupplies.IsInitialized = true
    end
    return;
  end  
  if (event == "PLAYER_LOGOUT") then
    TitanDragonIslesSupplies.IsInitialized = false;
    return;
  end
end

function TitanPanelRightClickMenu_PrepareDragonIslesSuppliesMenu()
  local id = TitanDragonIslesSupplies.Const.Id;

  TitanPanelRightClickMenu_AddTitle(TitanPlugins[id].menuText)
  
  TitanPanelRightClickMenu_AddToggleIcon(id)
  TitanPanelRightClickMenu_AddToggleLabelText(id)
  TitanPanelRightClickMenu_AddSpacer()
  TitanPanelRightClickMenu_AddCommand(LT["TITAN_PANEL_MENU_HIDE"], id, TITAN_PANEL_MENU_FUNC_HIDE)
end
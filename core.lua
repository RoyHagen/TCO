-- ============================================================
-- CurrencySummary — shows warbound currency totals per character
-- ============================================================

-- ------------------------------------
-- Currency definitions
-- ------------------------------------
-- priority: higher value = shown first; omit for default (sorts by ID descending)
local currencyIDs = {
    -- Midnight
    [3316] = { id = 3316, name = "Voidlight Marl",  priority = 100 },
    [3385] = { id = 3385, name = "Luminous Dust",  priority = 99 },
    [3379] = { id = 3379, name = "Brimming Arcana",  priority = 98 },
    [3319] = { id = 3319, name = "Twilight's Blade Insignia" }, -- prepatch

    -- The War Within
    [3093] = { id = 3093, name = "Nerub-ar Finery" },
    [3089] = { id = 3089, name = "Residual Memories" },        -- prepatch
    [3056] = { id = 3056, name = "Kej" },
    [3055] = { id = 3055, name = "Mereldar Derby Mark" },
    [2815] = { id = 2815, name = "Resonance Crystals",        priority = 90 },
    [2803] = { id = 2803, name = "Undercoin",                 priority = 90 },
    [2657] = { id = 2657, name = "Mysterious Fragment" },
    [2594] = { id = 2594, name = "Paracausal Flakes" },
    [2588] = { id = 2588, name = "Riders of Azeroth Badge" },
    [2118] = { id = 2118, name = "Elemental Overflow" },
    [2009] = { id = 2009, name = "Cosmic Flux" },
    [2003] = { id = 2003, name = "Dragon Isles Supplies" },
    [1979] = { id = 1979, name = "Cyphers of the First Ones" },
    [1931] = { id = 1931, name = "Cataloged Research" },
    [1906] = { id = 1906, name = "Soul Cinders" },
    [1885] = { id = 1885, name = "Grateful Offering" },
    [1828] = { id = 1828, name = "Soul Ash" },
    [1820] = { id = 1820, name = "Infused Ruby" },
    [1792] = { id = 1792, name = "Honor" },
    [1717] = { id = 1717, name = "7th Legion Service Medal" },
    [1716] = { id = 1716, name = "Honorbound Service Medal" },
    [1710] = { id = 1710, name = "Seafarer's Dubloon" },
    [1560] = { id = 1560, name = "War Resources" },
    [1379] = { id = 1379, name = "Trial of Style Token" },
    [1275] = { id = 1275, name = "Curious Coin" },
    [1226] = { id = 1226, name = "Nethershard" },
    [1166] = { id = 1166, name = "Timewarped Badge" },
    [ 777] = { id =  777, name = "Timeless Coin" },
    [ 515] = { id =  515, name = "Darkmoon Prize Ticket" },
    [ 241] = { id =  241, name = "Champion's Seal" },
}

-- Sort: higher priority first; ties broken by ID descending (newest first)
local sortedCurrencyKeys = {}
for k in pairs(currencyIDs) do
    sortedCurrencyKeys[#sortedCurrencyKeys + 1] = k
end
table.sort(sortedCurrencyKeys, function(a, b)
    local prioA = currencyIDs[a].priority or 0
    local prioB = currencyIDs[b].priority or 0
    if prioA ~= prioB then return prioA > prioB end
    return a > b
end)

-- ------------------------------------
-- Layout constants
-- ------------------------------------
local FRAME_WIDTH    = 300
local LINE_TOP_INSET = -15   -- first child offset from frame top
local LINE_TITLE_Y   = -20   -- title font Y inside a line frame
local LINE_CONTENT_Y = -35   -- content font Y inside a line frame
local ARROW_SIZE_W   = 32
local ARROW_SIZE_H   = 16

-- ------------------------------------
-- Main frame
-- ------------------------------------
local CurrencySummaryFrame = CreateFrame("Frame", "CurrencySummaryFrame", UIParent, "BackdropTemplate")
CurrencySummaryFrame:ClearAllPoints()
CurrencySummaryFrame:SetSize(FRAME_WIDTH, 1)
CurrencySummaryFrame:SetPoint("TOPLEFT", "TokenFrame", "TOPRIGHT")
CurrencySummaryFrame:Hide()

CurrencySummaryFrame:SetBackdrop({
    bgFile   = "Interface\\Glues\\Common\\Glue-Tooltip-Background",
    edgeFile = "Interface\\Glues\\Common\\Glue-Tooltip-Border",
    tile     = true,
    tileEdge = true,
    tileSize = 16,
    edgeSize = 16,
    insets   = { left = 10, right = 5, top = 4, bottom = 9 },
})
CurrencySummaryFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.7)
CurrencySummaryFrame:OnBackdropLoaded()

-- Header bar
CurrencySummaryFrame.headerBar = CurrencySummaryFrame:CreateTexture(nil, "BACKGROUND")
CurrencySummaryFrame.headerBar:SetDrawLayer("BACKGROUND", 2)
CurrencySummaryFrame.headerBar:SetColorTexture(0.25, 0.25, 0.25, 1)
CurrencySummaryFrame.headerBar:SetHeight(18)
CurrencySummaryFrame.headerBar:SetPoint("TOPLEFT",  CurrencySummaryFrame, "TOPLEFT",  10, -5)
CurrencySummaryFrame.headerBar:SetPoint("RIGHT",    CurrencySummaryFrame, "RIGHT",    -5,  0)
CurrencySummaryFrame.headerBar:SetAlpha(0.8)

-- Footer bar
CurrencySummaryFrame.footerBar = CurrencySummaryFrame:CreateTexture(nil, "BACKGROUND")
CurrencySummaryFrame.footerBar:SetDrawLayer("BACKGROUND", 2)
CurrencySummaryFrame.footerBar:SetColorTexture(0.25, 0.25, 0.25, 1)
CurrencySummaryFrame.footerBar:SetHeight(17)
CurrencySummaryFrame.footerBar:SetPoint("BOTTOMLEFT", CurrencySummaryFrame, "BOTTOMLEFT", 10, 10)
CurrencySummaryFrame.footerBar:SetPoint("RIGHT",      CurrencySummaryFrame, "RIGHT",      -5,  0)
CurrencySummaryFrame.footerBar:SetAlpha(0.3)

-- Title
CurrencySummaryFrame.title = CurrencySummaryFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
CurrencySummaryFrame.title:SetPoint("TOP", CurrencySummaryFrame, "TOP", 0, -8)
CurrencySummaryFrame.title:SetText("Total transferable | Own currency")

-- ------------------------------------
-- Line factory — creates a reusable line frame with no text set yet.
-- Call line:Populate(titleText, contentText) to fill or refresh it.
-- ------------------------------------
local function CreateCurrencyLine(parentFrame)
    local lineFrame = CreateFrame("Frame", nil, parentFrame)
    lineFrame:SetWidth(parentFrame:GetWidth() - 20)
    lineFrame:SetHeight(25)

    local arrow = lineFrame:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(ARROW_SIZE_W, ARROW_SIZE_H)
    arrow:SetTexture("Interface\\Buttons\\UI-SortArrow")

    local title = lineFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 20, LINE_TITLE_Y)
    title:SetJustifyH("LEFT")

    local content = lineFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    content:SetPoint("TOPLEFT", 40, LINE_CONTENT_Y)
    content:SetJustifyH("LEFT")
    content:SetWidth(lineFrame:GetWidth() - 10)
    content:SetWordWrap(true)

    local function SetCollapsed()
        content:Hide()
        lineFrame:SetHeight(25)
        arrow:SetRotation(math.pi / 2)
        arrow:SetPoint("TOPLEFT", -5, -(20 - 10))
    end

    local function SetExpanded()
        content:Show()
        lineFrame:SetHeight(25 + content:GetStringHeight() + 5)
        arrow:SetPoint("TOPLEFT", 0, -20)
        arrow:SetRotation(0)
    end

    local function ToggleContent()
        if content:IsShown() then
            SetCollapsed()
        else
            SetExpanded()
        end
        parentFrame:AdjustHeightAndReposition()
    end

    arrow:SetScript("OnMouseDown", ToggleContent)
    title:SetScript("OnMouseDown", ToggleContent)

    -- Populate (or refresh) text without recreating any objects
    function lineFrame:Populate(titleText, contentText)
        title:SetText(titleText)
        content:SetText(contentText)
        SetCollapsed()  -- reset to collapsed whenever data is refreshed
    end

    lineFrame:Hide()
    return lineFrame
end

-- Pre-create one line per currency entry at load time (never recreated)
local currencyLines = {}
for _, k in ipairs(sortedCurrencyKeys) do
    currencyLines[k] = CreateCurrencyLine(CurrencySummaryFrame)
end

-- ------------------------------------
-- Height / reposition helpers
-- ------------------------------------
function CurrencySummaryFrame:AdjustHeight()
    local totalHeight = 20
    for _, child in ipairs({ self:GetChildren() }) do
        if child:IsShown() then
            totalHeight = totalHeight + child:GetHeight() - 8
        end
    end
    self:SetHeight(totalHeight)
end

function CurrencySummaryFrame:AdjustHeightAndReposition()
    local previousLine
    for _, child in ipairs({ self:GetChildren() }) do
        if child:IsShown() then
            if previousLine then
                child:SetPoint("TOPLEFT", previousLine, "BOTTOMLEFT", 0, 10)
            else
                child:SetPoint("TOPLEFT", self, "TOPLEFT", 10, LINE_TOP_INSET)
            end
            previousLine = child
        end
    end
    self:AdjustHeight()
end

-- ------------------------------------
-- TokenFrame hooks
-- ------------------------------------
TokenFrame:HookScript("OnShow", function()
    for _, k in ipairs(sortedCurrencyKeys) do
        local entry       = currencyIDs[k]
        local accountData = C_CurrencyInfo.FetchCurrencyDataFromAccountCharacters(entry.id)
        local line        = currencyLines[k]
        if accountData then
            local totalCurrency = 0
            local characterList = ""
            for _, charData in pairs(accountData) do
                totalCurrency = totalCurrency + charData.quantity
                characterList = characterList .. charData.characterName .. ": " .. charData.quantity .. "\n"
            end

            local ownQuantity = C_CurrencyInfo.GetCurrencyInfo(entry.id).quantity
            line:Populate(
                entry.name .. ": " .. totalCurrency .. " | " .. ownQuantity,
                characterList
            )
            line:Show()
        else
            line:Hide()
        end
    end

    CurrencySummaryFrame:AdjustHeightAndReposition()
    CurrencySummaryFrame:Show()
end)

TokenFrame:HookScript("OnHide", function()
    for _, line in pairs(currencyLines) do
        line:Hide()
    end
    CurrencySummaryFrame:Hide()
end)

-- ------------------------------------
-- Request account currency data on login
-- ------------------------------------
CurrencySummaryFrame:RegisterEvent("PLAYER_LOGIN")
CurrencySummaryFrame:SetScript("OnEvent", function(self)
    C_CurrencyInfo.RequestCurrencyDataForAccountCharacters()
    self:UnregisterEvent("PLAYER_LOGIN")
end)

-- ACCOUNT_CHARACTER_CURRENCY_DATA_RECEIVED
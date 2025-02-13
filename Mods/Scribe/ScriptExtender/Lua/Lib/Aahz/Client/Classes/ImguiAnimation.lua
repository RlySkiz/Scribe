RX = RX or require("Lib.ReactiveX.reactivex._init")
Imgui = Imgui or {}

-- Internal animation tick setup
Imgui._mainScheduler = RX.CooperativeScheduler.Create()
Imgui.MainTick = RX.Subject.FromCoroutine(function()
    local i = 1
    while true do
        _P(i)
        coroutine.yield(i)
        if i >= 60 then i = 0 else i = i + 1 end
    end
end, Imgui._mainScheduler)
local fps = 1/60
Ext.Timer.WaitForRealtime(fps, function() Imgui._mainScheduler:Update(fps*.001) end, fps)

---Animates an imgui element's GuiColor colorProp between an initial and highlight color for a short time
---@param el ExtuiStyledRenderable
---@param colorProp GuiColor
---@param initialColor vec4
---@param highlightColor vec4
---@param animationLength integer # length in frames, ideally multiples of 60 for smooth tweening, since internal tick is 60 fps
function Imgui.AnimateColor(el, colorProp, initialColor, highlightColor, animationLength)
    local framesPassed = 0

    -- based on frame number (1-60), lerp between initial color and highlight color
    local function simpleTween(frame)
        framesPassed = framesPassed + 1

        -- adjust frame - 1 so initial sine input results at 0
        local adjustedFrame = frame - 1
        -- it's a waaaaave, oscillate percent between 0 and 100 twice per second
        local percent = (math.sin(adjustedFrame * math.pi / 30 - math.pi / 2) + 1) * 50

        el:SetColor(colorProp, Helpers.Color.NormalizedLerp(initialColor, highlightColor, percent))
    end
    local function resetColor() el:SetColor(colorProp, initialColor) _P(string.format("Reset to: <%s, %s, %s, %s>", table.unpack(initialColor))) end
    Imgui.MainTick:Take(animationLength):Subscribe(simpleTween, resetColor, resetColor)
end

-- local testWin
-- -- Test animation only
-- Ext.Events.ResetCompleted:Subscribe(function()
--     testWin = Imgui.CreateCommonWindow("Testing Color Animation")
--     testWin.Open = true
--     Ext.OnNextTick(function()
--         testWin:SetColor("WindowBg", Imgui.Colors.Blue)
--     end)
-- end)
-- Ext.RegisterConsoleCommand("blue", function()
--     Imgui.AnimateColor(testWin, "WindowBg", Imgui.Colors.Blue, Imgui.Colors.White, 120)
-- end)
-- Ext.RegisterConsoleCommand("green", function()
--     Imgui.AnimateColor(testWin, "WindowBg", Imgui.Colors.MediumSeaGreen, Imgui.Colors.White, 120)
-- end)

---@param el ExtuiTreeParent
---@param iconName string # name defined in atlas
---@param displaySize vec2 # ie- {64, 64} size of imgui image to display
---@param iconSize integer # square icons only, size of icon in atlas
---@param iconsPerRow integer # count of icons per row in atlas
---@param textureSize integer # square atlas only, size of full atlased texture
---@param frameCount integer # number of animation frames -1, before looping
---@param speed integer? # speed in ms, default 30 (40 fps, 60 fps would be 16 [1/60]),
---@return ExtuiImage
function Imgui.CreateAnimation(el, iconName, displaySize, iconSize, iconsPerRow, textureSize, frameCount, speed)
    speed = speed or 30
    local animImage = el:AddImage(iconName, displaySize)

    local function getUVsForFrame(index)
        -- local iconsPerRow = 3
        -- local iconSize = 96
        -- local textureSize = 288

        local iconX = index % iconsPerRow
        local iconY = math.floor(index / iconsPerRow)

        iconY = iconY % iconsPerRow -- safety wrap?

        local uStart = iconX * iconSize / textureSize
        local vStart = iconY * iconSize / textureSize
        local uEnd = (iconX + 1) * iconSize / textureSize
        local vEnd = (iconY + 1) * iconSize / textureSize

        return uStart, vStart, uEnd, vEnd
    end
    local scheduler = RX.CooperativeScheduler.Create()

    local animObservable = RX.Observable.FromCoroutine(function()
        local i = 0
        while true do
            coroutine.yield(i)
            if i >= frameCount then
                i = 0
            else
                i = i + 1
            end
        end
    end, scheduler)

    animObservable:Subscribe(function(i)
            -- local txt = animText
            if animImage ~= nil then
                -- txt.Label = string.format("Frame: %s", i)
                local currentU0,currentV0,currentU1,currentV1 = getUVsForFrame(i)
                animImage.ImageData.UV0 = { currentU0, currentV0}
                animImage.ImageData.UV1 = { currentU1, currentV1}
            end
        end)

    local fixedTime = 0 -- Ext.Timer to drive the scheduler's internal clock every 1/60 second (0.016)
    -- Ext.Timer.WaitForRealtime(16, function() scheduler:update(.016) fixedTime = fixedTime+.016 end, 16)
    Ext.Timer.WaitForRealtime(speed, function() scheduler:Update(speed*.001) fixedTime = fixedTime+(speed*.001) end, speed) -- slow down 1/40
    return animImage
end
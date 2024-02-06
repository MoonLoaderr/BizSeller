local ffi = require("ffi")
local imgui = require("mimgui")
local inicfg = require("inicfg")
local encoding = require("encoding")
local sampev = require("samp.events")
local res, socket = pcall(require, 'socket') assert(res, 'Lib SOCKET not found')
encoding.default = "CP1251"
local u8 = encoding.UTF8
local fileName = "BizSeller.ini"
local config = inicfg.load({
    main = {
        time = "4:34:00",
        floodDelay = 0,
        numberCard = "",
        vk = "",
        qiwi = "",
        enabled = false,
        autoConnect = false,
        type = 1,
        autoDisablePC = false
    }
}, fileName)
local window = imgui.new.bool(false)
local inputsDialog = false
local vkInput = imgui.new.char[256](config.main.vk)
local cardIdInput = imgui.new.char[256](u8(config.main.numberCard))
local qiwi = imgui.new.char[256](config.main.qiwi)
local connectTime = imgui.new.char[256](config.main.time)
local delay = imgui.new.int(config.main.floodDelay)
local selectSpawn = false
local try = 0
local type = { u8"Карта банка", u8"QIWI"}
local imType = imgui.new["const char*"][#type](type)
local imTypeInt = imgui.new.int(0)
local sellBizDial = false
local autoDialogResponse = { imgui.new.bool(false), imgui.new.bool(false) }
local dialogButtonsText = { "", "" }
local dialogsResponse = { 3, 0, 8 }
local delayDialogResponse = {} -- [1] - spawn, [2] - select biz, [3] - enter, [4] - select sell biz, [5] - enter, [6] - send vk, [7] - send qiwi or card, [8] - enter
local timeOnShowDialog = { {}, {}, {}, {}, {}, {}, {}, {} }
local timeOnSendDialogResponse = { {}, {}, {}, {}, {}, {}, {}, {} }
local disable = imgui.new.bool(config.main.autoDisablePC)
local version = 1.04

imgui.OnInitialize(function() 
    imgui.GetIO().IniFilename = nil
    local style = imgui.GetStyle()
    local colors = style.Colors

    colors[imgui.Col.Text] = imgui.ImVec4(0.87, 0.87, 0.87, 1.00)
    colors[imgui.Col.TextDisabled] = imgui.ImVec4(0.46, 0.46, 0.46, 1.00)
    colors[imgui.Col.WindowBg] = imgui.ImVec4(0.12, 0.10, 0.16, 1.00)
    colors[imgui.Col.ChildBg] = imgui.ImVec4(0.11, 0.10, 0.16, 0.98)
    colors[imgui.Col.PopupBg] = imgui.ImVec4(0.11, 0.10, 0.16, 0.98)
    colors[imgui.Col.Border] = imgui.ImVec4(0.11, 0.10, 0.16, 0.00)
    colors[imgui.Col.BorderShadow] = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[imgui.Col.FrameBg] = imgui.ImVec4(0.08, 0.07, 0.12, 0.98)
    colors[imgui.Col.FrameBgHovered] = imgui.ImVec4(0.14, 0.11, 0.21, 0.98)
    colors[imgui.Col.FrameBgActive] = imgui.ImVec4(0.16, 0.14, 0.23, 0.98)
    colors[imgui.Col.TitleBg] = imgui.ImVec4(0.15, 0.13, 0.21, 0.98)
    colors[imgui.Col.TitleBgActive] = imgui.ImVec4(0.18, 0.16, 0.25, 0.98)
    colors[imgui.Col.TitleBgCollapsed] = imgui.ImVec4(0.11, 0.10, 0.16, 0.98)
    colors[imgui.Col.MenuBarBg] = imgui.ImVec4(0.11, 0.10, 0.16, 0.98)
    colors[imgui.Col.ScrollbarBg] = imgui.ImVec4(0.11, 0.10, 0.16, 0.98)
    colors[imgui.Col.ScrollbarGrab] = imgui.ImVec4(0.08, 0.07, 0.12, 0.58)
    colors[imgui.Col.ScrollbarGrabHovered] = imgui.ImVec4(0.08, 0.07, 0.11, 0.71)
    colors[imgui.Col.ScrollbarGrabActive] = imgui.ImVec4(0.15, 0.13, 0.21, 0.58)
    colors[imgui.Col.CheckMark] = imgui.ImVec4(0.35, 0.30, 0.47, 1.00)
    colors[imgui.Col.SliderGrab] = imgui.ImVec4(0.19, 0.17, 0.28, 0.98)
    colors[imgui.Col.SliderGrabActive] = imgui.ImVec4(0.21, 0.19, 0.30, 0.98)
    colors[imgui.Col.Button] = imgui.ImVec4(0.18, 0.16, 0.24, 0.53)
    colors[imgui.Col.ButtonHovered] = imgui.ImVec4(0.24, 0.21, 0.32, 0.65)
    colors[imgui.Col.ButtonActive] = imgui.ImVec4(0.26, 0.23, 0.35, 1.00)
    colors[imgui.Col.Header] = imgui.ImVec4(0.09, 0.07, 0.13, 0.70)
    colors[imgui.Col.HeaderHovered] = imgui.ImVec4(0.08, 0.07, 0.11, 0.85)
    colors[imgui.Col.HeaderActive] = imgui.ImVec4(0.09, 0.08, 0.12, 1.00)
    colors[imgui.Col.Separator] = imgui.ImVec4(0.17, 0.15, 0.23, 0.72)
    colors[imgui.Col.SeparatorHovered] = imgui.ImVec4(0.11, 0.10, 0.16, 1.00)
    colors[imgui.Col.SeparatorActive] = imgui.ImVec4(0.22, 0.19, 0.30, 0.70)
    colors[imgui.Col.ResizeGrip] = imgui.ImVec4(0.16, 0.13, 0.23, 0.38)
    colors[imgui.Col.ResizeGripHovered] = imgui.ImVec4(0.19, 0.17, 0.25, 0.70)
    colors[imgui.Col.ResizeGripActive] = imgui.ImVec4(0.19, 0.17, 0.25, 1.00)
    colors[imgui.Col.Tab] = imgui.ImVec4(0.23, 0.19, 0.32, 0.26)
    colors[imgui.Col.TabHovered] = imgui.ImVec4(0.10, 0.09, 0.15, 1.00)
    colors[imgui.Col.TabActive] = imgui.ImVec4(0.30, 0.25, 0.43, 0.51)
    colors[imgui.Col.TabUnfocused] = imgui.ImVec4(0.27, 0.28, 0.30, 0.97)
    colors[imgui.Col.TabUnfocusedActive] = imgui.ImVec4(0.17, 0.17, 0.18, 1.00)
    colors[imgui.Col.PlotLines] = imgui.ImVec4(0.61, 0.61, 0.61, 1.00)
    colors[imgui.Col.PlotLinesHovered] = imgui.ImVec4(1.00, 0.43, 0.35, 1.00)
    colors[imgui.Col.PlotHistogram] = imgui.ImVec4(0.90, 0.70, 0.00, 1.00)
    colors[imgui.Col.PlotHistogramHovered] = imgui.ImVec4(1.00, 0.60, 0.00, 1.00)
    colors[imgui.Col.TextSelectedBg] = imgui.ImVec4(0.26, 0.59, 0.98, 0.35)
    colors[imgui.Col.DragDropTarget] = imgui.ImVec4(1.00, 1.00, 0.00, 0.90)
    colors[imgui.Col.NavHighlight] = imgui.ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[imgui.Col.NavWindowingHighlight] = imgui.ImVec4(1.00, 1.00, 1.00, 0.70)
    colors[imgui.Col.NavWindowingDimBg] = imgui.ImVec4(0.80, 0.80, 0.80, 0.20)
    colors[imgui.Col.ModalWindowDimBg] = imgui.ImVec4(0.34, 0.22, 0.22, 0.35)

    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
style.GrabRounding = 12
style.ScrollbarRounding = 12
style.PopupRounding = 6
style.FrameRounding = 6
end) 

imgui.OnFrame(function() return window[0] end, function() 
    local size, res = imgui.ImVec2(440, 210), imgui.ImVec2(getScreenResolution())
    imgui.SetNextWindowPos(imgui.ImVec2(res.x / 2 - size.x / 2, res.y / 2 - size.y / 2), imgui.Cond.FirstUseEver)
    imgui.SetNextWindowSize(imgui.ImVec2(size.x, size.y), imgui.Cond.FirstUseEver)

    if(imgui.Begin("BizSeller v" .. version, window, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)) then

        if(imgui.CollapsingHeader(u8"Information")) then

            imgui.Text(string.format("Delay response on dialog:\nSelect spawn: %s ms\nSelect biz: %s ms\nEnter: %s ms\nSend VK: %s ms\nSend Card/QIWI: %s ms\nEnter: %s ms", 
            (#delayDialogResponse < 1) and "null" or delayDialogResponse[1], (#delayDialogResponse < 2) and "null" or delayDialogResponse[2], (#delayDialogResponse < 3) and "null" or 
            delayDialogResponse[3], (#delayDialogResponse < 4) and "null" or delayDialogResponse[4], (#delayDialogResponse < 5) and "null" or delayDialogResponse[5], 
            (#delayDialogResponse < 6) and "null" or delayDialogResponse[6], (#delayDialogResponse < 7) and "null" or delayDialogResponse[7], (#delayDialogResponse < 8) and "null" or delayDialogResponse[8]))
        end

        imgui.Separator()

        if(imgui.Combo("##dsmvru9", imTypeInt, imType, #type)) then
            config.main.type = imTypeInt[0] + 1
            inicfg.save(config, fileName)
        end

        imgui.SameLine()
        if(imgui.Checkbox("##34608734", disable)) then
            config.main.autoDisablePC = disable[0]
            inicfg.save(config, fileName)
        end
        imgui.SameLine()
        imgui.Question(u8"Данная функция выключит пк через 5 минут после попытки слить биз")

        if(imgui.InputTextWithHint("##asd", u8"Введите ссылку на свой вк, например: https://vk.com/username", vkInput, 256)) then
            config.main.vk = ffi.string(vkInput)
            inicfg.save(config, fileName)
        end

        imgui.SameLine()
        imgui.Checkbox("##cf6089", autoDialogResponse[1])
        imgui.SameLine()

        if(imgui.Button((getClipboardText() == ffi.string(vkInput)) and "Copied!" or "Copy")) then
            setClipboardText(ffi.string(vkInput))
            if(sampIsDialogActive() and sampGetCurrentDialogType() == DIALOG_STYLE_INPUT and autoDialogResponse[1][0]) then
                local thread = lua_thread.create(function() 
                    sampSendDialogResponse(sampGetCurrentDialogId(), 1, 0, getClipboardText())
                end)
                thread:terminate()
            end
        end
        
        imgui.Question(u8"Если включен checkbox, то скрипт автоматически ответит на диалог")

        if(config.main.type == 1) then
            if(imgui.InputTextWithHint("##assd", u8"Введите номер своей карты и банк, например: 0000 0000 0000 0000 (Карта банка \"MonoBank\")", cardIdInput, 256)) then
                config.main.numberCard = u8:decode(ffi.string(cardIdInput))
                inicfg.save(config, fileName)
                sampAddChatMessage((config.main.numberCard), -1)
            end

            imgui.SameLine()
            imgui.Checkbox("##0e45jv", autoDialogResponse[2])
            imgui.SameLine()

            if(imgui.Button((getClipboardText() == config.main.numberCard) and "Copied!" or "Copy")) then
                setClipboardText(config.main.numberCard)
                if(sampIsDialogActive() and sampGetCurrentDialogType() == DIALOG_STYLE_INPUT and autoDialogResponse[2][0]) then
                    local thread = lua_thread.create(function() 
                        sampSendDialogResponse(sampGetCurrentDialogId(), 1, 0, getClipboardText())
                    end)
                    thread:terminate()
                end
            end
        else
            if(imgui.InputTextWithHint("##assddsd", u8"Введите номер QIWI, например: +193291319319", qiwi, 256)) then
                config.main.qiwi = ffi.string(qiwi)
                inicfg.save(config, fileName)
            end

            imgui.SameLine()

            if(imgui.Button((getClipboardText()== ffi.string(qiwi)) and "Copied!" or "Copy")) then
                setClipboardText(ffi.string(qiwi))
                if(sampIsDialogActive() and sampGetCurrentDialogType() == DIALOG_STYLE_INPUT and autoDialogResponse[2][0]) then
                    local thread = lua_thread.create(function() 
                        sampSendDialogResponse(sampGetCurrentDialogId(), 1, 0, getClipboardText())
                    end)
                    thread:terminate()
                end
            end
        end

        imgui.Question(u8"Если включен checkbox, то скрипт автоматически ответит на диалог")

        
        if(imgui.InputTextWithHint("##asssd", u8"Введите время в какое сливать биз, например: 4:34:00", connectTime, 256)) then 
            config.main.time = ffi.string(connectTime)
            inicfg.save(config, fileName)
        end

        imgui.Question(u8"За минуту до указаного времени скрипт начнет подключатся к серверу и сам выберет спавн\nВ указаное время начнет сливать бизнес за реал")


        if(imgui.SliderInt("##odfh6td9f6", delay, 0, 2000)) then
            config.main.floodDelay = delay[0]
            inicfg.save(config, fileName)
        end

        imgui.Question(u8"Задержка в миллисекундах между попытками слить бизнес за реал")
        imgui.PushItemWidth(415)

        if(imgui.Button((config.main.enabled) and u8"Выключить" or u8"Включить")) then
            config.main.enabled = not config.main.enabled
            inicfg.save(config, fileName)
        end

        imgui.PopItemWidth()
    end
end)

function main() 
    while not isSampAvailable() do wait(0) end
    sampRegisterChatCommand("bs", function() 
        window[0] = not window[0]
    end)
    
    lua_thread.create(function() 
        while true do wait(1000) 
            -- Счет инфы
                if(config.main.enabled) then
                    for i = 1, #timeOnShowDialog do 
                        local sum = 0
                        local num = 0
                        for ii = 1, #timeOnShowDialog[i] do
                            if(#timeOnSendDialogResponse[i] >= ii) then
                                timeOnSendDialogResponse[i][ii] = (timeOnSendDialogResponse[i][ii] <= 100 and timeOnShowDialog[i][ii] >= 800) and timeOnSendDialogResponse[i][ii] * 10 or timeOnSendDialogResponse[i][ii]
                                timeOnShowDialog[i][ii] = (timeOnShowDialog[i][ii] <= 100 and timeOnSendDialogResponse[i][ii] >= 800) and timeOnShowDialog[i][ii] * 10 or timeOnShowDialog[i][ii]
                                sum = (ii > 1) and timeOnSendDialogResponse[i][ii] - timeOnShowDialog[i][ii] or 0
                                num = num + 1
                            end
                        end
                        delayDialogResponse[i] = string.match(sum / num, "%P+")
                    end
                end
            end
        end)
    while true do wait(0) 
        local ctime = os.date("*t")
        local time = string.format("%02d:%02d:%02d", ctime.hour, ctime.min, ctime.sec)
        local curHours, curMin, curSec = string.match(time, "(%d+):(%d+):(%d+)") -- Время которое сейчас
        local hours, min, sec = string.match(config.main.time, "(%d+):(%d+):(%d+)") -- Время кфг
        if(selectSpawn and config.main.enabled) then
            -- Выбор спавна
            sampSendDialogResponse(sampGetCurrentDialogId(), 1, 4, "")
            sampCloseCurrentDialogWithButton(1)
            selectSpawn = false
        end
        if(curHours == hours and (tonumber(min) - tonumber(curMin)) == 1 and tonumber(curSec) == tonumber(sec)) then
            sampSendChat("/rec")
        end
        if(time == config.main.time) then
            sellBiz()
        end
        if(curHours == hours and (tonumber(curMin) - tonumber(min)) == 5 and tonumber(curSec) == tonumber(sec) and disable[0]) then
            os.execute("shutdown %/s %/t 01")
            wait(1000)
        end
    end
end

function sampev.onSendDialogResponse(dialogId, button, listboxId, inputsDialog) 
    sampAddChatMessage(getTime() .. "onSendDialogResponse: " .. ((button ~= -1) and dialogButtonsText[button] or "Closed dialog (Canceled)"), -1)
    if(config.main.enabled) then
        if(sampGetDialogCaption():find("Выбор места")) then
            table.insert(timeOnSendDialogResponse[1], ms())
        end
        if(sampGetDialogCaption():find("Мои бизнесы")) then
            table.insert(timeOnSendDialogResponse[2], ms())
        end
        if(sampGetDialogCaption():find("Меню")) then
            table.insert(timeOnSendDialogResponse[3], ms())
        end
        if(sampGetDialogCaption():find("Управления бизнесом")) then
            table.insert(timeOnSendDialogResponse[4], ms())
        end
        if(sampGetDialogCaption():find("Продажа бизнеса")) then
            table.insert(timeOnSendDialogResponse[5], ms())
        end
        if(sampGetDialogText():find("Укажите реальную ссылку на страницу")) then 
            table.insert(timeOnSendDialogResponse[6], ms())
        end
        if(sampGetDialogText():find("Укажите реальные реквизиты")) then 
            table.insert(timeOnSendDialogResponse[7], ms())
        end
    end
end

function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
    sampAddChatMessage(getTime() .. "onShowDialog(Title): " .. title, -1)
    dialogButtonsText[1] = button1
    dialogButtonsText[2] = button2
    if(config.main.enabled) then
        if(sampGetDialogCaption():find("Мои бизнесы")) then
            table.insert(timeOnShowDialog[2], ms())
        end
        if(sampGetDialogCaption():find("Меню")) then
            table.insert(timeOnShowDialog[3], ms())
        end
        if(sampGetDialogCaption():find("Управления бизнесом")) then
            table.insert(timeOnShowDialog[4], ms())
        end
        if(sampGetDialogText():find("Укажите реальные реквизиты")) then 
            table.insert(timeOnShowDialog[7], ms())
        end
        if(text:find("Укажите реальную ссылку на страницу")) then
            inputsDialog = true
            table.insert(timeOnShowDialog[6], ms())
        end
        if(title:find("Выбор места")) then
            selectSpawn = true
            table.insert(timeOnShowDialog[1], ms())
        end
        if(title:find("Продажа бизнеса")) then
            sellBizDial = true
            table.insert(timeOnShowDialog[5], ms())
        end
    end
end

function sampev.onServerMessage(color, text) 
    if(text:find("Внимание! Начался аукцион на бизнес")) then
        config.main.enabled = false
        inicfg.save(config, fileName)
    end
end

function sellBiz() 
    while config.main.enabled do wait(config.main.floodDelay)
        sampSendChat("/bizinfo")
        for i = 1, #dialogsResponse do
            while not sampIsDialogActive() do wait(0) end
            sampSendDialogResponse(sampGetCurrentDialogId(), 1, dialogsResponse[i], "")
            sampCloseCurrentDialogWithButton(1)
        end
        if(sellBizDial) then
            sampSendDialogResponse(sampGetCurrentDialogId(), 1, 0, "")
            sampCloseCurrentDialogWithButton(1)
        end
        try = try + 1
        if(inputsDialog) then
            inputsDialog = false
                sampAddChatMessage("Selling biz! Sending vk and card", -1)
                sampSendDialogResponse(sampGetCurrentDialogId(), 1, 0, config.main.vk)
                sampCloseCurrentDialogWithButton(1)
                while not sampIsDialogActive() do wait(0) end
                sampSendDialogResponse(sampGetCurrentDialogId(), 1, 0, config.main.numberCard or config.main.qiwi)
                sampCloseCurrentDialogWithButton(1)
                while not sampIsDialogActive() do wait(0) end
                sampSendDialogResponse(sampGetCurrentDialogId(), 1, 0, "")
                sampCloseCurrentDialogWithButton(1)
                sampAddChatMessage(string.format("Tryed sell biz with info: vk - %s, card - %s", config.main.vk, config.main.numberCard), -1)
                try = 0
                config.main.enabled = false
                inicfg.save(config, fileName)
        else 
            sampAddChatMessage(string.format("Trying sell biz! Try: %s. Failed", try), -1)
        end
    end
end

function imgui.Hint(content)
    if not imgui.IsItemHovered() then
        return
    end
    imgui.BeginTooltip()
    imgui.Text(content)
    imgui.EndTooltip()
end

function imgui.Question(...)
    imgui.SameLine()
    imgui.TextDisabled('(?)')
    imgui.Hint(...)
end

function getTime() 
    local ctime = os.date("*t")
    local time = string.format("%02d:%02d:%02d", ctime.hour, ctime.min, ctime.sec)
    local ms = tostring(math.ceil(socket.gettime()*1000))
    local ms = tonumber(string.sub(ms, #ms-2, #ms))
    return string.format("[%s:%s]: ", time, ms)
end

function ms()
    local ctime = os.date("*t")
    local time = string.format("%02d", ctime.sec)
    local ms = tostring(math.ceil(socket.gettime()*1000))
    local ms = tonumber(string.sub(ms, #ms-2, #ms))
    return tonumber(time .. ms)
end
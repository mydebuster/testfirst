--[[
    Adopt Me - Auto Trade Sender + Acceptor v2.0
    Исправлено: ожидание предметов + повторные подтверждения
--]]

local API = game.ReplicatedStorage.API
local Players = game.Players
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ======== НАСТРОЙКИ ========
local USERNAMES_FILE = "usernames.rfld"
local TRADE_DELAY = 0.5
local BETWEEN_TRADES_DELAY = 3
local WAIT_FOR_ITEMS = 20  -- сколько секунд ждать предметы от второго аккаунта
local CONFIRM_COUNT = 5    -- сколько раз отправлять ConfirmTrade

-- ======== ЧТЕНИЕ ФАЙЛА ========
local function readUsernames()
    local success, content = pcall(function()
        return readfile(USERNAMES_FILE)
    end)
    
    if not success then
        warn("❌ Не удалось прочитать файл: " .. tostring(content))
        return {}
    end
    
    local names = {}
    for name in content:gmatch("[^\r\n]+") do
        name = name:match("^%s*(.-)%s*$")
        if name ~= "" and name:lower() ~= player.Name:lower() then
            table.insert(names, name)
        end
    end
    
    print("📋 Загружено " .. #names .. " имён")
    return names
end

-- ======== ПОИСК ИГРОКА ========
local function findPlayer(username)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Name:lower() == username:lower() then
            return plr
        end
    end
    return nil
end

-- ======== ПРОВЕРКА ПРЕДМЕТОВ В ТРЕЙДЕ ========
local function checkTradeItems()
    local tradeApp = playerGui:FindFirstChild("TradeApp")
    if not tradeApp then return false end
    
    -- Ищем слоты с предметами от другого игрока
    -- Обычно это Frame с предметами, которые предлагает другая сторона
    local offerFrames = {}
    
    -- Разные возможные названия контейнеров предметов
    local possibleNames = {
        "TheirOffer", "OtherOffer", "TradePartnerOffer",
        "RightSide", "TheirItems", "OtherItems",
        "OfferFrame", "TradeSlot"
    }
    
    for _, name in ipairs(possibleNames) do
        local frame = tradeApp:FindFirstChild(name, true)
        if frame then
            table.insert(offerFrames, frame)
        end
    end
    
    -- Проверяем, есть ли дети (предметы) в этих фреймах
    for _, frame in ipairs(offerFrames) do
        local children = frame:GetChildren()
        -- Ищем ImageLabel, ImageButton, ViewportFrame (обычно это иконки предметов)
        for _, child in ipairs(children) do
            if child:IsA("ImageLabel") or child:IsA("ImageButton") or child:IsA("ViewportFrame") then
                return true  -- Нашли хотя бы один предмет
            end
        end
        -- Если есть любые видимые дети кроме UI-украшений
        local visibleChildren = 0
        for _, child in ipairs(children) do
            if child:IsA("GuiObject") and child.Visible then
                visibleChildren = visibleChildren + 1
            end
        end
        if visibleChildren > 2 then  -- больше чем просто рамка и украшения
            return true
        end
    end
    
    return false
end

-- ======== ОЖИДАНИЕ ПРЕДМЕТОВ ========
local function waitForItems()
    print("⏳ Ожидаю предметы от второго аккаунта...")
    
    local waited = 0
    local checkInterval = 0.5
    
    while waited < WAIT_FOR_ITEMS do
        if checkTradeItems() then
            print("   ✅ Предметы обнаружены через " .. waited .. " сек")
            return true
        end
        wait(checkInterval)
        waited = waited + checkInterval
        if math.floor(waited) ~= math.floor(waited - checkInterval) then
            print("   ⏳ Ожидание: " .. math.floor(waited) .. "/" .. WAIT_FOR_ITEMS .. " сек")
        end
    end
    
    print("   ⚠️ Предметы не обнаружены за " .. WAIT_FOR_ITEMS .. " сек, продолжаю...")
    return false
end

-- ======== ПРОВЕРКА АКТИВНОСТИ ТРЕЙДА ========
local function isTradeActive()
    local tradeApp = playerGui:FindFirstChild("TradeApp")
    if not tradeApp or not tradeApp.Enabled then
        return false
    end
    
    local tradeFrame = tradeApp:FindFirstChild("TradeFrame") 
        or tradeApp:FindFirstChild("MainFrame")
        or tradeApp:FindFirstChild("Frame")
    
    return tradeFrame ~= nil and tradeFrame.Visible == true
end

-- ======== ОЖИДАНИЕ ТРЕЙДА ========
local function waitForTradeApp(timeout)
    local waited = 0
    while not isTradeActive() and waited < timeout do
        wait(0.2)
        waited = waited + 0.2
    end
    return isTradeActive()
end

-- ======== ОЖИДАНИЕ ЗАКРЫТИЯ ТРЕЙДА ========
local function waitForTradeClose(timeout)
    local waited = 0
    while isTradeActive() and waited < timeout do
        wait(0.2)
        waited = waited + 0.2
    end
    return waited < timeout
end

-- ======== ОТПРАВКА ЗАПРОСА ========
local function sendTradeRequest(targetPlayer)
    print("📤 Отправляю запрос: " .. targetPlayer.Name)
    
    local sendReq = API:FindFirstChild("TradeAPI/SendTradeRequest")
    if not sendReq then
        warn("❌ SendTradeRequest не найден!")
        return false
    end
    
    local ok, err = pcall(sendReq.FireServer, sendReq, targetPlayer)
    if ok then
        print("   ✅ Запрос отправлен")
        return true
    else
        warn("   ❌ Ошибка: " .. tostring(err))
        return false
    end
end

-- ======== ПРИНЯТИЕ ТРЕЙДА С ПОВТОРНЫМИ ПОДТВЕРЖДЕНИЯМИ ========
local function acceptTrade()
    print("🚀 Начинаю процесс принятия...")
    
    -- Этап 1: Принимаем запрос на трейд
    local acceptReq = API:FindFirstChild("TradeAPI/AcceptOrDeclineTradeRequest")
    if acceptReq then
        local ok, err = pcall(acceptReq.InvokeServer, acceptReq, true)
        if ok then
            print("   ✅ Этап 1: Запрос принят")
        else
            warn("   ❌ Ошибка этапа 1: " .. tostring(err))
            return false
        end
    end
    
    wait(TRADE_DELAY)
    
    -- ЖДЁМ ПРЕДМЕТЫ от второго аккаунта
    waitForItems()
    
    -- Этап 2: Принимаем переговоры
    local acceptNeg = API:FindFirstChild("TradeAPI/AcceptNegotiation")
    if acceptNeg then
        local ok, err = pcall(acceptNeg.FireServer, acceptNeg)
        if ok then
            print("   ✅ Этап 2: Переговоры приняты")
        else
            warn("   ❌ Ошибка этапа 2: " .. tostring(err))
        end
    end
    
    wait(TRADE_DELAY)
    
    -- Этап 3: Множественные подтверждения
    local confirm = API:FindFirstChild("TradeAPI/ConfirmTrade")
    if confirm then
        for i = 1, CONFIRM_COUNT do
            local ok, err = pcall(confirm.FireServer, confirm)
            if ok then
                print("   ✅ Подтверждение " .. i .. "/" .. CONFIRM_COUNT)
            else
                warn("   ❌ Ошибка подтверждения " .. i .. ": " .. tostring(err))
            end
            wait(TRADE_DELAY / 2)  -- небольшая пауза между подтверждениями
        end
    end
    
    print("🏁 Трейд завершён!")
    return true
end

-- ======== ОБРАБОТКА ОДНОГО ТРЕЙДА ========
local function processOneTrade(targetName)
    print("\n" .. string.rep("-", 35))
    print("🎯 Цель: " .. targetName)
    
    local targetPlayer = findPlayer(targetName)
    if not targetPlayer then
        warn("❌ Игрок не найден: " .. targetName)
        return false
    end
    
    print("✅ Игрок найден")
    
    -- Отправляем запрос
    if not sendTradeRequest(targetPlayer) then
        return false
    end
    
    -- Ждём открытия трейда
    print("⏳ Жду ответа от игрока...")
    if not waitForTradeApp(15) then
        warn("❌ Игрок не принял запрос")
        return false
    end
    
    print("🟢 Трейд открыт!")
    wait(0.5)
    
    -- Принимаем
    local success = acceptTrade()
    
    -- Ждём закрытия
    if success then
        print("⏳ Жду закрытия окна...")
        waitForTradeClose(10)
    end
    
    return success
end

-- ======== ГЛАВНАЯ ========
local function main()
    print("=" .. string.rep("=", 40))
    print("🤖 Adopt Me Trade Bot v2.0")
    print("   Ожидание предметов: " .. WAIT_FOR_ITEMS .. " сек")
    print("   Подтверждений: " .. CONFIRM_COUNT)
    print("=" .. string.rep("=", 40))
    print("👤 Ваш ник: " .. player.Name)
    
    local usernames = readUsernames()
    if #usernames == 0 then
        warn("❌ Нет имён в файле")
        return
    end
    
    print("\n📋 Очередь (" .. #usernames .. " игроков):")
    for i, name in ipairs(usernames) do
        print("   " .. i .. ". " .. name)
    end
    
    print("\n🚀 Начинаю...\n")
    
    for i, targetName in ipairs(usernames) do
        print("📊 Прогресс: " .. i .. "/" .. #usernames)
        
        local success = processOneTrade(targetName)
        print(success and "✅ Успех!" or "❌ Неудача")
        
        if i < #usernames then
            print("⏳ Пауза " .. BETWEEN_TRADES_DELAY .. " сек...\n")
            wait(BETWEEN_TRADES_DELAY)
        end
    end
    
    print("\n🏁 Готово! Обработано: " .. #usernames)
end

main()

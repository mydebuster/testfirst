--[[
    Adopt Me - Auto Trade Sender + Acceptor
    Отправляет трейд игрокам из файла и принимает его с их стороны
--]]

local API = game.ReplicatedStorage.API
local Players = game.Players
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ======== НАСТРОЙКИ ========
local USERNAMES_FILE = "usernames.rfld"
local TRADE_DELAY = 0.5
local BETWEEN_TRADES_DELAY = 3  -- задержка между трейдами

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
    
    print("📋 Загружено " .. #names .. " имён (без своего ника)")
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

-- ======== ОТПРАВКА ЗАПРОСА НА ТРЕЙД ========
local function sendTradeRequest(targetPlayer)
    print("📤 Отправляю запрос на трейд: " .. targetPlayer.Name)
    
    local sendReq = API:FindFirstChild("TradeAPI/SendTradeRequest")
    if not sendReq then
        warn("❌ TradeAPI/SendTradeRequest не найден!")
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

-- ======== ОЖИДАНИЕ ПОЯВЛЕНИЯ ТРЕЙДА ========
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
    if waited >= timeout then
        warn("⚠️ Таймаут ожидания закрытия трейда")
        return false
    end
    return true
end

-- ======== ПРИНЯТИЕ ТРЕЙДА (все этапы) ========
local function acceptTrade()
    print("🚀 Принимаю трейд...")
    
    -- Этап 1: AcceptOrDeclineTradeRequest
    local acceptReq = API:FindFirstChild("TradeAPI/AcceptOrDeclineTradeRequest")
    if acceptReq then
        local ok, err = pcall(acceptReq.InvokeServer, acceptReq, true)
        if ok then
            print("   ✅ Запрос принят")
        else
            warn("   ❌ Ошибка: " .. tostring(err))
            return false
        end
    end
    
    wait(TRADE_DELAY)
    
    -- Этап 2: AcceptNegotiation
    local acceptNeg = API:FindFirstChild("TradeAPI/AcceptNegotiation")
    if acceptNeg then
        local ok, err = pcall(acceptNeg.FireServer, acceptNeg)
        if ok then
            print("   ✅ Переговоры приняты")
        else
            warn("   ❌ Ошибка: " .. tostring(err))
        end
    end
    
    wait(TRADE_DELAY)
    
    -- Этап 3: ConfirmTrade (первый раз)
    local confirm = API:FindFirstChild("TradeAPI/ConfirmTrade")
    if confirm then
        local ok, err = pcall(confirm.FireServer, confirm)
        if ok then
            print("   ✅ Подтверждение 1")
        else
            warn("   ❌ Ошибка: " .. tostring(err))
        end
    end
    
    wait(TRADE_DELAY)
    
    -- Этап 4: ConfirmTrade (второй раз - финальное)
    if confirm then
        local ok, err = pcall(confirm.FireServer, confirm)
        if ok then
            print("   ✅ Подтверждение 2 (финальное)")
        else
            warn("   ❌ Ошибка: " .. tostring(err))
        end
    end
    
    print("🏁 Трейд завершён!")
    return true
end

-- ======== ОБРАБОТКА ОДНОГО ТРЕЙДА ========
local function processOneTrade(targetName)
    print("\n" .. string.rep("-", 30))
    print("🎯 Цель: " .. targetName)
    
    -- Ищем игрока
    local targetPlayer = findPlayer(targetName)
    if not targetPlayer then
        warn("❌ Игрок не найден на сервере: " .. targetName)
        return false
    end
    
    print("✅ Игрок найден: " .. targetPlayer.Name)
    
    -- Отправляем запрос на трейд
    local sent = sendTradeRequest(targetPlayer)
    if not sent then
        return false
    end
    
    -- Ждём появления трейд-интерфейса (игрок должен принять запрос)
    print("⏳ Ожидаю, пока игрок примет запрос...")
    local appeared = waitForTradeApp(15)
    
    if not appeared then
        warn("❌ Трейд не появился (игрок не принял или таймаут)")
        return false
    end
    
    print("🟢 Трейд открыт! Принимаю со своей стороны...")
    wait(0.5)
    
    -- Принимаем трейд
    local accepted = acceptTrade()
    
    if accepted then
        -- Ждём закрытия окна
        print("⏳ Ожидаю закрытия трейд-окна...")
        waitForTradeClose(10)
    end
    
    return accepted
end

-- ======== ГЛАВНАЯ ЛОГИКА ========
local function main()
    print("=" .. string.rep("=", 40))
    print("🤖 Adopt Me Trade Bot (Sender + Acceptor)")
    print("=" .. string.rep("=", 40))
    print("👤 Ваш ник: " .. player.Name)
    
    local usernames = readUsernames()
    
    if #usernames == 0 then
        warn("❌ Нет имён в файле. Создайте файл " .. USERNAMES_FILE)
        return
    end
    
    print("\n📋 Очередь трейдов:")
    for i, name in ipairs(usernames) do
        print("   " .. i .. ". " .. name)
    end
    
    print("\n⏱ Задержка между трейдами: " .. BETWEEN_TRADES_DELAY .. " сек")
    print("🚀 Начинаю отправку трейдов...\n")
    
    -- Проходим по всем именам
    for i, targetName in ipairs(usernames) do
        print("\n📊 Прогресс: " .. i .. "/" .. #usernames)
        
        local success = processOneTrade(targetName)
        
        if success then
            print("✅ Трейд с " .. targetName .. " завершён успешно!")
        else
            print("❌ Трейд с " .. targetName .. " не удался")
        end
        
        -- Задержка перед следующим трейдом
        if i < #usernames then
            print("⏳ Ожидание " .. BETWEEN_TRADES_DELAY .. " сек перед следующим...")
            wait(BETWEEN_TRADES_DELAY)
        end
    end
    
    print("\n🏁 Все трейды обработаны!")
    print("📊 Успешно: обработаны все " .. #usernames .. " игроков")
end

-- ======== ЗАПУСК ========
main()

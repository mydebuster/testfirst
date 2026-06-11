--[[
    Adopt Me - Auto Trade Acceptor
    Читает usernames из файла .rfld
    Принимает трейд 2+ раза (AcceptNegotiation + ConfirmTrade)
    Игрок не кладёт предметы
--]]

local API = game.ReplicatedStorage.API
local Players = game.Players
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ======== НАСТРОЙКИ ========
local USERNAMES_FILE = "usernames.rfld"  -- файл с именами
local TRADE_DELAY = 0.3                   -- задержка между этапами

-- ======== ЧТЕНИЕ ФАЙЛА ========
local function readUsernames()
    local success, content = pcall(function()
        return readfile(USERNAMES_FILE)
    end)
    
    if not success then
        warn("❌ Не удалось прочитать файл: " .. tostring(content))
        return {}
    end
    
    -- Парсим: каждое имя с новой строки, убираем пробелы
    local names = {}
    for name in content:gmatch("[^\r\n]+") do
        name = name:match("^%s*(.-)%s*$")  -- trim
        if name ~= "" then
            table.insert(names, name)
        end
    end
    
    print("📋 Загружено " .. #names .. " имён из файла")
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

-- ======== ПРОВЕРКА АКТИВНОСТИ ТРЕЙДА ========
local function isTradeActive()
    local tradeApp = playerGui:FindFirstChild("TradeApp")
    if tradeApp then
        -- Проверяем, видим ли интерфейс трейда
        local mainFrame = tradeApp:FindFirstChild("MainFrame") or tradeApp:FindFirstChild("Frame")
        if mainFrame and mainFrame.Visible then
            return true
        end
        -- Альтернативная проверка
        if tradeApp.Enabled then
            return true
        end
    end
    return false
end

-- ======== ПРИНЯТИЕ ТРЕЙДА ========
local function acceptTrade()
    print("🚀 Начинаю принятие трейда...")
    
    -- Этап 1: Принимаем запрос на трейд
    local acceptReq = API:FindFirstChild("TradeAPI/AcceptOrDeclineTradeRequest")
    if acceptReq then
        local ok, err = pcall(acceptReq.InvokeServer, acceptReq, true)
        if ok then
            print("   ✅ Запрос трейда принят")
        else
            warn("   ❌ Ошибка принятия запроса: " .. tostring(err))
            return false
        end
    end
    
    wait(TRADE_DELAY)
    
    -- Этап 2: Принимаем переговоры
    local acceptNeg = API:FindFirstChild("TradeAPI/AcceptNegotiation")
    if acceptNeg then
        local ok, err = pcall(acceptNeg.FireServer, acceptNeg)
        if ok then
            print("   ✅ Переговоры приняты")
        else
            warn("   ❌ Ошибка принятия переговоров: " .. tostring(err))
        end
    end
    
    wait(TRADE_DELAY)
    
    -- Этап 3: Финальное подтверждение
    local confirm = API:FindFirstChild("TradeAPI/ConfirmTrade")
    if confirm then
        local ok, err = pcall(confirm.FireServer, confirm)
        if ok then
            print("   ✅ Трейд подтверждён")
        else
            warn("   ❌ Ошибка подтверждения: " .. tostring(err))
        end
    end
    
    print("🏁 Трейд завершён!")
    return true
end

-- ======== ОТПРАВКА ЗАПРОСА НА ТРЕЙД (опционально) ========
local function sendTradeRequest(targetPlayer)
    local sendReq = API:FindFirstChild("TradeAPI/SendTradeRequest")
    if sendReq and targetPlayer then
        local ok, err = pcall(sendReq.FireServer, sendReq, targetPlayer)
        if ok then
            print("📤 Запрос на трейд отправлен: " .. targetPlayer.Name)
        else
            warn("❌ Ошибка отправки запроса: " .. tostring(err))
        end
    end
end

-- ======== МОНИТОРИНГ ТРЕЙДА ========
local function monitorTrade()
    print("👀 Ожидаю появления трейд-интерфейса...")
    
    -- Ждём появления TradeApp
    local tradeApp = playerGui:FindFirstChild("TradeApp")
    if not tradeApp then
        tradeApp = playerGui:WaitForChild("TradeApp", 30)
    end
    
    if not tradeApp then
        warn("❌ TradeApp не появился за 30 секунд")
        return
    end
    
    print("🟢 TradeApp обнаружен!")
    
    -- Ждём пока станет видимым (если ещё нет)
    local attempts = 0
    while not isTradeActive() and attempts < 50 do
        wait(0.2)
        attempts = attempts + 1
    end
    
    if isTradeActive() then
        print("🟢 Трейд активен! Принимаю...")
        wait(0.5)  -- небольшая задержка перед принятием
        acceptTrade()
    else
        warn("❌ Трейд не активировался")
    end
end

-- ======== ГЛАВНАЯ ЛОГИКА ========
local function main()
    print("=" .. string.rep("=", 40))
    print("🤖 Adopt Me Auto Trade Acceptor")
    print("=" .. string.rep("=", 40))
    
    local usernames = readUsernames()
    
    if #usernames == 0 then
        warn("❌ Нет имён в файле. Завершение.")
        return
    end
    
    -- Показываем загруженные имена
    print("👤 Целевые игроки:")
    for i, name in ipairs(usernames) do
        print("   " .. i .. ". " .. name)
    end
    
    -- Автоматический режим: мониторим и принимаем
    while true do
        monitorTrade()
        wait(2)  -- пауза перед следующей итерацией
    end
end

-- ======== ЗАПУСК ========
main()

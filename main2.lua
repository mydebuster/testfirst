-- PS99 RAID MASTER (Цикличный | Старт: L | Стоп: X)
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local masterSwitch = false -- Главный выключатель

-- НАСТРОЙКИ
local MOVE_SPEED = 70
local ACTION_DELAY = 3.5      
local INTERACT_WAIT = 1.2
local CLICK_X, CLICK_Y = 240, 530 -- Координаты твоей кнопки

-- Функция смещения координат
local function offset(vec, ox, oz)
    return Vector3.new(vec.X + (ox or 0), vec.Y, vec.Z + (oz or 0))
end

-----------------------------------------------------------
-- МАРШРУТ
-----------------------------------------------------------
local RaidSections = {
    { Name = "Комната 1", Points = { {Type = "Move", Pos = Vector3.new(-506.38, 109.14, -5721.69)}, {Type = "Move", Pos = offset(Vector3.new(-506.38, 109.14, -5721.69), 15, 15)}, {Type = "Move", Pos = Vector3.new(-447.38, 109.14, -5685.63)}, {Type = "Move", Pos = offset(Vector3.new(-447.38, 109.14, -5685.63), -15, 15)}, {Type = "Move", Pos = Vector3.new(-443.99, 109.14, -5727.37)}, {Type = "Move", Pos = offset(Vector3.new(-443.99, 109.14, -5727.37), 15, -15)}, {Type = "Move", Pos = Vector3.new(-445, 109.14, -5705)}, } },
    { Name = "Комната 2", Points = { {Type = "Move", Pos = Vector3.new(-346.37, 109.14, -5706.03)}, {Type = "Move", Pos = offset(Vector3.new(-346.37, 109.14, -5706.03), 10, -10)}, {Type = "Move", Pos = Vector3.new(-297.09, 109.14, -5722.50)}, {Type = "Move", Pos = offset(Vector3.new(-297.09, 109.14, -5722.50), -10, 10)}, {Type = "Move", Pos = Vector3.new(-301.86, 109.14, -5674.80)}, {Type = "Move", Pos = offset(Vector3.new(-301.86, 109.14, -5674.80), 20, 0)}, {Type = "Move", Pos = Vector3.new(-320, 109.14, -5700)}, } },
    { 
        Name = "Комната 3", 
        Points = { 
            {Type = "Move", Pos = Vector3.new(-193.19, 109.14, -5701.66)}, 
            {Type = "Move", Pos = Vector3.new(-147.92, 109.14, -5698.76)},
            {Type = "Move", Pos = offset(Vector3.new(-147.92, 109.14, -5698.76), 20, 30)}, 
            {Type = "Move", Pos = offset(Vector3.new(-147.92, 109.14, -5698.76), -25, -10)}, 
            {Type = "Interact", Pos = Vector3.new(-142.38, 109.14, -5771.87)}, 
            {Type = "Move", Pos = Vector3.new(-139.42, 109.02, -5950.68)},    
            {Type = "Move", Pos = offset(Vector3.new(-139.42, 109.02, -5950.68), 30, 30)},
            {Type = "Move", Pos = offset(Vector3.new(-139.42, 109.02, -5950.68), -30, -30)},
            {Type = "Move", Pos = offset(Vector3.new(-139.42, 109.02, -5950.68), 30, -30)},
            {Type = "Move", Pos = offset(Vector3.new(-139.42, 109.02, -5950.68), -30, 30)},
            {Type = "Move", Pos = offset(Vector3.new(-139.42, 109.02, -5950.68), 0, 45)},
            {Type = "Move", Pos = Vector3.new(-147.92, 109.14, -5698.76)},
            {Type = "Move", Pos = offset(Vector3.new(-147.92, 109.14, -5698.76), 20, 30)}, 
            {Type = "Move", Pos = offset(Vector3.new(-147.92, 109.14, -5698.76), -25, -10)}, 
        } 
    },
    { Name = "Комната 4", Points = { {Type = "Move", Pos = Vector3.new(-11.94, 109.14, -5701.22)}, {Type = "Move", Pos = offset(Vector3.new(-11.94, 109.14, -5701.22), 20, 20)}, {Type = "Move", Pos = offset(Vector3.new(-11.94, 109.14, -5701.22), -20, -20)}, {Type = "Move", Pos = Vector3.new(32.07, 109.14, -5696.34)}, {Type = "Move", Pos = offset(Vector3.new(32.07, 109.14, -5696.34), 15, 15)}, {Type = "Move", Pos = offset(Vector3.new(32.07, 109.14, -5696.34), -15, -15)}, {Type = "Move", Pos = Vector3.new(10, 109.14, -5700)}, } },
    { Name = "Комната 5", Points = { {Type = "Move", Pos = Vector3.new(126.31, 109.14, -5688.38)}, {Type = "Move", Pos = offset(Vector3.new(126.31, 109.14, -5688.38), 20, 0)}, {Type = "Move", Pos = offset(Vector3.new(126.31, 109.14, -5688.38), 0, 20)}, {Type = "Move", Pos = Vector3.new(196.80, 109.14, -5721.58)}, {Type = "Move", Pos = offset(Vector3.new(196.80, 109.14, -5721.58), -15, -15)}, {Type = "Move", Pos = offset(Vector3.new(196.80, 109.14, -5721.58), 15, 15)}, {Type = "Move", Pos = Vector3.new(160, 109.14, -5700)}, } },
    { Name = "Комната 6", Points = { {Type = "Move", Pos = Vector3.new(290.60, 109.14, -5742.09)}, {Type = "Move", Pos = offset(Vector3.new(290.60, 109.14, -5742.09), 30, 10)}, {Type = "Move", Pos = Vector3.new(332.33, 109.14, -5704.45)}, {Type = "Move", Pos = offset(Vector3.new(332.33, 109.14, -5704.45), -20, 20)}, {Type = "Move", Pos = Vector3.new(375.73, 109.14, -5662.99)}, {Type = "Move", Pos = offset(Vector3.new(375.73, 109.14, -5662.99), -20, -10)}, {Type = "Move", Pos = Vector3.new(330, 109.14, -5700)}, } },
    { Name = "Комната 7", Points = { {Type = "Move", Pos = Vector3.new(447.83, 109.14, -5699.78)}, {Type = "Move", Pos = Vector3.new(447.83, 109.14, -5699.78)}, {Type = "Move", Pos = Vector3.new(490.19, 109.14, -5660.09)}, {Type = "Move", Pos = Vector3.new(507.36, 109.20, -5713.30)}, {Type = "Move", Pos = Vector3.new(547.66, 109.14, -5703.40)}, {Type = "Move", Pos = Vector3.new(607.93, 109.14, -5678.70)}, {Type = "Move", Pos = Vector3.new(682.99, 109.14, -5729.26)}, {Type = "Move", Pos = offset(Vector3.new(682.99, 109.14, -5729.26), 25, 25)}, } },
    { 
        Name = "Комната 8", 
        Points = { 
            {Type = "Move", Pos = Vector3.new(761.29, 109.14, -5741.07)},
            {Type = "Move", Pos = Vector3.new(810.50, 109.14, -5708.46)}, 
            {Type = "Move", Pos = Vector3.new(861.37, 109.14, -5662.01)}, 
            {Type = "Move", Pos = offset(Vector3.new(810.50, 109.14, -5708.46), 30, 0)}, 
            {Type = "Interact", Pos = Vector3.new(815.10, 109.14, -5761.67)}, 
            {Type = "Move", Pos = Vector3.new(812.59, 109.02, -5905.14)},    
            {Type = "Move", Pos = offset(Vector3.new(812.59, 109.02, -5905.14), 25, 25)},
            {Type = "Move", Pos = offset(Vector3.new(812.59, 109.02, -5905.14), -25, -25)},
            {Type = "Move", Pos = offset(Vector3.new(812.59, 109.02, -5905.14), 25, -25)},
            {Type = "Move", Pos = offset(Vector3.new(812.59, 109.02, -5905.14), -25, 25)},
            {Type = "Move", Pos = offset(Vector3.new(812.59, 109.02, -5905.14), 0, -40)},
            {Type = "Move", Pos = offset(Vector3.new(812.59, 109.02, -5905.14), 40, 0)},
        } 
    },
    { Name = "Комната 9", Points = { {Type = "Move", Pos = Vector3.new(950.32, 110.50, -5700.28)}, {Type = "Move", Pos = offset(Vector3.new(950.32, 110.50, -5700.28), 15, 15)}, {Type = "Move", Pos = offset(Vector3.new(950.32, 110.50, -5700.28), -15, -15)}, {Type = "Move", Pos = Vector3.new(996.28, 110.53, -5702.81)}, {Type = "Move", Pos = offset(Vector3.new(996.28, 110.53, -5702.81), 15, 15)}, {Type = "Move", Pos = offset(Vector3.new(996.28, 110.53, -5702.81), -15, -15)}, {Type = "Move", Pos = Vector3.new(970, 110.53, -5700)}, } },
    { Name = "Комната НАГРАД", Points = { {Type = "Interact", Pos = Vector3.new(1094.57, 112.14, -5717.70)}, {Type = "Interact", Pos = Vector3.new(1101.89, 110.85, -5681.42)}, {Type = "Interact", Pos = Vector3.new(1164.13, 110.85, -5677.97)},  {Type = "Interact", Pos = Vector3.new(1135.07, 111.20, -5783.95)}, } },
    
    }
}

-----------------------------------------------------------
-- ЛОГИКА
-----------------------------------------------------------

local function physicalSingleClick()
    if not masterSwitch then return end
    VirtualInputManager:SendMouseButtonEvent(CLICK_X, CLICK_Y, 0, true, game, 0)
    task.wait(0.1)
    VirtualInputManager:SendMouseButtonEvent(CLICK_X, CLICK_Y, 0, false, game, 0)
end

local function moveTo(pos)
    if not masterSwitch then return end
    local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local dist = (root.Position - pos).Magnitude
    local info = TweenInfo.new(dist / MOVE_SPEED, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(root, info, {CFrame = CFrame.new(pos)})
    tween:Play()
    
    -- Ожидание конца твина с проверкой на выключение
    local start = tick()
    repeat task.wait(0.1) until tween.PlaybackState == Enum.PlaybackState.Completed or not masterSwitch
    if not masterSwitch then tween:Cancel() return end
    
    task.wait(ACTION_DELAY)
end

local function pressE()
    if not masterSwitch then return end
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    task.wait(INTERACT_WAIT)
    task.wait(ACTION_DELAY)
end

-- Авто-сборщик монет
task.spawn(function()
    local Net = game:GetService("ReplicatedStorage"):WaitForChild("Network")
    while true do
        if masterSwitch then
            local th = workspace:FindFirstChild("__THINGS")
            if th and th:FindFirstChild("Orbs") then
                local ids = {}
                for _, v in pairs(th.Orbs:GetChildren()) do table.insert(ids, tonumber(v.Name)) v:Destroy() end
                if #ids > 0 then Net.Orbs_Collect:FireServer(ids) end
            end
        end
        task.wait(0.5)
    end
end)

-- Основной процесс (БЕСКОНЕЧНЫЙ ЦИКЛ)
local function startMasterLoop()
    print(">>> ЗАПУСК ЦИКЛА РЕЙДА <<<")
    
    while masterSwitch do
        -- 1. Движение по комнатам
        moveTo(Vector3.new(-525.31, 109.14, -5702.72)) -- Стартовая точка

        for _, section in ipairs(RaidSections) do
            if not masterSwitch then break end
            print("Зона: " .. section.Name)
            for _, step in ipairs(section.Points) do
                if not masterSwitch then break end
                moveTo(step.Pos)
                if step.Type == "Interact" then pressE() end
            end
        end

        if not masterSwitch then break end

        -- 2. Клики Авторейда
        print(">>> МАРШРУТ ПРОЙДЕН. ВКЛЮЧАЮ AUTO RAID... <<<")
        task.wait(1)
        physicalSingleClick() -- Клик 1

        print(">>> ЖДУ 12 СЕКУНД... <<<")
        local waitStart = tick()
        repeat task.wait(0.5) until tick() - waitStart >= 15 or not masterSwitch

        if not masterSwitch then break end

        print(">>> ВЫКЛЮЧАЮ AUTO RAID... <<<")
        physicalSingleClick() -- Клик 2
        
        print(">>> ЦИКЛ ЗАВЕРШЕН. НАЧИНАЮ ЗАНОВО... <<<")
        task.wait(2)
    end
    
    print(">>> СКРИПТ ПОЛНОСТЬЮ ОСТАНОВЛЕН <<<")
end

-- СЛУШАТЕЛЬ КНОПОК
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    -- L - Запуск
    if input.KeyCode == Enum.KeyCode.L then
        if not masterSwitch then
            masterSwitch = true
            task.spawn(startMasterLoop)
        else
            warn("Скрипт уже запущен!")
        end
    end
    
    -- X - Остановка
    if input.KeyCode == Enum.KeyCode.X then
        if masterSwitch then
            masterSwitch = false
            print("ОСТАНОВКА СКРИПТА...")
        end
    end
end)

print("------------------------------------------")
print("Гарнитура готова!")
print("Нажми 'L' для запуска (бесконечный цикл).")
print("Нажми 'X' для полной остановки.")
print("------------------------------------------")

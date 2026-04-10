-- PS99 RAID MASTER (Ultra Collector | 1024x768 | DPI 100 | Активация: L)
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local isRunning = false

-- НАСТРОЙКИ
local MOVE_SPEED = 70
local ACTION_DELAY = 4.0      -- Пауза между точками
local INTERACT_WAIT = 1.2
local CLICK_X, CLICK_Y = 240, 530 -- Твои новые координаты кнопки AutoRaid

-- Функция смещения координат
local function offset(vec, ox, oz)
    return Vector3.new(vec.X + (ox or 0), vec.Y, vec.Z + (oz or 0))
end

-- МАРШРУТ
local RaidSections = {
    { Name = "Комната 1", Points = { {Type = "Move", Pos = Vector3.new(-506.38, 109.14, -5721.69)}, {Type = "Move", Pos = offset(Vector3.new(-506.38, 109.14, -5721.69), 15, 15)}, {Type = "Move", Pos = Vector3.new(-447.38, 109.14, -5685.63)}, {Type = "Move", Pos = offset(Vector3.new(-447.38, 109.14, -5685.63), -15, 15)}, {Type = "Move", Pos = Vector3.new(-443.99, 109.14, -5727.37)} } },
    { Name = "Комната 2", Points = { {Type = "Move", Pos = Vector3.new(-346.37, 109.14, -5706.03)}, {Type = "Move", Pos = offset(Vector3.new(-346.37, 109.14, -5706.03), 10, -10)}, {Type = "Move", Pos = Vector3.new(-297.09, 109.14, -5722.50)}, {Type = "Move", Pos = offset(Vector3.new(-297.09, 109.14, -5722.50), -10, 10)}, {Type = "Move", Pos = Vector3.new(-301.86, 109.14, -5674.80)} } },
    { 
        Name = "Комната 3 (Макс Сбор)", 
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
            
        } 
    },
    { Name = "Комната 4", Points = { {Type = "Move", Pos = Vector3.new(-11.94, 109.14, -5701.22)}, {Type = "Move", Pos = offset(Vector3.new(-11.94, 109.14, -5701.22), 20, 20)}, {Type = "Move", Pos = offset(Vector3.new(-11.94, 109.14, -5701.22), -20, -20)}, {Type = "Move", Pos = Vector3.new(32.07, 109.14, -5696.34)}, {Type = "Move", Pos = offset(Vector3.new(32.07, 109.14, -5696.34), 15, 15)}, {Type = "Move", Pos = offset(Vector3.new(32.07, 109.14, -5696.34), -15, -15)}, } },
    { Name = "Комната 5", Points = { {Type = "Move", Pos = Vector3.new(126.31, 109.14, -5688.38)}, {Type = "Move", Pos = offset(Vector3.new(126.31, 109.14, -5688.38), 20, 0)}, {Type = "Move", Pos = offset(Vector3.new(126.31, 109.14, -5688.38), 0, 20)}, {Type = "Move", Pos = Vector3.new(196.80, 109.14, -5721.58)}, {Type = "Move", Pos = offset(Vector3.new(196.80, 109.14, -5721.58), -15, -15)}, {Type = "Move", Pos = Vector3.new(160, 109.14, -5700)}, } },
    { Name = "Комната 6", Points = { {Type = "Move", Pos = Vector3.new(290.60, 109.14, -5742.09)}, {Type = "Move", Pos = offset(Vector3.new(290.60, 109.14, -5742.09), 30, 10)}, {Type = "Move", Pos = Vector3.new(332.33, 109.14, -5704.45)}, {Type = "Move", Pos = offset(Vector3.new(332.33, 109.14, -5704.45), -20, 20)}, {Type = "Move", Pos = Vector3.new(375.73, 109.14, -5662.99)}, {Type = "Move", Pos = offset(Vector3.new(375.73, 109.14, -5662.99), -20, -10)}, {Type = "Move", Pos = Vector3.new(330, 109.14, -5700)}, } },
    { Name = "Комната 7", Points = { {Type = "Move", Pos = Vector3.new(447.83, 109.14, -5699.78)}, {Type = "Move", Pos = Vector3.new(490.19, 109.14, -5660.09)}, {Type = "Move", Pos = Vector3.new(507.36, 109.20, -5713.30)}, {Type = "Move", Pos = Vector3.new(547.66, 109.14, -5703.40)}, {Type = "Move", Pos = Vector3.new(607.93, 109.14, -5678.70)}, {Type = "Move", Pos = Vector3.new(682.99, 109.14, -5729.26)}, {Type = "Move", Pos = offset(Vector3.new(682.99, 109.14, -5729.26), 25, 25)}, } },
    { 
        Name = "Комната 8 (Макс Сбор)", 
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
    { Name = "Комната НАГРАД", Points = { {Type = "Interact", Pos = Vector3.new(1094.57, 112.14, -5717.70)}, {Type = "Interact", Pos = Vector3.new(1101.89, 110.85, -5681.42)}, {Type = "Interact", Pos = Vector3.new(1164.13, 110.85, -5677.97)}, {Type = "Interact", Pos = Vector3.new(1165.39, 110.85, -5721.62)}, {Type = "Interact", Pos = Vector3.new(1135.07, 111.20, -5783.95)}, } },
    { 
        Name = "Босс и Финал зачистка", 
        Points = { 
            {Type = "Move", Pos = Vector3.new(1131.03, 109.94, -5636.84)}, 
            {Type = "Move", Pos = Vector3.new(1130.40, 109.45, -5422.93)}, 
            {Type = "Move", Pos = offset(Vector3.new(1130.40, 109.45, -5422.93), 25, 25)}, 
            {Type = "Move", Pos = offset(Vector3.new(1130.40, 109.45, -5422.93), -25, -25)}, 
            {Type = "Move", Pos = offset(Vector3.new(1130.40, 109.45, -5422.93), 25, -25)}, 
            {Type = "Move", Pos = offset(Vector3.new(1130.40, 109.45, -5422.93), -25, 25)}, 
            {Type = "Move", Pos = offset(Vector3.new(1130.40, 109.45, -5422.93), 0, 40)}, 
        } 
    }
}

-- ЛОГИКА КЛИКА
local function physicalClickButton()
    print("ВЫПОЛНЯЮ КЛИК ПО КНОПКЕ (", CLICK_X, ",", CLICK_Y, ")...")
    for i = 1, 3 do
        VirtualInputManager:SendMouseButtonEvent(CLICK_X, CLICK_Y, 0, true, game, 0)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(CLICK_X, CLICK_Y, 0, false, game, 0)
        task.wait(0.2)
    end
end

local function moveTo(pos)
    local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local dist = (root.Position - pos).Magnitude
    local info = TweenInfo.new(dist / MOVE_SPEED, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(root, info, {CFrame = CFrame.new(pos)})
    tween:Play()
    tween.Completed:Wait()
    task.wait(ACTION_DELAY)
end

local function pressE()
    print("Нажимаю E...")
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    task.wait(INTERACT_WAIT)
    task.wait(ACTION_DELAY)
end

-- Сборщик монет (фон)
task.spawn(function()
    local Net = game:GetService("ReplicatedStorage"):WaitForChild("Network")
    while true do
        local th = workspace:FindFirstChild("__THINGS")
        if th and th:FindFirstChild("Orbs") then
            local ids = {}
            for _, v in pairs(th.Orbs:GetChildren()) do table.insert(ids, tonumber(v.Name)) v:Destroy() end
            if #ids > 0 then Net.Orbs_Collect:FireServer(ids) end
        end
        task.wait(0.5)
    end
end)

-- Основной цикл рейда
local function startRaid()
    if isRunning then return end
    isRunning = true

    print(">>> СТАРТ ПОЛНОГО РЕЙДА <<<")
    moveTo(Vector3.new(-525.31, 109.14, -5702.72)) 

    for _, section in ipairs(RaidSections) do
        print("Зона: " .. section.Name)
        for _, step in ipairs(section.Points) do
            moveTo(step.Pos)
            if step.Type == "Interact" then pressE() end
        end
    end

    print(">>> МАРШРУТ ЗАВЕРШЕН. ПЕРВОЕ НАЖАТИЕ... <<<")
    task.wait(2)
    physicalClickButton() -- Первое нажатие

    print(">>> ОЖИДАНИЕ 12 СЕКУНД ПЕРЕД ВТОРЫМ НАЖАТИЕМ... <<<")
    task.wait(12)
    physicalClickButton() -- Второе нажатие
    print(">>> ОЖИДАНИЕ 12 СЕКУНД ПЕРЕД ВТОРЫМ НАЖАТИЕМ... <<<")
    task.wait(12)
    physicalClickButton() -- Второе нажатие

    print(">>> ВСЕ ДЕЙСТВИЯ ЗАВЕРШЕНЫ <<<")
    isRunning = false
end

-- Активация на кнопку L
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.K then
        startRaid()
    end
end)

print("------------------------------------------")
print("Скрипт ГОТОВ. Нажми 'L'.")
print("Клик 1 в 240, 530.")
print("Клик 2 через 12 секунд.")
print("------------------------------------------")

-- PS99 RAID MASTER (Активация: L | Задержка 2 сек)
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local isRunning = false 

-----------------------------------------------------------
-- НАСТРОЙКИ
-----------------------------------------------------------
local MOVE_SPEED = 65      -- Скорость полета
local ACTION_DELAY = 2.0    -- Задержка между действиями (2 секунды)
local INTERACT_WAIT = 1.2   -- Время на саму анимацию нажатия E

-----------------------------------------------------------
-- МАРШРУТ
-----------------------------------------------------------
local RaidPath = {
    {Type = "Move", Pos = Vector3.new(-525.31, 109.14, -5702.72)}, -- Начало
    {Type = "Move", Pos = Vector3.new(-506.38, 109.14, -5721.69)},
    {Type = "Move", Pos = Vector3.new(-447.38, 109.14, -5685.63)},
    {Type = "Move", Pos = Vector3.new(-443.99, 109.14, -5727.37)},
    {Type = "Move", Pos = Vector3.new(-346.37, 109.14, -5706.03)},
    {Type = "Move", Pos = Vector3.new(-297.09, 109.14, -5722.50)},
    {Type = "Move", Pos = Vector3.new(-301.86, 109.14, -5674.80)},
    {Type = "Move", Pos = Vector3.new(-193.19, 109.14, -5701.66)},
    {Type = "Move", Pos = Vector3.new(-147.92, 109.14, -5698.76)},
    {Type = "Move", Pos = Vector3.new(-94.89, 109.14, -5710.89)},
    {Type = "Interact", Pos = Vector3.new(-142.38, 109.14, -5771.87)}, -- Кнопка 1
    {Type = "Move", Pos = Vector3.new(-139.42, 109.02, -5950.68)}, -- Сундук 1
    {Type = "Move", Pos = Vector3.new(-11.94, 109.14, -5701.22)},
    {Type = "Move", Pos = Vector3.new(32.07, 109.14, -5696.34)},
    {Type = "Move", Pos = Vector3.new(126.31, 109.14, -5688.38)},
    {Type = "Move", Pos = Vector3.new(196.80, 109.14, -5721.58)},
    {Type = "Move", Pos = Vector3.new(290.60, 109.14, -5742.09)},
    {Type = "Move", Pos = Vector3.new(332.33, 109.14, -5704.45)},
    {Type = "Move", Pos = Vector3.new(375.73, 109.14, -5662.99)},
    {Type = "Move", Pos = Vector3.new(447.83, 109.14, -5699.78)},
    {Type = "Move", Pos = Vector3.new(490.19, 109.14, -5660.09)},
    {Type = "Move", Pos = Vector3.new(507.36, 109.20, -5713.30)},
    {Type = "Move", Pos = Vector3.new(547.66, 109.14, -5703.40)},
    {Type = "Move", Pos = Vector3.new(607.93, 109.14, -5678.70)},
    {Type = "Move", Pos = Vector3.new(682.99, 109.14, -5729.26)},
    {Type = "Move", Pos = Vector3.new(761.29, 109.14, -5741.07)},
    {Type = "Move", Pos = Vector3.new(810.50, 109.14, -5708.46)},
    {Type = "Move", Pos = Vector3.new(861.37, 109.14, -5662.01)},
    {Type = "Interact", Pos = Vector3.new(815.10, 109.14, -5761.67)}, -- Кнопка 2
    {Type = "Move", Pos = Vector3.new(812.59, 109.02, -5905.14)}, -- Сундук 2
    {Type = "Move", Pos = Vector3.new(950.32, 110.50, -5700.28)},
    {Type = "Move", Pos = Vector3.new(996.28, 110.53, -5702.81)},
    -- Награды
    {Type = "Interact", Pos = Vector3.new(1094.57, 112.14, -5717.70)},
    {Type = "Interact", Pos = Vector3.new(1101.89, 110.85, -5681.42)},
    {Type = "Interact", Pos = Vector3.new(1164.13, 110.85, -5677.97)},
    {Type = "Interact", Pos = Vector3.new(1165.39, 110.85, -5721.62)},
    {Type = "Interact", Pos = Vector3.new(1135.07, 111.20, -5783.95)},
    -- Финал
    {Type = "Move", Pos = Vector3.new(1131.03, 109.94, -5636.84)},
    {Type = "Move", Pos = Vector3.new(1130.40, 109.45, -5822.93)},
    {Type = "Move", Pos = Vector3.new(1208.86, 109.94, -5701.94)},
}

-----------------------------------------------------------
-- ФУНКЦИИ ЛОГИКИ
-----------------------------------------------------------

local function moveTo(pos)
    local char = Player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local dist = (root.Position - pos).Magnitude
    local info = TweenInfo.new(dist / MOVE_SPEED, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(root, info, {CFrame = CFrame.new(pos)})
    
    tween:Play()
    tween.Completed:Wait() -- Ждем окончания полета
    print("Прибыл в точку. Жду " .. ACTION_DELAY .. " сек.")
    task.wait(ACTION_DELAY) -- Задержка 2 сек после прилета
end

local function pressE()
    print("Нажимаю E...")
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    task.wait(INTERACT_WAIT) -- Время на срабатывание кнопки
    print("Взаимодействие завершено. Жду " .. ACTION_DELAY .. " сек.")
    task.wait(ACTION_DELAY) -- Задержка 2 сек после взаимодействия
end

-- Авто-коллектор (Магнит для сфер)
task.spawn(function()
    local Network = game:GetService("ReplicatedStorage"):WaitForChild("Network")
    while true do
        local things = workspace:FindFirstChild("__THINGS")
        if things then
            local orbs = things:FindFirstChild("Orbs")
            if orbs and #orbs:GetChildren() > 0 then
                local ids = {}
                for _, v in pairs(orbs:GetChildren()) do 
                    table.insert(ids, tonumber(v.Name)) 
                    v:Destroy() 
                end
                Network:WaitForChild("Orbs_Collect"):FireServer(ids)
            end
        end
        task.wait(0.5)
    end
end)

-- Основной цикл рейда
local function runRaid()
    if isRunning then return end
    isRunning = true
    
    print(">>> СТАРТ МАРШРУТА...")
    
    for i, step in ipairs(RaidPath) do
        print("Шаг №" .. i .. " из " .. #RaidPath)
        moveTo(step.Pos)
        
        if step.Type == "Interact" then
            pressE()
        end
    end
    
    print(">>> МАРШРУТ ПОЛНОСТЬЮ ПРОЙДЕН!")
    isRunning = false
end

-- Кнопка активации
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.L then
        if not isRunning then
            runRaid()
        else
            warn("Скрипт уже выполняет маршрут!")
        end
    end
end)

print("Скрипт готов! Нажми 'L', когда зайдешь в рейд.")

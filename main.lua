-- Регистрация мода
local mod = RegisterMod("StarRainMod", 1)

-- Получаем ID предмета Star Rain
local starRainId = Isaac.GetItemIdByName("Star Rain")
-- Частота появления особых слез
local specialTearChance = 0.1

-- Проверка наличия предмета и установка флагов слез
function mod:OnTearInit(tear)
    local player = tear.SpawnerEntity and tear.SpawnerEntity:ToPlayer() -- Получаем игрока

    -- Проверяем, есть ли у игрока предмет Star Rain
    if player and player:HasCollectible(starRainId) then
        player.TearFlags = player.TearFlags | TearFlags.TEAR_PIERCING
        tear:GetSprite():Load("gfx/star.anm2", true) -- Загрузка графики для звезды
        tear:GetSprite():ReplaceSpritesheet(1, "gfx/star.png")
        tear:GetSprite():LoadGraphics()
        tear:GetSprite():Play("Idle", true)

        -- Устанавливаем кастомный флаг, чтобы знать, что слеза принадлежит Star Rain
        tear:GetData().IsStarTear = true

        -- Добавление случайной вероятности для особой слезы
        if math.random() < specialTearChance then
            tear:GetSprite():Load("gfx/special_star.anm2", true) -- Загрузка файла с анимацией
            tear:GetSprite():ReplaceSpritesheet(1, "gfx/special_star.png")
            tear:GetSprite():LoadGraphics()
            tear:GetSprite():Play("Idle", true)

            -- Устанавливаем флаг для особой слезы
            tear:GetData().IsSpecialTear = true
            print("Special Star fired!") -- Для отладки
        end
    end
end

-- Обработка разрушения слезы
function mod:OnTearUpdate(tear)
    -- Проверяем, принадлежит ли слеза Star Rain и завершает ли она полёт
    if tear:GetData().IsStarTear and tear:IsDead() then
        tear:Remove()
        -- Создаем эффект всплеска на месте разрушения слезы
        local explosion = Isaac.Spawn(
            EntityType.ENTITY_EFFECT, -- Тип объекта
            EffectVariant.POOF01, -- Используем стандартный эффект, чтобы заменить его спрайтом
            0, -- Субтип
            tear.Position + -5 * tear.Velocity:Normalized(), -- Позиция всплеска
            Vector.Zero, -- Скорость
            nil -- Нет владельца
        )

        -- Заменяем анимацию всплеска
        local explosionSprite = explosion:GetSprite()
        explosionSprite:Load("gfx/star_explosion.anm2", true) -- Загрузка анимации всплеска
        explosionSprite:ReplaceSpritesheet(0, "gfx/star_explosion.png") -- Заменяем графику 
        explosionSprite:LoadGraphics()
        explosionSprite:Play("Idle", true)

        -- Настраиваем длительность эффекта всплеска
        --explosion:ToEffect():SetTimeout(30)

        print("Star tear exploded with custom animation!") -- Для отладки
    end
end
function mod:StarRains(ent, amount, flags, src, frames)
    if ent:IsEnemy() and src and src.Type == EntityType.ENTITY_TEAR and src.Entity:GetData().IsSpecialTear then
        local room = Game():GetRoom()
        local centerX = room:GetCenterPos().X
        local roomWidth = room:GetGridWidth() * 40 -- Rough estimate
         -- Just above the screen 
         local dir = (math.random(2) == 1 and -1 or 1) * 8
        for i = 1, 15, 1 do
            local xPos = centerX + math.random(-roomWidth / 2, roomWidth / 2)
            local yPos = room:GetTopLeftPos().Y - math.random(0, 50) 
    
            -- Spawn a projectile (tear-like entity)
            local tear = Isaac.Spawn(EntityType.ENTITY_TEAR, 0, 0, Vector(xPos, yPos), Vector(dir, 8), nil)
            tear:ToTear().TearFlags = Isaac.GetPlayer(0).TearFlags
            tear:GetData().IsStarTear = true
            tear:GetSprite():Load("gfx/star.anm2", true) -- Загрузка графики для звезды
            tear:GetSprite():ReplaceSpritesheet(1, "gfx/star.png")
            tear:GetSprite():LoadGraphics()
            tear:GetSprite():Play("Idle", true)
            tear:ToTear().Height = -100
        end
        -- Random X position within room bounds

    end    
end
-- Регистрируем колбэки
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, mod.OnTearInit)
mod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, mod.OnTearUpdate)
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.StarRains)

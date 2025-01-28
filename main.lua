-- Регистрация мода
local mod = RegisterMod("StarRainMod", 1)
local sfx = SFXManager()
local SOUND_RAIN = Isaac.GetSoundIdByName("Rain")
local SOUND_RAINFALL = Isaac.GetSoundIdByName("Falling Rain")
local BREAK = Isaac.GetSoundIdByName("Break")
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
        sfx:Play(SOUND_RAIN, 1,1,false, math.random(9, 12)/10)
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
        sfx:Play(BREAK) 
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
         sfx:Play(SOUND_RAINFALL) 
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

local mod = RegisterMod("StarRainMod", 1)
local sfx = SFXManager()
local injectionId = Isaac.GetItemIdByName("Isaac Injection")
local isaac = false
local haveItem = false
function mod:OnFamiliarUpdate(familiar)
    familiar.Velocity = Vector.Zero -- Prevent movement
    familiar.SpriteScale = Vector(2, 2)
end




function mod:PostFireTear(tear)
    local player = Isaac.GetPlayer(0)
    local luck = player.Luck -- Get player's Luck stat
    local baseChance = 0.05-- Base probability (e.g., 10%)
    haveItem = player:HasCollectible(injectionId)
local chance = baseChance + (luck * 0.02) 
    if haveItem and math.random() < chance and haveItem then
        tear:GetSprite():Load("gfx/tear.anm2", true)
        tear:GetSprite():ReplaceSpritesheet(0, "gfx/tear.png")
        tear:GetSprite():LoadGraphics()
        tear:GetSprite():Play("Idle", true)
        isaac = true
    end
end
function mod:OnNPCHit(entity, amount, damageFlags, source, countdown)
    if entity:IsEnemy() and not entity:IsBoss() then
        -- Example: If hit by a tear, do something special
        if source and source.Type == EntityType.ENTITY_TEAR then

            -- Now safely check if the tear has the TEAR_ACID flag
            if isaac then
                print("Hit by a tear with TEAR_ACID flag!")
                Isaac.Spawn(EntityType.ENTITY_FAMILIAR, FamiliarVariant.MINISAAC, 0, entity.Position, Vector.Zero, entity):ToFamiliar()
                isaac= false
                entity:Kill()
end
        end
        end
    end
    -- Replace FamiliarVariant.YOUR_FAMILIAR with the familiar you want to change

    function mod:OnNewRoom()
        for _, familiar in pairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR)) do
            if familiar.Variant == FamiliarVariant.MINISAAC then
                familiar:Remove() -- Deletes the familiar
            end
        end
    end

    mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.OnNewRoom)
    function mod:MakeEnemiesAttackFamiliar(npc)
        -- Get the familiar we want enemies to target
        local familiars = Isaac.FindByType(EntityType.ENTITY_FAMILIAR, FamiliarVariant.MINISAAC, -1, false, false)

        -- Ensure at least one familiar exists
        if #familiars > 0 then
            local targetFamiliar = familiars[1] -- Select the first found familiar

            -- Set the enemy's target to the familiar
            npc.Target = targetFamiliar
        end
    end
    -- local itemID = CollectibleType.Coll  -- Change this to the desired item

    function mod:OnPickupSpawn(pickup)
        -- Ensure the pickup is a collectible item
        if pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE then
            -- Check if the spawned item is the one we want
            if pickup.SubType == Isaac.GetItemIdByName("Isaac Injection") then
                haveItem = true -- Replace with your desired action
                -- Example: Move the item slightly
            end
        end
    end

    mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.OnPickupSpawn, PickupVariant.PICKUP_COLLECTIBLE)
    mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, mod.OnFamiliarUpdate, FamiliarVariant.MINISAAC)
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.MakeEnemiesAttackFamiliar)
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.OnNPCHit)
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, mod.PostFireTear)
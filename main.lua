-- Load background music
gameMusic = love.audio.newSource("audio/game_music.ogg", "stream")
gameMusic:setLooping(true)
gameMusic:setVolume(0.7)  -- volume from 0.0 to 1.0
gameMusic:play()

function love.load()
    anim8 = require 'libraries/anim8'

    --Background
    background = love.graphics.newImage('sprites/cal.jpg')

    --Camera and world
    camera = { x = 0, y = 0, shake = 0 }
    tileSize = 48
    groundY = 500

    --Custom Fonts
    fonts = {
        title = love.graphics.newFont("fonts/MonsterTitle.ttf", 72),
        subtitle = love.graphics.newFont("fonts/MonsterTitle.ttf", 28),
        character_select = love.graphics.newFont("fonts/MonsterTitle.ttf", 36)
    }

    --Load ground tiles
    groundTiles = {
        topLeft  = love.graphics.newImage("sprites/tile28.png"),
        topMid   = love.graphics.newImage("sprites/tile29.png"),
        bottom   = love.graphics.newImage("sprites/tile11.png")
    }

    tileSize = 48
    groundRows = 3     
    groundCols = math.ceil(love.graphics.getWidth() / tileSize) + 2


    

    -- Load explosion sound effect
    explosionSound = love.audio.newSource("audio/explosion.ogg", "static")
    explosionSound:setVolume(0.9) -- optional: adjust loudness (0.0–1.0)

    -- Load hurt (damage) sound
    hurtSound = love.audio.newSource("audio/damage.ogg", "static")
    hurtSound:setVolume(0.8)

    -- Load UI selection sound
    selectSound = love.audio.newSource("audio/laser.ogg", "static")
    selectSound:setVolume(0.8)

    coinSound = love.audio.newSource("audio/coin_sound.mp3", "static")
    coinSound:setVolume(0.9) 

    --Character selection setup
    characters = {
        {
            name = "Pink Monster",
            run = 'sprites/Pink_Monster_Run_6.png',
            jump = 'sprites/Pink_Monster_Jump_8.png',
            idle = 'sprites/Pink_Monster_Idle_4.png',
            deathSheet = "sprites/Pink_Monster_Death_8.png",
            hurt = 'sprites/Pink_Monster_Hurt_4.png',
            throw = 'sprites/Pink_Monster_Throw_4.png', 
            image = love.graphics.newImage("sprites/Pink_Monster.png")
        },
        {
            name = "Owlet Monster",
            run = 'sprites/Owlet_Monster_Run_6.png',
            jump = 'sprites/Owlet_Monster_Jump_8.png',
            idle = 'sprites/Owlet_Monster_Idle_4.png',
            deathSheet = "sprites/Owlet_Monster_Death_8.png",
            hurt = 'sprites/Owlet_Monster_Hurt_4.png',
            throw = 'sprites/Owlet_Monster_Throw_4.png',
            image = love.graphics.newImage("sprites/Owlet_Monster.png")
        },
        {
            name = "Dude Monster",
            run = 'sprites/Dude_Monster_Run_6.png',
            jump = 'sprites/Dude_Monster_Jump_8.png',
            idle = 'sprites/Dude_Monster_Idle_4.png',
            deathSheet = "sprites/Dude_Monster_Death_8.png",
            hurt = 'sprites/Dude_Monster_Hurt_4.png',
            throw = 'sprites/Dude_Monster_Throw_4.png',  
            image = love.graphics.newImage("sprites/Dude_Monster.png")
        }
    }

    --Load idle animations for all characters for the animated preview
    for _, char in ipairs(characters) do
        local idleSheet = love.graphics.newImage(char.idle)
        local idleGrid = anim8.newGrid(32, 32, idleSheet:getWidth(), idleSheet:getHeight())
        char.idleAnim = anim8.newAnimation(idleGrid('1-4', 1), 0.25)
        char.idleSheet = idleSheet
    end

    selectedCharacter = 1

    --Player setup
    player = {
        x = 500,
        y = groundY - 96,
        width = 32,
        height = 32,
        speed = 350,
        yVelocity = 0,
        jumpForce = -700,
        gravity = 1500,
        onGround = true,
        flip = false,
        isDead = false,
        deathTimer = 0,
        fadeAlpha = 0,
        isHurt = false,
        hurtTimer = 0,
        isThrowing = false,
        fireMode = false,
        fireTimer = 0
    }

    --Load default (Pink Monster)
    loadSelectedCharacter()

    --Gorgon setup
    enemy = {
        x = 0,
        y = groundY - 128 * 1.5,
        width = 128,
        height = 128,
        speed = 349,
        flip = false,
        alive = true
    }

    enemy.sheet = love.graphics.newImage('sprites/enemy_run.png')
    enemy.grid = anim8.newGrid(128, 128, enemy.sheet:getWidth(), enemy.sheet:getHeight())
    enemy.anim = anim8.newAnimation(enemy.grid('1-7', 1), 0.1)

    --Game variables
    font = love.graphics.newFont(24)
    distance = 0
    camera.x = 0
    score = 0

    --Bomb setup
    bomb = {
        image = love.graphics.newImage("sprites/bomb.png"),
        x = -100,
        y = groundY - 32 * 3,
        width = 32,
        height = 32,
        active = false
    }
    bombSpawnTimer = 0
    bombSpawnInterval = math.max(1.5, 5 - distance / 200)

    --Explosion setup
    explosion = {
        image = love.graphics.newImage("sprites/explosion.png"),
        active = false,
        x = 0,
        y = 0,
        scale = 2
    }
    local explosionGrid = anim8.newGrid(64, 64, explosion.image:getWidth(), explosion.image:getHeight())
    explosion.anim = anim8.newAnimation(explosionGrid('1-4', 1, '1-4', 2, '1-4', 3, '1-4', 4), 0.08, 'pauseAtEnd')

    --Shield setup
    shield = {
        image = love.graphics.newImage("sprites/shield.png"),
        x = -100,
        y = groundY - 32 * 3,
        width = 32,
        height = 32,
        active = false,   
        collected = false 
    }
    shieldSpawnTimer = 0
    shieldSpawnInterval = 10 
    
    --Fireball Power-up setup
    fireball = {
        sheet = love.graphics.newImage("sprites/fireball_sheet.png"), -- 8 frames x 48x48
        x = -100,
        y = groundY - 48 * 3,
        width = 48,
        height = 48,
        active = false,
        collected = false
    }
    local fireballGrid = anim8.newGrid(48, 48, fireball.sheet:getWidth(), fireball.sheet:getHeight())
    fireball.anim = anim8.newAnimation(fireballGrid('1-8', 1), 0.08)
    fireballSpawnTimer = 0
    fireballSpawnInterval = 6  -- seconds

    --Firespell projectile setup (animated shots)
    firespell = {
        sheet = love.graphics.newImage("sprites/firespell_sheet.png"), 
        projectiles = {},
        speed = 600
    }
    local firespellGrid = anim8.newGrid(32, 32, firespell.sheet:getWidth(), firespell.sheet:getHeight())
    firespell.anim = anim8.newAnimation(firespellGrid('1-8', 1), 0.08)

    -- Coin setup (animated coin)
    coin = {
        sheet = love.graphics.newImage("sprites/coin_sheet.png"),
        coins = {},
        spawnTimer = 0,
        spawnInterval = 2  -- seconds between spawns
    }

    local coinGrid = anim8.newGrid(32, 32, coin.sheet:getWidth(), coin.sheet:getHeight())
    coin.anim = anim8.newAnimation(coinGrid('1-8', 1), 0.1)
    
    --Pause Menu Buttons
    pauseButtons = {
        newGame = love.graphics.newImage("sprites/New Game  col_Button.png"),
        resume  = love.graphics.newImage("sprites/Resume  col_Button.png"),
        quit    = love.graphics.newImage("sprites/Quit  col_Button.png")
    }
    pauseMenu = {
        active = false,
        selected = 1,
        options = {"Resume", "New Game", "Quit"}
    }
    
    -- Game state management
    gameState = "menu" 
    blinkTimer = 0
    blinkVisible = true
end


function loadSelectedCharacter()
    local char = characters[selectedCharacter]

    player.runSheet  = love.graphics.newImage(char.run)
    player.jumpSheet = love.graphics.newImage(char.jump)
    player.idleSheet = love.graphics.newImage(char.idle)
    player.deathSheet = love.graphics.newImage(char.deathSheet)
    player.throwSheet = love.graphics.newImage(char.throw)
    player.hurtSheet = love.graphics.newImage(char.hurt)

    player.runGrid  = anim8.newGrid(32, 32, player.runSheet:getWidth(),  player.runSheet:getHeight())
    player.jumpGrid = anim8.newGrid(32, 32, player.jumpSheet:getWidth(), player.jumpSheet:getHeight())
    player.idleGrid = anim8.newGrid(32, 32, player.idleSheet:getWidth(), player.idleSheet:getHeight())
    player.deathGrid = anim8.newGrid(32, 32, player.deathSheet:getWidth(), player.deathSheet:getHeight())
    player.throwGrid  = anim8.newGrid(32, 32, player.throwSheet:getWidth(), player.throwSheet:getHeight())
    player.hurtGrid = anim8.newGrid(32, 32, player.hurtSheet:getWidth(), player.hurtSheet:getHeight())

    player.runAnim  = anim8.newAnimation(player.runGrid('1-6', 1), 0.1)
    player.jumpAnim = anim8.newAnimation(player.jumpGrid('1-8', 1), 0.08)
    player.idleAnim = anim8.newAnimation(player.idleGrid('1-4', 1), 0.25)
    player.deathAnim = anim8.newAnimation(player.deathGrid('1-8', 1), 0.08)
    player.throwAnim = anim8.newAnimation(player.throwGrid('1-4', 1), 0.08, 'pauseAtEnd')
    player.hurtAnim = anim8.newAnimation(player.hurtGrid('1-4', 1), 0.1)

    player.currentAnim = player.idleAnim
end


function love.update(dt)
    --Blinking text for menu
    if gameState == "menu" then
        blinkTimer = blinkTimer + dt
        if blinkTimer > 0.6 then
            blinkVisible = not blinkVisible
            blinkTimer = 0
        end
        return
    end

    --Update idle animations on character select screen
    if gameState == "character_select" then
        for _, char in ipairs(characters) do
            char.idleAnim:update(dt)
        end
        return
    end

    if gameState ~= "playing" then
        return
    end

    --Freeze gameplay while paused
    if pauseMenu.active then
        return
    end

    --Death animation logic
    if player.isDead then
        dt = dt * 0.4

        player.deathAnim:update(dt)
        player.deathTimer = player.deathTimer + dt

        if player.deathTimer < 0.4 then
            camera.shake = 10 * (0.4 - player.deathTimer)
        else
            camera.shake = math.max(camera.shake - dt * 15, 0)
        end

        if player.deathTimer > 0.6 then
            player.fadeAlpha = math.min(player.fadeAlpha + dt * 0.8, 1)
        end

        if player.deathTimer > 0.5 then
            gameState = "gameover"
        end

        return
    end

    local isMoving = false

    --Player movement
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        player.x = player.x + player.speed * dt
        player.flip = false
        isMoving = true
    elseif love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        player.x = player.x - player.speed * dt
        player.flip = true
        isMoving = true
    end

    --Gravity and jumping
    player.yVelocity = player.yVelocity + player.gravity * dt
    player.y = player.y + player.yVelocity * dt

    --Ground collision
    if player.y + player.height * 3 >= groundY then
        player.y = groundY - player.height * 3
        player.yVelocity = 0
        player.onGround = true
        if not player.isHurt and not player.isThrowing then
            player.currentAnim = isMoving and player.runAnim or player.idleAnim
        end
    else
        player.onGround = false
        if not player.isHurt and not player.isThrowing then
            player.currentAnim = player.jumpAnim
        end
    end

    --Bomb spawn logic
    bombSpawnTimer = bombSpawnTimer + dt
    if bombSpawnTimer >= bombSpawnInterval and not bomb.active then
         bomb.x = player.x + love.math.random(400, 800)

        --Calculate the player’s max jump height
        local maxJumpHeight = groundY - ((player.jumpForce ^ 2) / (2 * player.gravity)) - player.height * 3

        --Random vertical position between ground and max height
        bomb.y = love.math.random(maxJumpHeight, groundY - bomb.height)

        bomb.active = true
        bombSpawnTimer = 0
        bombSpawnInterval = math.max(1.5, 5 - distance / 200)
    end

    if bomb.active and bomb.x < player.x - 200 then
        bomb.active = false
    end

    -- Shield spawn logic
    shieldSpawnTimer = shieldSpawnTimer + dt
    if shieldSpawnTimer >= shieldSpawnInterval and not shield.active and not shield.collected then
        shield.x = player.x + love.math.random(400, 900)
        shield.y = groundY - shield.height * 3
        shield.active = true
        shieldSpawnTimer = 0
    end

    --Bomb collision with the player
    if bomb.active and checkCollision(player.x, player.y, player.width * 3, player.height * 3,
                                      bomb.x, bomb.y, bomb.width, bomb.height) then
        if not shield.collected then
            bomb.active = false

            --PLAY EXPLOSION SOUND 
            explosionSound:stop() 
            explosionSound:play()

            --PLAY HURT SOUND
            hurtSound:stop()
            hurtSound:play()

            --Trigger explosion
            explosion.active = true
            explosion.x = bomb.x - 64
            explosion.y = bomb.y - 64
            explosion.anim:gotoFrame(1)
            explosion.anim:resume()

            player.speed = player.speed * 0.5
            player.slowTimer = 1
            player.isHurt = true
            player.hurtTimer = 0
            player.currentAnim = player.hurtAnim
            player.hurtAnim:gotoFrame(1)
        else
            --Shield absorbs the hit
            bomb.active = false
            shield.collected = false
        end
    end

    --Shield pickup
    if shield.active and checkCollision(player.x, player.y, player.width * 3, player.height * 3,
                                        shield.x, shield.y, shield.width, shield.height) then
        shield.active = false
        shield.collected = true
    end

    --Update explosion animation
    if explosion.active then
        explosion.anim:update(dt)
        if explosion.anim.position == explosion.anim.totalFrames then
            explosion.active = false
        end
    end

    --Player speed reset after bomb hit
    if player.slowTimer then
        player.slowTimer = player.slowTimer - dt
        if player.slowTimer <= 0 then
            player.speed = 350
            player.slowTimer = nil
        end
    end

    --Handle hurt animation timing
    if player.isHurt then
        player.hurtTimer = player.hurtTimer + dt
        player.hurtAnim:update(dt)
        if player.hurtTimer > 0.4 then
            player.isHurt = false
            player.currentAnim = player.idleAnim
        end
    end

    --Handle throw animation timing
    if player.isThrowing then
        player.throwAnim:update(dt)

        -- If animation is paused 
        if player.throwAnim.status == "paused" then
            player.isThrowing = false

            --reset to first frame for next time
            player.throwAnim:gotoFrame(1)

            --restore correct animation based on state
            if not player.onGround then
                player.currentAnim = player.jumpAnim
            else
                local moving = love.keyboard.isDown("left") or love.keyboard.isDown("a") or
                               love.keyboard.isDown("right") or love.keyboard.isDown("d")
                player.currentAnim = moving and player.runAnim or player.idleAnim
            end
        end
    end


    --Gorgon chases player
    if enemy.alive then
        if enemy.x < player.x then
            enemy.x = enemy.x + enemy.speed * dt
            enemy.flip = false
        elseif enemy.x > player.x then
            enemy.x = enemy.x - enemy.speed * dt
            enemy.flip = true
        end
    end

    if enemy.x < player.x - 800 then
        enemy.x = player.x - love.math.random(500, 800)
    end

    camera.x = player.x - love.graphics.getWidth() / 2
    if camera.x < 0 then camera.x = 0 end

    distance = math.floor(player.x / 10)

    --Gorgon always kills player on contact
    local playerScale = 3
    local enemyScale = 1.5
    if not player.isDead and
        checkCollision(player.x, player.y, player.width * playerScale, player.height * playerScale,
                  enemy.x, enemy.y, enemy.width * enemyScale, enemy.height * enemyScale) then

        hurtSound:stop()
        hurtSound:play()
        player.isDead = true
        player.deathTimer = 0
        player.deathAnim:gotoFrame(1)
        player.fadeAlpha = 0
        camera.shake = 10
    end

    --Fireball spawn
    fireballSpawnTimer = fireballSpawnTimer + dt
    if fireballSpawnTimer >= fireballSpawnInterval and not fireball.active then
        fireball.x = player.x + love.math.random(400, 900)
    
       -- Calculate player's maximum jump height
        local maxJumpHeight = groundY - ((player.jumpForce ^ 2) / (2 * player.gravity)) - player.height * 3

        -- Fireball can appear ANYWHERE between player max jump height and ground level
        fireball.y = love.math.random(maxJumpHeight, groundY - fireball.height * 3)

        fireball.active = true
        fireball.collected = false       
        fireballSpawnTimer = 0
        fireballSpawnInterval = love.math.random(4, 8)  
    end

    --Fireball pickup
    if fireball.active and checkCollision(player.x, player.y, player.width * 3, player.height * 3,
                                      fireball.x, fireball.y, fireball.width, fireball.height) then
        fireball.active = false
        fireball.collected = true
        player.fireMode = true           
        player.fireTimer = 10              
    end

    --Fireball timer countdown
    if player.fireMode then
        player.fireTimer = player.fireTimer - dt
        if player.fireTimer <= 0 then
            player.fireMode = false
        end
    end
    fireball.anim:update(dt)

    --Coin spawn logic
    coin.spawnTimer = coin.spawnTimer + dt
    if coin.spawnTimer >= coin.spawnInterval then
        --Calculate max jump height dynamically
        local maxJumpHeight = groundY - ((player.jumpForce ^ 2) / (2 * player.gravity)) - player.height * 3
        local spawnY = love.math.random(maxJumpHeight, groundY - 32 * 3)

        local newCoin = {
            x = player.x + love.math.random(400, 900),
            y = spawnY,
            anim = coin.anim:clone()
        }
        table.insert(coin.coins, newCoin)
        coin.spawnTimer = 0
    end

    --Update and collision for coins
    for i = #coin.coins, 1, -1 do
        local c = coin.coins[i]
        c.anim:update(dt)

        --Remove coin if far behind camera
        if c.x < player.x - 500 then
            table.remove(coin.coins, i)
        --Player collects coin
        elseif checkCollision(player.x, player.y, player.width * 3, player.height * 3,
                            c.x, c.y, 32, 32) then
            coinSound:stop()   
            coinSound:play()

            score = score + 10 
            table.remove(coin.coins, i)
        end
    end

    --Update firespell projectiles
    for i = #firespell.projectiles, 1, -1 do
        local spell = firespell.projectiles[i]
        spell.x = spell.x + firespell.speed * dt * spell.dir
        spell.anim:update(dt)

        --Check collision with bombs
        if bomb.active and checkCollision(spell.x, spell.y, 48, 48,
            bomb.x, bomb.y, bomb.width, bomb.height) then

            explosionSound:stop()
            explosionSound:play()

            --Destroy bomb with explosion
            bomb.active = false
            explosion.active = true
            explosion.x = bomb.x - 64
            explosion.y = bomb.y - 64
            explosion.anim:gotoFrame(1)
            explosion.anim:resume()

            --Remove the spell projectile
            table.remove(firespell.projectiles, i)

        --Check collision with Gorgon
        elseif enemy.alive and checkCollision(spell.x, spell.y, 48, 48,
            enemy.x, enemy.y, enemy.width * enemyScale, enemy.height * enemyScale) then
            
            camera.shake = 4
            explosion.active = true
            explosion.x = spell.x - 32
            explosion.y = spell.y - 32
            explosion.anim:gotoFrame(1)
            explosion.anim:resume()
            table.remove(firespell.projectiles, i)

        elseif spell.x < camera.x - 200 or spell.x > camera.x + love.graphics.getWidth() + 200 then
            table.remove(firespell.projectiles, i)
        end
    end

    player.currentAnim:update(dt)
    enemy.anim:update(dt)
end


function love.draw()
    --Main Menu Screen
    if gameState == "menu" then
        local bgScroll = (love.timer.getTime() * 50) % background:getWidth()
        for i = -1, math.ceil(love.graphics.getWidth() / background:getWidth()) + 1 do
            love.graphics.draw(background, i * background:getWidth() - bgScroll, 0)
        end

        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 1, 1)

        love.graphics.setFont(fonts.title)
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.printf("MONSTER RUNNER", 4, 154, love.graphics.getWidth(), "center")

        love.graphics.setColor(1, 0.3, 0.3)
        love.graphics.printf("MONSTER RUNNER", 0, 150, love.graphics.getWidth(), "center")

        love.graphics.setFont(fonts.subtitle)
        love.graphics.setColor(1, 1, 1)
        if blinkVisible then
            love.graphics.setColor(1, 1, 0.6)
            love.graphics.printf("Press ENTER or SPACE to Start", 0, 260, love.graphics.getWidth(), "center")
        end

        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.printf("Press ESC to Quit", 0, 420, love.graphics.getWidth(), "center")
        return
    end

    --Character Selection Screen
    if gameState == "character_select" then
        love.graphics.draw(background, 0, 0)
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 1, 1)

        love.graphics.setFont(fonts.title)
        love.graphics.printf("Select Your Monster", 0, 100, love.graphics.getWidth(), "center")

        local startX = love.graphics.getWidth() / 2 - (#characters * 200) / 2 
        local y = 240
        local scale = 5

        for i, char in ipairs(characters) do
            local x = startX + (i - 1) * 200
            if i == selectedCharacter then
                love.graphics.setColor(1, 1, 0.3)
                love.graphics.rectangle("line", x - 10, y - 10, 32 * scale + 20, 32 * scale + 20, 10, 10)
                love.graphics.setColor(1, 1, 1)
            end

            local pulse = 1
            if i == selectedCharacter then
                pulse = 1 + 0.05 * math.sin(love.timer.getTime() * 5)
            end

            local bounce = 5 * math.sin(love.timer.getTime() * 5)
            char.idleAnim:draw(char.idleSheet, x, y + bounce, 0, scale * pulse, scale * pulse)

            love.graphics.setFont(fonts.subtitle)
            love.graphics.printf(char.name, x - 10, y + 180, 150, "center")
        end

        love.graphics.setColor(1, 1, 0.6)
        love.graphics.printf("< LEFT / RIGHT >", 0, 520, love.graphics.getWidth(), "center")
        love.graphics.printf("Press ENTER to Confirm", 0, 560, love.graphics.getWidth(), "center")
        love.graphics.printf("ESC to go back", 0, 600, love.graphics.getWidth(), "center")
        return
    end   

    love.graphics.push()
    
    --Camera shake effect
    local shakeX = math.random(-camera.shake, camera.shake)
    local shakeY = math.random(-camera.shake, camera.shake)
    love.graphics.translate(-camera.x + shakeX, shakeY)
    
    --Draw scrolling background
    local bgWidth = background:getWidth()
    local startBg = math.floor(camera.x / bgWidth)
    local endBg = startBg + math.ceil(love.graphics.getWidth() / bgWidth) + 1
    for i = startBg, endBg do
        love.graphics.draw(background, i * bgWidth, 0)
    end

    --Draw tiled ground
    local startCol = math.floor(camera.x / tileSize)
    local endCol = startCol + groundCols

    for i = startCol, endCol do
        local x = i * tileSize
        local yTop = groundY               

        --draw grass on top
        local tile = (i == startCol) and groundTiles.topLeft or groundTiles.topMid
        love.graphics.draw(tile, x, yTop, 0, 1, 1)

        --draw filler dirt below it
        for r = 1, groundRows - 1 do
            love.graphics.draw(groundTiles.bottom, x, yTop + (r * tileSize))
        end
    end


    --Draw player
    local scale = 3
    if player.isDead then
        if player.flip then
            player.deathAnim:draw(player.deathSheet, player.x + player.width * scale, player.y, 0, -scale, scale)
        else
            player.deathAnim:draw(player.deathSheet, player.x, player.y, 0, scale, scale)
        end
    else
        local sheet = player.idleSheet
        if player.currentAnim == player.runAnim then
            sheet = player.runSheet
        elseif player.currentAnim == player.jumpAnim then
            sheet = player.jumpSheet
        elseif player.currentAnim == player.hurtAnim then
            sheet = player.hurtSheet
        elseif player.currentAnim == player.throwAnim then
            sheet = player.throwSheet
        end
        if player.flip then
            player.currentAnim:draw(sheet, player.x + player.width * scale, player.y, 0, -scale, scale)
        else
            player.currentAnim:draw(sheet, player.x, player.y, 0, scale, scale)
        end
    end

    --Draw enemy
    local enemyScale = 1.5
    if enemy.alive then
        if enemy.flip then
            enemy.anim:draw(enemy.sheet, enemy.x + enemy.width * enemyScale, enemy.y, 0, -enemyScale, enemyScale)
        else
            enemy.anim:draw(enemy.sheet, enemy.x, enemy.y, 0, enemyScale, enemyScale)
        end
    end

    --Draw bomb
    if bomb.active then
        love.graphics.draw(bomb.image, bomb.x, bomb.y, 0, 3, 3)
    end

    --Draw explosion
    if explosion.active then
        explosion.anim:draw(explosion.image, explosion.x, explosion.y, 0, explosion.scale, explosion.scale)
    end

    --Draw shield power-up
    if shield.active then
        love.graphics.draw(shield.image, shield.x, shield.y, 0, 3, 3)
    end

    --Draw shield effect around player if active
    if shield.collected then
        love.graphics.setColor(0, 0.7, 1, 0.4)
        love.graphics.circle("fill", player.x + player.width * 1.5, player.y + player.height * 1.5, 60)
        love.graphics.setColor(1, 1, 1)
    end

    --Draw fireball 
    if fireball.active then
        fireball.anim:draw(fireball.sheet, fireball.x, fireball.y, 0, 2, 2)
    end

    --Draw firespell
    for _, spell in ipairs(firespell.projectiles) do
        local s = 2.5
        spell.anim:draw(firespell.sheet, spell.x, spell.y, 0, s * spell.dir, s)
    end

    --Draw coins
    for _, c in ipairs(coin.coins) do
        c.anim:draw(coin.sheet, c.x, c.y, 0, 2, 2)
    end

    --Fire aura while powered
    if player.fireMode then
        love.graphics.setColor(1, 0.3, 0, 0.25)
        love.graphics.circle("fill", player.x + player.width * 1.5, player.y + player.height * 1.5, 65)
        love.graphics.setColor(1, 1, 1)
    end

    love.graphics.pop()

    --Draw distance and score
    if gameState == "playing" then
        love.graphics.setFont(font)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Distance: " .. distance .. " m", 20, 20)
        love.graphics.print("Score: " .. score, 20, 50)
        -- small hint when powered
        if player.fireMode then
            love.graphics.print("Fire Mode: F to shoot (" .. math.ceil(player.fireTimer) .. "s)", 20, 80)
        end
    end

    --Pause Menu
    if pauseMenu.active then
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 1, 1)

        local screenWidth, screenHeight = love.graphics.getWidth(), love.graphics.getHeight()
        local buttons = { pauseButtons.resume, pauseButtons.newGame, pauseButtons.quit }
        local buttonSpacing = 140

        local totalHeight = (#buttons - 1) * buttonSpacing
        local startY = (screenHeight - totalHeight) / 2 - 75

        for i, btn in ipairs(buttons) do
            local y = startY + (i - 1) * buttonSpacing
            local scaleBtn = (i == pauseMenu.selected) and 0.65 or 0.55
            local btnWidth = btn:getWidth() * scaleBtn
            local btnHeight = btn:getHeight() * scaleBtn
            local x = (screenWidth - btnWidth) / 2
            love.graphics.setColor(1, 1, 1, (i == pauseMenu.selected) and 1 or 0.7)
            love.graphics.draw(btn, x, y, 0, scaleBtn, scaleBtn)
        end
        love.graphics.setColor(1, 1, 1)
    end

    --Draw fade effect on death
    if player.isDead then
        love.graphics.setColor(0, 0, 0, player.fadeAlpha * 0.7)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 1, 1)
    end

    --Game Over Screen
    if gameState == "gameover" then
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("GAME OVER\nPress R to Return to Menu\nDistance: " .. distance .. " m",
            0, 200, love.graphics.getWidth(), "center")
    end
end


function love.keypressed(key)
    if gameState == "menu" then
        if key == "return" or key == "space" then
            gameState = "character_select"
        elseif key == "escape" then
            love.event.quit()
        end

    elseif gameState == "character_select" then
        --Navigate character selection
        if key == "right" then
            selectedCharacter = selectedCharacter + 1
            if selectedCharacter > #characters then selectedCharacter = 1 end
        elseif key == "left" then
            selectedCharacter = selectedCharacter - 1
            if selectedCharacter < 1 then selectedCharacter = #characters end
        elseif key == "return" or key == "space" then
            loadSelectedCharacter()
            gameState = "playing"
        elseif key == "escape" then
            gameState = "menu"
        end

    elseif gameState == "playing" then
        if pauseMenu.active then
            --Navigate pause menu
            if key == "up" then
                pauseMenu.selected = pauseMenu.selected - 1
                if pauseMenu.selected < 1 then pauseMenu.selected = #pauseMenu.options end
            elseif key == "down" then
                pauseMenu.selected = pauseMenu.selected + 1
                if pauseMenu.selected > #pauseMenu.options then pauseMenu.selected = 1 end
            elseif key == "return" or key == "space" then
                local choice = pauseMenu.options[pauseMenu.selected]
                if choice == "Resume" then
                    pauseMenu.active = false
                elseif choice == "New Game" then
                    love.load()
                    gameState = "menu"
                elseif choice == "Quit" then
                    love.event.quit()
                end
            elseif key == "escape" then
                pauseMenu.active = false
            end
            return
        end

        if key == "escape" then
            pauseMenu.active = true
            return
        end

        --Jumping 
        if key == "space" and player.onGround and not player.isDead then
            player.yVelocity = player.jumpForce
            player.onGround = false
            player.currentAnim = player.jumpAnim
            player.jumpAnim:gotoFrame(1)
        end

        --Shoot firespell while in fire mode
        if key == "f" and player.fireMode and not player.isDead and not player.isThrowing then
            player.isThrowing = true
            player.throwAnim:resume()
            player.throwAnim:gotoFrame(1)
            player.currentAnim = player.throwAnim

            local spellDir = player.flip and -1 or 1
            local playerScale = 3
            local centerX = player.x + (player.width * playerScale) / 2
            local centerY = player.y + (player.height * playerScale) / 2

            table.insert(firespell.projectiles, {
                x = centerX - 24,
                y = centerY - 24,
                dir = spellDir,
                anim = firespell.anim:clone()
            })
        end

    elseif gameState == "gameover" then
        if key == "r" then
            love.load()
            gameState = "menu"
        end
    end
end


function checkCollision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and
           x2 < x1 + w1 and
           y1 < y2 + h2 and
           y2 < y1 + h1
end
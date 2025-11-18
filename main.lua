--Load background music
gameMusic = love.audio.newSource("audio/game_music.ogg", "stream")
gameMusic:setLooping(true)
gameMusic:setVolume(0.5)  
gameMusic:play()

--High Score System
local highScore = 0
local highScore = 0   --total best score (distance + score)
local lastFinalScore = 0  --stores last run's combined final score

--Load saved high score
local function loadHighScore()
    if love.filesystem.getInfo("highscore.txt") then
        local contents = love.filesystem.read("highscore.txt")
        highScore = tonumber(contents) or 0
    end
end

--Save new high score
local function saveHighScore()
    love.filesystem.write("highscore.txt", tostring(highScore))
end

function love.load()
    anim8 = require 'libraries/anim8'
    love.window.setMode(900, 640, { resizable = false })
    loadHighScore()

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
        character_select = love.graphics.newFont("fonts/MonsterTitle.ttf", 36),
        countdown = love.graphics.newFont("fonts/Ghoulish.ttf",96),
        stage = love.graphics.newFont("fonts/Ghoulish.ttf", 40),
        numbers = love.graphics.newFont("fonts/Ghoulish.ttf", 36)
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
    -- Hitbox tuning
    hitbox = {
        playerShrink = 0.55,   
        enemyShrink  = 0.60,   
        bombShrink   = 0.70,   
        pickupGrow   = 1.15,   
    }
    

    --Load explosion sound effect
    explosionSound = love.audio.newSource("audio/explosion.ogg", "static")
    explosionSound:setVolume(0.9) 

    --Load hurt (damage) sound
    hurtSound = love.audio.newSource("audio/damage.ogg", "static")
    hurtSound:setVolume(0.8)

    --Load UI selection sound
    selectSound = love.audio.newSource("audio/laser.ogg", "static")
    selectSound:setVolume(0.8)

    coinSound = love.audio.newSource("audio/coin_sound.mp3", "static")
    coinSound:setVolume(0.9) 

    gameOverSound = love.audio.newSource("audio/8-bit-game-over-sound-effect-331435.mp3", "static")

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
        baseSpeed = 350,  
        speed = 350,  
        boostTimer = 0,  
        boostMultiplier = 1.5,  
        nextBoostDistance = 1000, 
        slowMultiplier = 1.0,
        slowTimer = 0,
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

    --Power-up spawn frequency increases each stage
    local spawnMultiplier = 1
    if player.stage == 1 then
        spawnMultiplier = 1.2
    elseif player.stage == 2 then
        spawnMultiplier = 1.5
    elseif player.stage == 3 then
        spawnMultiplier = 2.0
    end

    --Load default (Pink Monster)
    loadSelectedCharacter()

    --Gorgon setup
    enemy = {
        x = 0,
        y = groundY - 128 * 1.5,
        width = 128,
        height = 128,
        speed = 349,
        baseSpeed = 349,
        scale = 1.5,
        baseScale = 1.5,
        debuffTimer = 0, 
        flip = false,
        alive = true
    }

    enemy.recovering = false      
    enemy.recoverySpeed = 0       
    enemy.recoveryRate = 80       

    enemy.sheet = love.graphics.newImage('sprites/enemy_run.png')
    enemy.grid = anim8.newGrid(128, 128, enemy.sheet:getWidth(), enemy.sheet:getHeight())
    enemy.anim = anim8.newAnimation(enemy.grid('1-7', 1), 0.1)

    
    --Skeleton enemy
    skeleton = {
        x = -100,
        y = groundY - 128 * 1.2,
        width = 128,
        height = 128,
        speed = 120,
        direction = -1,
        scale = 1.2,
        alive = false,       
        patrolRange = 250        
    }

    skeleton.sheet = love.graphics.newImage("sprites/Walk.png")
    skeleton.grid = anim8.newGrid(128, 128, skeleton.sheet:getWidth(), skeleton.sheet:getHeight())
    skeleton.anim = anim8.newAnimation(skeleton.grid('1-7', 1), 0.09)

    --Skeleton death animation (4 frames)
    skeleton.deadSheet = love.graphics.newImage("sprites/Dead.png")
    skeleton.deadGrid = anim8.newGrid(128, 128,skeleton.deadSheet:getWidth(),skeleton.deadSheet:getHeight())

    skeleton.deadAnim = anim8.newAnimation(skeleton.deadGrid('1-4', 1),0.15,"pauseAtEnd")
    skeleton.isDead = false
    skeleton.deadTimer = 0
    
    player.stage = 0
    enemy.stage = 0

    --Game variables
    font = love.graphics.newFont(24)
    distance = 0
    distanceOffset = 0
    camera.x = 0
    camera.lock = true
    score = 0

    --Bomb setup
    bomb = {
        image = love.graphics.newImage("sprites/bomb.png"),
        x = -100,
        y = groundY - 32 * 3,
        width = 48,
        height = 48,
        active = false
    }
    bombSpawnTimer = 0
    bombSpawnInterval = math.max(1.0, (5 - distance / 200) / spawnMultiplier)

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
    fireballSpawnInterval = 6  

    --Skeleton spawn system
    skeletonSpawner = {
        timer = 0,
        interval = 6
    }

    --Yellow Potion Power-up (Enemy slowdown)
    lightningPotion = {
        sheet = love.graphics.newImage("sprites/yellow_potion_sheet.png"),
        x = -100,
        y = groundY - 16 * 3, 
        width = 16,
        height = 16,
        scale = 3,           
        active = false
    }
    lightningPotion.y = groundY - (lightningPotion.height * lightningPotion.scale)

    --Yellow Potion animation
    local potionGrid = anim8.newGrid(16, 16, lightningPotion.sheet:getWidth(),lightningPotion.sheet:getHeight())
    lightningPotion.anim = anim8.newAnimation(potionGrid('1-3', 1, '1-3', 2, '1-3', 3),0.10)
    lightningSpawnTimer = 0
    lightningSpawnInterval = 6  -- seconds until first spawn

    --Lightning strike animation
    lightning = {
        sheet = love.graphics.newImage("sprites/lightning-strike-Sheet.png"),
        x = 0,
        y = 0,
        active = false,
        scale = 4,
        life = 0, 
    }

    
    local lightningGrid = anim8.newGrid(168, 102, lightning.sheet:getWidth(), lightning.sheet:getHeight())
    lightning.anim = anim8.newAnimation(lightningGrid('1-10', 1), 0.08, 'pauseAtEnd')

    --Lightning hit sound
    lightningSound = love.audio.newSource("audio/lightning-spell-386163.mp3", "static")
    lightningSound:setVolume(0.8)

    --Firespell projectile setup (animated shots)
    firespell = {
        sheet = love.graphics.newImage("sprites/firespell_sheet.png"), 
        projectiles = {},
        speed = 600
    }
    local firespellGrid = anim8.newGrid(32, 32, firespell.sheet:getWidth(), firespell.sheet:getHeight())
    firespell.anim = anim8.newAnimation(firespellGrid('1-8', 1), 0.08)

    --Coin setup 
    coin = {
        sheet = love.graphics.newImage("sprites/coin_sheet.png"),
        coins = {},
        spawnTimer = 0,
        spawnInterval = 2  
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
    
    --Game state management
    gameState = "menu" 
    blinkTimer = 0
    blinkVisible = true

    -- GAME OVER title animation
    local gameOverTime = 0
    local gameOverFade = 0
    local gameOverShake = 0
    local gameOverScale = 1

    --Countdown
    countdown = {
        active = false,
        timer = 0,
        number = 3,
        justEnded = false
    }

    --Stage Messages
    stageMessage = ""
    stageMessageAlpha = 0
    stageMessageTimer = 0

    stageBanner = {
        text = "",
        alpha = 0,
        y = -100,          
        timer = 0,
        active = false,
        scale = 1
    }

    deathMusicDelay = 0
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

function showStageMessage(text)
    stageBanner.text = text
    stageBanner.alpha = 0        
    stageBanner.y = -100
    stageBanner.targetY = 150         
    stageBanner.timer = 3        
    stageBanner.scale = 0.5     
    stageBanner.active = true      
    stageBanner.animDone = false
end


function love.update(dt)
    local realDT = dt

    --Death music silence timer
    if deathMusicDelay and deathMusicDelay > 0 then
        deathMusicDelay = deathMusicDelay - dt
        if deathMusicDelay <= 0 then
            gameMusic:play()     --restart music AFTER delay
        end
    end

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

    if gameState == "gameover" then
        gameOverTime = gameOverTime + dt

        --Fade in
        gameOverFade = math.min(1, gameOverFade + dt * 1.2)

        --Pulse scaling
        gameOverScale = 1 + math.sin(gameOverTime * 2.5) * 0.08

        --Shake decreases over time
        gameOverShake = math.max(0, gameOverShake - dt * 2)
    end

    --Stage message fade-out
    if stageMessageTimer > 0 then
        stageMessageTimer = stageMessageTimer - dt
    else
        stageMessageAlpha = math.max(0, stageMessageAlpha - dt * 1.5)
    end

    if gameState ~= "playing" then
        --ONLY auto-play during menu or character select
        if gameState == "menu" or gameState == "character_select" then
            if deathMusicDelay <= 0 then
                gameMusic:play()
            end
        end
        return
    end

    -- Handle countdown before gameplay starts
    if countdown.active then
        countdown.timer = countdown.timer + dt

        if countdown.timer >= 1.0 then
            countdown.timer = 0
            countdown.number = countdown.number - 1

            if countdown.number < 0 then
                countdown.active = false
                countdown.justEnded = true   
            end
        end

        return
    end
    
    --LOCK camera immediately after countdown ends
    if countdown.justEnded then
        countdown.justEnded = false
        camera.lock = true      
        return
    end

    --Unlock camera on the FIRST real gameplay frame
    if camera.lock then
        camera.lock = false
    end

    --Freeze gameplay while paused
    if pauseMenu.active then
        return
    end

    --Stage Banner Animation
    if stageBanner.active then
        stageBanner.timer = stageBanner.timer - dt

        --Fade in for first 0.5 sec
        if stageBanner.alpha < 1 and stageBanner.timer > 1.5 then
            stageBanner.alpha = math.min(1, stageBanner.alpha + dt * 2)
        end

        --Slide-down animation toward targetY
        if stageBanner.y < stageBanner.targetY then
            stageBanner.y = stageBanner.y + dt * 200
            if stageBanner.y > stageBanner.targetY then
                stageBanner.y = stageBanner.targetY
            end
        end

        --Pop animation
        stageBanner.scale = stageBanner.scale + dt * 2
        if stageBanner.scale > 1 then
            stageBanner.scale = 1
        end

        --Fade-out near the end
        if stageBanner.timer < 0.7 then
            stageBanner.alpha = math.max(0, stageBanner.alpha - dt * 2)
        end

        --Remove when done
        if stageBanner.timer <= 0 then
            stageBanner.active = false
        end
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

    -- DESPAWN lightning potion if it gets too far behind the player
    if lightningPotion.active and lightningPotion.x < player.x - 600 then
        lightningPotion.active = false
        lightningPotion.collected = false
        lightningSpawnTimer = 0
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
        bomb.y = love.math.random(maxJumpHeight, groundY - bomb.height * 3)

        bomb.active = true
        bombSpawnTimer = 0
        bombSpawnInterval = math.max(1.5, 5 - distance / 200)
    end

    if bomb.active and bomb.x < player.x - 200 then
        bomb.active = false
    end

    --Shield spawn logic
    shieldSpawnTimer = shieldSpawnTimer + dt
    if shieldSpawnTimer >= shieldSpawnInterval and not shield.active and not shield.collected then
        shield.x = player.x + love.math.random(400, 900)
        shield.y = groundY - shield.height * 3
        shield.active = true
        shieldSpawnTimer = 0
    end

    --Bomb collision with the player
    if bomb.active and checkCollision(player.x, player.y, player.width * 3, player.height * 3, bomb.x, bomb.y, bomb.width, bomb.height,
                                      hitbox.playerShrink, hitbox.bombShrink) then
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

            player.slowMultiplier = 0.5
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
                                        shield.x, shield.y, shield.width, shield.height,
                                        hitbox.playerShrink, hitbox.pickupGrow
    ) then
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
            player.slowTimer = 0
            player.slowMultiplier = 1.0
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

        --If animation is paused 
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

    --Gorgon recovery logic 
    if enemy.recovering then
        local cameraRight = camera.x + love.graphics.getWidth()

        -- Accelerate while still off camera
        if enemy.x < cameraRight - 150 then
            enemy.recoverySpeed = enemy.recoverySpeed + enemy.recoveryRate * dt

            -- Cap at normal speed
            if enemy.recoverySpeed >= enemy.baseSpeed then
                enemy.recoverySpeed = enemy.baseSpeed
                enemy.recovering = false
            end

            enemy.speed = enemy.recoverySpeed

        else
            --Gorgon is visible again → stop recovery
            enemy.recovering = false
            enemy.speed = enemy.baseSpeed
        end
    end

    if enemy.x < player.x - 800 then
        enemy.x = player.x - love.math.random(500, 800)
    end

    --Skeleton movement (Goomba-style patrol)
    if skeleton.alive then
        skeleton.startX = skeleton.startX or skeleton.x

        skeleton.x = skeleton.x + skeleton.speed * dt * skeleton.direction

        if skeleton.x < skeleton.startX - skeleton.patrolRange then
            skeleton.direction = 1
        elseif skeleton.x > skeleton.startX + skeleton.patrolRange then
            skeleton.direction = -1
        end

        skeleton.anim:update(dt)
    end

    --Update skeleton hit cooldown
    if skeleton.hitCooldown and skeleton.hitCooldown > 0 then
        skeleton.hitCooldown = skeleton.hitCooldown - dt
    end

    --Despawn skeleton if too far behind player
    if skeleton.alive and skeleton.x < player.x - 600 then
        skeleton.alive = false
    end

    if not camera.lock then
        camera.x = player.x - love.graphics.getWidth() / 2
        if camera.x < 0 then camera.x = 0 end
    end

    --Distance starts at 0
    distance = math.floor((player.x - distanceOffset) / 10)

    --Stage progression logic
    if distance >= 3000 and player.stage < 3 then
        player.stage = 3
        enemy.stage = 3
        showStageMessage("STAGE 3 REACHED!")
    elseif distance >= 2000 and player.stage < 2 then
        player.stage = 2
        enemy.stage = 2
        showStageMessage("STAGE 2 REACHED!")
    elseif distance >= 1000 and player.stage < 1 then
        player.stage = 1
        enemy.stage = 1
        showStageMessage("STAGE 1 REACHED!")
    end

    spawnMultiplier = 1 + (player.stage * 0.2)

    

    --Apply permanent speed increase per stage
    local stageSpeeds = { 
        [0] = 350,   --default
        [1] = 450,   --stage 1
        [2] = 550,   --stage 2
        [3] = 650    --stage 3
    }

    player.speed = stageSpeeds[player.stage] * player.slowMultiplier
    if enemy.debuffTimer <= 0 then
        enemy.speed = stageSpeeds[enemy.stage] * 0.99
    end  

    --Increase firespell speed based on stage
    if player.stage == 0 then
        firespell.speed = 600     
    elseif player.stage == 1 then
        firespell.speed = 700
    elseif player.stage == 2 then
        firespell.speed = 900     
    elseif player.stage == 3 then
        firespell.speed = 1100    
    end
    

    --Gorgon always kills player on contact
    local playerScale = 3
    if not player.isDead and
        checkCollision(player.x, player.y, player.width * 3, player.height * 3,
                       enemy.x, enemy.y, enemy.width * enemy.scale, enemy.height * enemy.scale,
                       hitbox.playerShrink, hitbox.enemyShrink) then

        hurtSound:stop()
        hurtSound:play()
        player.isDead = true
        player.deathTimer = 0
        player.deathAnim:gotoFrame(1)
        player.fadeAlpha = 0
        camera.shake = 10

        gameMusic:stop()

        gameOverSound:stop()
        gameOverSound:play()

        --Add silence gap before restarting game music
        deathMusicDelay = 5.0 

        --FINAL SCORE = distance + coin score
        lastFinalScore = distance + score

        --Check for new high score
        if lastFinalScore > highScore then
            highScore = lastFinalScore
            saveHighScore()
        end

        --Reset GAME OVER animation
        gameOverTime = 0
        gameOverFade = 0
        gameOverShake = 4      
        gameOverScale = 0.6   
    end

    --Skeleton collision 
    if skeleton.alive then

        if checkCollision(
            player.x, player.y, player.width * 3, player.height * 3,
            skeleton.x, skeleton.y,
            skeleton.width * skeleton.scale,
            skeleton.height * skeleton.scale,
            hitbox.playerShrink, hitbox.enemyShrink
        ) then

            --Prevent rapid re-hits
            if skeleton.hitCooldown and skeleton.hitCooldown > 0 then
                -- ignore collision
            else
                if shield.collected then
                    --Shield blocks skeleton just like bombs
                    shield.collected = false
                    skeleton.hitCooldown = 0.5   -- prevent immediate re-hit
                else
                    --Skeleton hurts player normally
                    hurtSound:stop()
                    hurtSound:play()

                    player.slowMultiplier = 0.5
                    player.slowTimer = 1.0

                    player.isHurt = true
                    player.hurtTimer = 0
                    player.currentAnim = player.hurtAnim
                    player.hurtAnim:gotoFrame(1)
                end
            end
        end
    end

    --Fireball spawn
    fireballSpawnTimer = fireballSpawnTimer + dt
    if fireballSpawnTimer >= fireballSpawnInterval and not fireball.collected then
        fireball.x = player.x + love.math.random(400, 900)
    
       --Calculate player's maximum jump height
        local maxJumpHeight = groundY - ((player.jumpForce ^ 2) / (2 * player.gravity)) - player.height * 3

        --Fireball can appear ANYWHERE between player max jump height and ground level
        fireball.y = love.math.random(maxJumpHeight, groundY - fireball.height * 3)

        fireball.active = true
        fireball.collected = false       
        fireballSpawnTimer = 0
        fireballSpawnInterval = love.math.random(4, 8) / spawnMultiplier
    end

    --Fireball pickup
    if fireball.active and checkCollision(
        player.x, player.y, player.width * 3, player.height * 3,
        fireball.x, fireball.y, fireball.width, fireball.height,
        hitbox.playerShrink, hitbox.pickupGrow
    ) then
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
            fireball.collected = false
        end
    end
    fireball.anim:update(dt)

    --Lightning Potion spawn logic
    lightningSpawnTimer = lightningSpawnTimer + dt
    if lightningSpawnTimer >= lightningSpawnInterval and not lightningPotion.active then
        lightningPotion.x = player.x + love.math.random(400, 900)
        lightningPotion.y = groundY - (lightningPotion.height * lightningPotion.scale) - 5
        lightningPotion.active = true
        lightningSpawnTimer = 0
        lightningSpawnInterval = love.math.random(4, 8) / spawnMultiplier
    end


    --Lightning Potion pickup
    if lightningPotion.active and 
        checkCollision(player.x, player.y, player.width * 3, player.height * 3,
                    lightningPotion.x, lightningPotion.y,
                    lightningPotion.width * lightningPotion.scale,
                    lightningPotion.height * lightningPotion.scale,
                    hitbox.playerShrink, hitbox.pickupGrow)
    then
        lightningPotion.active = false
        lightningPotion.collected = true
        lightningSpawnTimer = 0

        if enemy.alive then
            lightningSound:stop()
            lightningSound:play()

            lightning.active = true
            lightning.anim:gotoFrame(1)
            lightning.anim:resume()
            lightning.life = 1.5

            local frameW, frameH = 168, 102
            lightning.x = enemy.x + (enemy.width * enemy.scale)/2 - (frameW * lightning.scale)/2
            lightning.y = enemy.y - frameH * lightning.scale * 0.3

            enemy.speed = enemy.baseSpeed * 0.5
            enemy.scale = enemy.baseScale * 0.6
            enemy.y = groundY - enemy.height * enemy.scale
            enemy.debuffTimer = 3
        end
    end

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
        elseif checkCollision(
                player.x, player.y, player.width * 3, player.height * 3,
                c.x, c.y, 32, 32,
                hitbox.playerShrink, hitbox.pickupGrow
            ) then

            coinSound:stop()   
            coinSound:play()

            score = score + 10 
            table.remove(coin.coins, i)
        end
    end

    --Update death animation
    if skeleton.isDead then
        skeleton.deadAnim:update(dt)
        skeleton.deadTimer = skeleton.deadTimer + dt

        --Remove corpse after finished
        if skeleton.deadTimer > 1.0 then
            skeleton.isDead = false
        end
    end

    --Skeleton spawn logic
    skeletonSpawner.timer = skeletonSpawner.timer + dt

    if skeletonSpawner.timer >= skeletonSpawner.interval and not skeleton.alive then
        skeleton.x = player.x + love.math.random(400, 900)
        skeleton.y = groundY - skeleton.height * skeleton.scale
        skeleton.direction = love.math.random(0, 1) == 0 and -1 or 1
        skeleton.alive = true

        --Reset patrol center
        skeleton.startX = skeleton.x

        skeletonSpawner.timer = 0
        local baseMin = 5
        local baseMax = 9

        skeletonSpawner.interval = love.math.random(
            baseMin / spawnMultiplier,
            baseMax / spawnMultiplier
        )
    end

    --Update Lightning Potion animation
    if lightningPotion.active then
        lightningPotion.anim:update(dt)
    end

    --Update lightning strike animation
    if lightning.active then
        lightning.anim:update(dt)
        lightning.life = lightning.life - dt
        if lightning.life <= 0 then
            lightning.active = false
            lightningPotion.collected = false   -- NEW
        end
    end



    --Enemy lightning debuff timer
    if enemy.debuffTimer and enemy.debuffTimer > 0 then
        enemy.debuffTimer = enemy.debuffTimer - dt
        if enemy.debuffTimer <= 0 then
            enemy.debuffTimer = 0

            --Enemy lightning debuff timer
            if enemy.debuffTimer and enemy.debuffTimer > 0 then
                enemy.debuffTimer = enemy.debuffTimer - dt
                if enemy.debuffTimer <= 0 then
                    enemy.debuffTimer = 0

                    --Instantly restore speed and size
                    enemy.speed = enemy.baseSpeed
                    enemy.scale = enemy.baseScale
                    enemy.y = groundY - enemy.height * enemy.scale
                    enemy.recovering = false

                    --Guarantee Gorgon is near player after debuff ends
                    local distanceFromPlayer = enemy.x - player.x

                    --If enemy is too far behind OR too far ahead
                    if distanceFromPlayer < -600 or distanceFromPlayer > 600 then
                        --Teleport Gorgon right behind player (close range)
                        enemy.x = player.x - love.math.random(250, 400)
                    end
                end
            end

            --Restore normal size immediately
            enemy.scale = enemy.baseScale
            enemy.y = groundY - enemy.height * enemy.scale
        end
    end

    --Update firespell projectiles
    for i = #firespell.projectiles, 1, -1 do
        local spell = firespell.projectiles[i]
        spell.x = spell.x + firespell.speed * realDT * spell.dir
        spell.anim:update(realDT)

        --Check collision with bombs
        if bomb.active and checkCollision(spell.x, spell.y, 48, 48,
                bomb.x, bomb.y, bomb.width, bomb.height,
                1, hitbox.bombShrink
            ) then

            explosionSound:stop()
            explosionSound:play()

            --Destroy bomb with explosion
            bomb.active = false
            explosion.active = true
            explosion.x = bomb.x - 64
            explosion.y = bomb.y - 64
            explosion.anim:gotoFrame(1)
            explosion.anim:resume()

            score = score + 5

            --Remove the spell projectile
            table.remove(firespell.projectiles, i)

        --Check collision with Gorgon
        elseif enemy.alive and checkCollision(
                spell.x, spell.y, 48, 48,
                enemy.x, enemy.y, enemy.width * enemy.scale, enemy.height * enemy.scale,
                1, hitbox.enemyShrink
            ) then
            
            camera.shake = 4
            explosion.active = true
            explosion.x = spell.x - 32
            explosion.y = spell.y - 32
            explosion.anim:gotoFrame(1)
            explosion.anim:resume()
            table.remove(firespell.projectiles, i)
        
        --Fireball kills skeleton
        elseif skeleton.alive and
            checkCollision(
                spell.x, spell.y, 48, 48,
                skeleton.x, skeleton.y,
                skeleton.width * skeleton.scale,
                skeleton.height * skeleton.scale,
                1, hitbox.enemyShrink
            )
        then
            --Spawn small explosion
            explosion.active = true
            explosion.x = spell.x - 32
            explosion.y = spell.y - 32
            explosion.anim:gotoFrame(1)
            explosion.anim:resume()

            --Kill skeleton
            skeleton.alive = false
            skeleton.isDead = true
            skeleton.deadTimer = 0

            score = score + 10

            --Remove projectile
            table.remove(firespell.projectiles, i)

        --Remove if far off-screen
        elseif spell.x < camera.x - 200 or spell.x > camera.x + love.graphics.getWidth() + 200 then
            table.remove(firespell.projectiles, i)
        end
    end

    --Ensure Gorgon is on-screen after debuff
    if enemy.debuffTimer == 0 then
        local distanceFromPlayer = enemy.x - player.x

        --If enemy is still too far behind or ahead AFTER all movement
        if distanceFromPlayer < -600 or distanceFromPlayer > 600 then
            --Forced teleport closer behind player
            enemy.x = player.x - love.math.random(400, 650)
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
    if enemy.alive then
        if enemy.flip then
            enemy.anim:draw(enemy.sheet, enemy.x + enemy.width * enemy.scale, enemy.y, 0, -enemy.scale, enemy.scale)
        else
            enemy.anim:draw(enemy.sheet, enemy.x, enemy.y, 0, enemy.scale, enemy.scale)
        end
    end

    --Draw skeleton
    if skeleton.alive then
        --Walking animation
        if skeleton.direction == -1 then
            skeleton.anim:draw(
                skeleton.sheet,
                skeleton.x + skeleton.width * skeleton.scale,
                skeleton.y,
                0,
                -skeleton.scale,
                skeleton.scale
            )
        else
            skeleton.anim:draw(
                skeleton.sheet,
                skeleton.x,
                skeleton.y,
                0,
                skeleton.scale,
                skeleton.scale
            )
        end

    elseif skeleton.isDead then
        --Death animation
        skeleton.deadAnim:draw(
            skeleton.deadSheet,
            skeleton.x,
            skeleton.y,
            0,
            skeleton.scale,
            skeleton.scale
        )
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

    --Draw Lightning Potion
    if lightningPotion.active then
        local s = lightningPotion.scale   
        lightningPotion.anim:draw(
            lightningPotion.sheet,
            lightningPotion.x,
            lightningPotion.y,
            0,
            s,
            s)
    end

    --Draw lightning strike on enemy
    if lightning.active then
        lightning.anim:draw(lightning.sheet, lightning.x, lightning.y, 0, lightning.scale, lightning.scale)
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

        -- Draw Stage Banner
        if stageBanner.active then
            --Save current font
            local previousFont = love.graphics.getFont()

            love.graphics.setFont(fonts.stage)
            love.graphics.setColor(1, 1, 0, stageBanner.alpha)

            local text = stageBanner.text
            local textW = fonts.stage:getWidth(text)
            local textH = fonts.stage:getHeight()

            love.graphics.push()
            love.graphics.translate(love.graphics.getWidth() / 2, stageBanner.y)
            love.graphics.scale(stageBanner.scale, stageBanner.scale)
            love.graphics.printf(text, -textW / 2, -textH / 2, textW, "center")
            love.graphics.pop()

            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(previousFont)
        end
        
        --Show countdown overlay on top of the game
        if countdown.active then
            love.graphics.setColor(0, 0, 0, 0.5)
            love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
            
            love.graphics.setFont(fonts.countdown)
            love.graphics.setColor(1, 1, 0.3)
            
            if countdown.number > 0 then
                love.graphics.printf(tostring(countdown.number), 0, 250, love.graphics.getWidth(), "center")
            else
                love.graphics.setColor(0.4, 1, 0.4)
                love.graphics.printf("GO", 0, 250, love.graphics.getWidth(), "center")
            end

            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(font)
        else
           --Draw Distance and Score when Countdown is done
            love.graphics.print("Distance: " .. distance .. " m", 20, 20)
            love.graphics.print("Score: " .. score, 20, 50)

            --Small hint when powered
            if player.fireMode then
                love.graphics.print("Fire Mode: F to shoot (" .. math.ceil(player.fireTimer) .. "s)", 20, 80)
            end
            --Hint to pause
            local hint = "Press ESC to pause"
            local hintW = font:getWidth(hint)
            local margin = 20
            love.graphics.print(hint,
                love.graphics.getWidth() - hintW - margin,
                margin)
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
    end

    --Draw fade effect on death
    if player.isDead then
        love.graphics.setColor(0, 0, 0, player.fadeAlpha * 0.7)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 1, 1)
    end

    --Game Over Screen
    if gameState == "gameover" then
        local w, h = love.graphics.getWidth(), love.graphics.getHeight()
        local offsetY = -40

        love.graphics.setColor(0, 0, 0, 0.75)
        love.graphics.rectangle("fill", 0, 0, w, h)

       
        --TITLE
        love.graphics.setFont(fonts.title)
        love.graphics.setColor(1, 0.3, 0.3)
        local title = "GAME OVER"

        local shakeX = (math.random() - 0.5) * gameOverShake * 5

        love.graphics.setFont(fonts.title)
        love.graphics.setColor(1, 0.3, 0.3, gameOverFade)

        love.graphics.push()
        love.graphics.translate(w/2 + shakeX, h * 0.20 + offsetY)
        love.graphics.scale(gameOverScale, gameOverScale)
        love.graphics.printf(title, -w/2, 0, w, "center")
        love.graphics.pop()

        --SHARED SETTINGS
        local labelFont = fonts.subtitle
        local numberFont = fonts.numbers
        local numOffsetY = -3


        --SCORE
        local scoreLabel = "Score "
        local scoreValue = tostring(score)

        local scoreY = h * 0.45 + offsetY
        local labelW = labelFont:getWidth(scoreLabel)
        local valueW = numberFont:getWidth(scoreValue)
        local startX = (w - (labelW + valueW)) / 2

        love.graphics.setFont(labelFont)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(scoreLabel, startX, scoreY)

        love.graphics.setFont(numberFont)
        love.graphics.setColor(1, 1, 0.5)
        love.graphics.print(scoreValue, startX + labelW, scoreY + numOffsetY)

        --DISTANCE
        local distLabelLeft = "Distance "
        local distValue = tostring(distance)
        local distLabelRight = " m"

        local leftW = labelFont:getWidth(distLabelLeft)
        local numW = numberFont:getWidth(distValue)
        local rightW = labelFont:getWidth(distLabelRight)

        local distY = h * 0.52 + offsetY
        local distX = (w - (leftW + numW + rightW)) / 2

        love.graphics.setFont(labelFont)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(distLabelLeft, distX, distY)

        love.graphics.setFont(numberFont)
        love.graphics.setColor(1, 1, 0.5)
        love.graphics.print(distValue, distX + leftW, distY + numOffsetY)

        love.graphics.setFont(labelFont)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(distLabelRight, distX + leftW + numW, distY)


        --FINAL SCORE
        local finalLabel = "Final Score "
        local finalValue = tostring(lastFinalScore)

        local finalLabelW = labelFont:getWidth(finalLabel)
        local finalValueW = numberFont:getWidth(finalValue)
        local finalY = h * 0.59 + offsetY
        local finalX = (w - (finalLabelW + finalValueW)) / 2

        love.graphics.setFont(labelFont)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(finalLabel, finalX, finalY)

        love.graphics.setFont(numberFont)
        love.graphics.setColor(1, 1, 0.5)
        love.graphics.print(finalValue, finalX + finalLabelW, finalY + numOffsetY)



        --HIGH SCORE
        local hsLabel = "High Score "
        local hsValue = tostring(highScore)

        local hsLabelW = labelFont:getWidth(hsLabel)
        local hsValueW = numberFont:getWidth(hsValue)
        local hsY = h * 0.66 + offsetY
        local hsX = (w - (hsLabelW + hsValueW)) / 2

        love.graphics.setFont(labelFont)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(hsLabel, hsX, hsY)

        love.graphics.setFont(numberFont)
        love.graphics.setColor(1, 1, 0.5)
        love.graphics.print(hsValue, hsX + hsLabelW, hsY + numOffsetY)

        --BUTTONS
        love.graphics.setFont(fonts.subtitle)
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.printf("Press ENTER to Replay", 0, h * 0.74 + offsetY, w, "center")
        love.graphics.printf("Press R to Return to Menu", 0, h * 0.80 + offsetY, w, "center")
    end
end


function love.keypressed(key)

    --Menu
    if gameState == "menu" then
        if key == "return" or key == "space" then
            gameState = "character_select"
        elseif key == "escape" then
            love.event.quit()
        end


    
    --Character
    elseif gameState == "character_select" then
        
        if key == "right" then
            selectedCharacter = selectedCharacter + 1
            if selectedCharacter > #characters then 
                selectedCharacter = 1 
            end
        
        elseif key == "left" then
            selectedCharacter = selectedCharacter - 1
            if selectedCharacter < 1 then 
                selectedCharacter = #characters 
            end
        
        elseif key == "return" or key == "space" then
            loadSelectedCharacter()

            -- NEW: Start countdown
            countdown.active = true
            countdown.timer  = 0
            countdown.number = 3

            gameState = "playing"
            distanceOffset = player.x
        
        elseif key == "escape" then
            gameState = "menu"
        end


    --Playing
    elseif gameState == "playing" then
        
        --PAUSE MENU
        if pauseMenu.active then
            
            if key == "up" then
                pauseMenu.selected = pauseMenu.selected - 1
                if pauseMenu.selected < 1 then 
                    pauseMenu.selected = #pauseMenu.options 
                end
            
            elseif key == "down" then
                pauseMenu.selected = pauseMenu.selected + 1
                if pauseMenu.selected > #pauseMenu.options then 
                    pauseMenu.selected = 1 
                end

            elseif key == "return" or key == "space" then
                local choice = pauseMenu.options[pauseMenu.selected]

                if choice == "Resume" then
                    pauseMenu.active = false

                    --Countdown when resuming
                    countdown.active = true
                    countdown.timer  = 0
                    countdown.number = 3
                
                elseif choice == "New Game" then
                    love.load()
                    gameState = "menu"
                
                elseif choice == "Quit" then
                    love.event.quit()
                end
            
            elseif key == "escape" then
                --Resume with ESC + countdown
                pauseMenu.active = false
                countdown.active = true
                countdown.timer  = 0
                countdown.number = 3
            end

            return
        end

        --Enter pause
        if key == "escape" then
            pauseMenu.active = true
            return
        end

        --Jump
        if key == "space" and player.onGround and not player.isDead then
            player.yVelocity = player.jumpForce
            player.onGround = false
            player.currentAnim = player.jumpAnim
            player.jumpAnim:gotoFrame(1)
        end

        --Fire spell
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


    --GAME OVER
    elseif gameState == "gameover" then
        
        if key == "r" then
            love.load()
            gameState = "menu"

        elseif key == "return" or key == "space" then
            love.load()
            gameState = "playing"

            --countdown when restarting
            countdown.active = true
            countdown.timer  = 0
            countdown.number = 3
        end
    end
end


function checkCollision(x1, y1, w1, h1, x2, y2, w2, h2, shrink1, shrink2)
    shrink1 = shrink1 or 1
    shrink2 = shrink2 or 1

    local hw1 = w1 * shrink1
    local hh1 = h1 * shrink1
    local hw2 = w2 * shrink2
    local hh2 = h2 * shrink2

    --recenter shrunk hitboxes
    local nx1 = x1 + (w1 - hw1) / 2
    local ny1 = y1 + (h1 - hh1) / 2
    local nx2 = x2 + (w2 - hw2) / 2
    local ny2 = y2 + (h2 - hh2) / 2

    return nx1 < nx2 + hw2 and
           nx2 < nx1 + hw1 and
           ny1 < ny2 + hh2 and
           ny2 < ny1 + hh1
end

function love.mousepressed(x, y, button)

    --Handle clicks when game is paused
    if button == 1 and gameState == "playing" and pauseMenu.active then

        local screenWidth, screenHeight = love.graphics.getWidth(), love.graphics.getHeight()
        local buttons = { pauseButtons.resume, pauseButtons.newGame, pauseButtons.quit }
        local buttonSpacing = 140

        local totalHeight = (#buttons - 1) * buttonSpacing
        local startY = (screenHeight - totalHeight) / 2 - 75

        for i, img in ipairs(buttons) do
            
            local scaleBtn = (i == pauseMenu.selected) and 0.65 or 0.55
            local btnWidth  = img:getWidth()  * scaleBtn
            local btnHeight = img:getHeight() * scaleBtn

            local btnX = (screenWidth - btnWidth) / 2
            local btnY = startY + (i - 1) * buttonSpacing

            --Click detection
            if x >= btnX and x <= btnX + btnWidth and
               y >= btnY and y <= btnY + btnHeight then
                
                local choice = pauseMenu.options[i]

                if choice == "Resume" then
                    pauseMenu.active = false

                elseif choice == "New Game" then
                    love.load()
                    gameState = "menu"

                elseif choice == "Quit" then
                    love.event.quit()
                end

                break
            end
        end
    end
end
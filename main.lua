function love.load()
    anim8 = require 'libraries/anim8'

    --Background
    background = love.graphics.newImage('sprites/cal.jpg')

    --Camera and world
    camera = { x = 0, y = 0, shake = 0 }
    groundY = 500

    --Custom Fonts
    fonts = {
        title = love.graphics.newFont("fonts/MonsterTitle.ttf", 72),
        subtitle = love.graphics.newFont("fonts/MonsterTitle.ttf", 28),
        character_select = love.graphics.newFont("fonts/MonsterTitle.ttf", 36)
    }

    --Character selection setup
    characters = {
        {
            name = "Pink Monster",
            run = 'sprites/Pink_Monster_Run_6.png',
            jump = 'sprites/Pink_Monster_Jump_8.png',
            idle = 'sprites/Pink_Monster_Idle_4.png',
            deathSheet = "sprites/Pink_Monster_Death_8.png",
            image = love.graphics.newImage("sprites/Pink_Monster.png")
        },
        {
            name = "Owlet Monster",
            run = 'sprites/Owlet_Monster_Run_6.png',
            jump = 'sprites/Owlet_Monster_Jump_8.png',
            idle = 'sprites/Owlet_Monster_Idle_4.png',
            deathSheet = "sprites/Owlet_Monster_Death_8.png",
            image = love.graphics.newImage("sprites/Owlet_Monster.png")
        },
        {
            name = "Dude Monster",
            run = 'sprites/Dude_Monster_Run_6.png',
            jump = 'sprites/Dude_Monster_Jump_8.png',
            idle = 'sprites/Dude_Monster_Idle_4.png',
            deathSheet = "sprites/Dude_Monster_Death_8.png",
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
        jumpForce = -600,
        gravity = 1500,
        onGround = true,
        flip = false,
        isDead = false,
        deathTimer = 0,
        fadeAlpha = 0
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

    -- Game variables
    font = love.graphics.newFont(24)
    distance = 0
    camera.x = 0

    -- Game state management
    gameState = "menu" -- menu, character_select, playing, gameover
    blinkTimer = 0
    blinkVisible = true
end


function loadSelectedCharacter()
    local char = characters[selectedCharacter]

    player.runSheet  = love.graphics.newImage(char.run)
    player.jumpSheet = love.graphics.newImage(char.jump)
    player.idleSheet = love.graphics.newImage(char.idle)
    player.deathSheet = love.graphics.newImage(char.deathSheet)

    player.runGrid  = anim8.newGrid(32, 32, player.runSheet:getWidth(),  player.runSheet:getHeight())
    player.jumpGrid = anim8.newGrid(32, 32, player.jumpSheet:getWidth(), player.jumpSheet:getHeight())
    player.idleGrid = anim8.newGrid(32, 32, player.idleSheet:getWidth(), player.idleSheet:getHeight())
    player.deathGrid = anim8.newGrid(32, 32, player.deathSheet:getWidth(), player.deathSheet:getHeight())

    player.runAnim  = anim8.newAnimation(player.runGrid('1-6', 1), 0.1)
    player.jumpAnim = anim8.newAnimation(player.jumpGrid('1-8', 1), 0.08)
    player.idleAnim = anim8.newAnimation(player.idleGrid('1-4', 1), 0.25)
    player.deathAnim = anim8.newAnimation(player.deathGrid('1-8', 1), 0.08)

    player.currentAnim = player.idleAnim
end


function love.update(dt)
    -- Blinking text for menu
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

    --Death animation logic
    if player.isDead then
        dt = dt * 0.4

        player.deathAnim:update(dt)
        player.deathTimer = player.deathTimer + dt

        --Screen shakes when player dies
        if player.deathTimer < 0.4 then
            camera.shake = 10 * (0.4 - player.deathTimer)
        else
            camera.shake = math.max(camera.shake - dt * 15, 0)
        end

        --Fade to black
        if player.deathTimer > 0.6 then
            player.fadeAlpha = math.min(player.fadeAlpha + dt * 0.8, 1)
        end

        --After death anim finishes
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
        player.currentAnim = isMoving and player.runAnim or player.idleAnim
    else
        player.onGround = false
        player.currentAnim = player.jumpAnim
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

    --Enemy respawn behind player if player gets too far
    if enemy.x < player.x - 800 then
        enemy.x = player.x - love.math.random(500, 800)
    end

    --Camera follows player always
    camera.x = player.x - love.graphics.getWidth() / 2
    if camera.x < 0 then camera.x = 0 end

    --Distance
    distance = math.floor(player.x / 10)

    -- Collision detection (only if alive)
    local playerScale = 3
    local enemyScale = 1.5
    if not player.isDead and
       checkCollision(player.x, player.y, player.width * playerScale, player.height * playerScale,
                      enemy.x, enemy.y, enemy.width * enemyScale, enemy.height * enemyScale) then
        player.isDead = true
        player.deathTimer = 0
        player.deathAnim:gotoFrame(1)
        player.fadeAlpha = 0
        camera.shake = 10 
    end

    --Update animations
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

    --Character Select Screen
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

            -- 🔹 Animated character preview (idle animation)
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

    --GAMEPLAY DRAW
    love.graphics.push()

    -- Screen shake effect
    local shakeX = math.random(-camera.shake, camera.shake)
    local shakeY = math.random(-camera.shake, camera.shake)
    love.graphics.translate(-camera.x + shakeX, shakeY)

    --Background goes on forever
    local bgWidth = background:getWidth()
    local startBg = math.floor(camera.x / bgWidth)
    local endBg = startBg + math.ceil(love.graphics.getWidth() / bgWidth) + 1
    for i = startBg, endBg do
        love.graphics.draw(background, i * bgWidth, 0)
    end

    --Graphics of the ground
    love.graphics.setColor(0.3, 0.8, 0.3)
    love.graphics.rectangle("fill", camera.x - 1000, groundY, love.graphics.getWidth() + 2000, 100)
    love.graphics.setColor(1, 1, 1)

    --Graphics of the player
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
        end
        if player.flip then
            player.currentAnim:draw(sheet, player.x + player.width * scale, player.y, 0, -scale, scale)
        else
            player.currentAnim:draw(sheet, player.x, player.y, 0, scale, scale)
        end
    end

    --Graphics of the gorgon
    local enemyScale = 1.5
    if enemy.flip then
        enemy.anim:draw(enemy.sheet, enemy.x + enemy.width * enemyScale, enemy.y, 0, -enemyScale, enemyScale)
    else
        enemy.anim:draw(enemy.sheet, enemy.x, enemy.y, 0, enemyScale, enemyScale)
    end

    love.graphics.pop()

    --Distance display
    if gameState == "playing" then
        love.graphics.setFont(font)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Distance: " .. distance .. " m", 20, 20)
    end

    --Death fade
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
        if key == "space" and player.onGround and not player.isDead then
            player.yVelocity = player.jumpForce
            player.onGround = false
            player.currentAnim = player.jumpAnim
            player.jumpAnim:gotoFrame(1)
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
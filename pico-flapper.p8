pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

--pico flapper
--by andrew phifer


player = {}
obstacles = {}
screen_height = 128
screen_width = 128
sprite_height = 8
sprite_width = 8
screen_sprite_width = screen_width / sprite_width
screen_sprite_height = screen_height / sprite_height
gravity = 0
game_over = false
pipe_spawn_counter_max = 0
pipe_spawn_counter = 0
difficulty = 5
high_score = 0


function make_player()
    player.x = 5
    player.y = screen_height / 2
    player.width = sprite_width
    player.height = sprite_height
    player.jump_speed = -3
    player.dy = 0
    player.alive = 1
    player.falling = 2
    player.dead = 3
    player.score = 0
    player.jump_cycle = {6,7,8,9,8,7,6}
    player.jump_effect = 0
    player.jump_max = 9
end



function reset_game()
    print("resetting")
    high_score = max(high_score, player.score)
    make_player()
    game_over = false
    pipe_spawn_counter = 0
    obstacles = {}
end


function _init()
    reset_game()
    gravity = 0.3
    pipe_spawn_counter_max = sprite_width * 1.5    
    menuitem(1, "reset game", reset_game())
end


function accept_player_input()
    if btnp(5) then
        player.dy = player.jump_speed
        player.jump_effect = 1
        sfx(0)
    end
end


function make_pipe(x, y, is_top, is_cap)
    local output = {}
    output.x = x
    output.y = y
    output.width = sprite_width
    output.height = sprite_height

    if is_cap then
        output.sprite = 5
    else
        output.sprite = 4
    end

    output.is_top = is_top
    return output
end


function make_obstacle_column(minGapSize)

    local x = screen_width + (sprite_width + 1)
    local upper_length = flr((rnd(screen_sprite_height) / 2) - (minGapSize / 2))
    local lower_length = flr((rnd(screen_sprite_height) / 2) - (minGapSize / 2))    

    for index = 0, upper_length do
        print(tostr(screen_sprite_height) .. " " .. tostr(upper_length) .. " " .. tostr(lower_length) .. " " .. tostr(index)) 
        local y = index * sprite_height
        local buffer = make_pipe(x, y, true, false)
        add(obstacles, buffer)
    end

    print(#obstacles)
    local buffer
    add(obstacles, make_pipe(x, (upper_length + 1) * sprite_height, true, true)) --add the pipe cap

    for index = 0, lower_length do
        print(tostr(screen_sprite_height) .. " " .. tostr(upper_length) .. " " .. tostr(lower_length) .. " " .. tostr(index)) 
        local y = screen_width - (index * sprite_height)
        local buffer = make_pipe(x, y, false, false)
        add(obstacles, buffer)
    end

    print(#obstacles)
    add(obstacles, make_pipe(x, screen_width - ((lower_length + 1) * sprite_height), false, true)) --add the pipe cap
end


function normal_game_tick()
    player.score += 1
    player.y += player.dy
    player.dy += gravity

    game_over = (player.y < 0) or (player.y > (screen_height - sprite_height))
end


function conditionally_reset_game()
    if btn(4) then
        reset_game()
    end
end



function update_obstacles()    
    for element in all(obstacles) do
        if (element.x > -sprite_width) and (element.x < (screen_width + (sprite_width * 2))) then
        element.x += -1
        else            
            del(obstacles, element)            
        end
    end
end


function point_in_bounding_box(input, box)
    local box_p1_x = box.x
    local box_p1_y = box.y
    local box_p2_x = box_p1_x + box.width
    local box_p2_y = box_p1_y + box.height

    local vertical_check = (input.x >= box_p1_x) and (input.x <= box_p2_x)
    local horizontal_check = (input.y >= box_p1_y) and (input.y <= box_p2_y)
    local output = vertical_check and horizontal_check
    return output
end


function collision_detection(mob)
    local mob_corner_1 = {}
    local mob_corner_2 = {}
    local mob_corner_3 = {}
    local mob_corner_4 = {}

    mob_corner_1.x = mob.x
    mob_corner_1.y = mob.y
    mob_corner_1.width = mob.width
    mob_corner_1.height = mob.height
    mob_corner_2.x = mob.x + mob.width
    mob_corner_2.y = mob.y
    mob_corner_2.width = mob.width
    mob_corner_2.height = mob.height
    mob_corner_3.x = mob.x
    mob_corner_3.y = mob.y + mob.height
    mob_corner_3.width = mob.width
    mob_corner_3.height = mob.height
    mob_corner_4.x = mob_corner_2.x
    mob_corner_4.y = mob_corner_3.y
    mob_corner_4.width = mob.width
    mob_corner_4.height = mob.height   
    local collision = false 

    for element in all(obstacles) do        
        local c1 = point_in_bounding_box(mob_corner_1, element)
        local c2 = point_in_bounding_box(mob_corner_2, element)
        local c3 = point_in_bounding_box(mob_corner_3, element)
        local c4 = point_in_bounding_box(mob_corner_4, element)
        collision = c1 or c2 or c3 or c4

        if collision then
            break
        end
    end

    return collision
end


function create_new_obstacles()
    pipe_spawn_counter += 1
    pipe_spawn_counter = pipe_spawn_counter % pipe_spawn_counter_max

    if pipe_spawn_counter == 0 then
        print("trigger")
        make_obstacle_column(difficulty)
    end
    
    
end


function _update()
    if not game_over then
        update_obstacles()
        accept_player_input()    
        normal_game_tick()
        game_over = game_over or collision_detection(player)
        create_new_obstacles()
    else
        conditionally_reset_game()
    end
end

function draw_pipe(input)    
    spr(input.sprite, input.x, input.y, 1, 1, false, input.is_top)
end


function _draw()
    cls()
    local sprite_number_to_draw = 0

    if player.dy > 0 then
        --player is falling
        sprite_number_to_draw = player.falling
    else
        --player is rising
        sprite_number_to_draw = player.alive
    end

    spr(sprite_number_to_draw, player.x, player.y)
    
    if player.jump_effect > 0 then
        spr(player.jump_cycle[player.jump_effect], player.x, player.y + sprite_height)
        player.jump_effect += 1
        player.jump_effect = player.jump_effect % #player.jump_cycle
    end

    foreach(obstacles, draw_pipe) --draw obstacles
    print("current score: " .. tostr(player.score))
    print("high score: " .. tostr(high_score))

    if game_over then
        --player game over sequence, then reset with init
        sprite_number_to_draw = player.dead
        print("game over", screen_width / 4, screen_height / 3, 8)
        print("press z to restart")
    end
    
    
end



__gfx__
0000000000aaaa0000aaaa000088880003b333303b33333307000700070007000000000000000000000000000000000000000000000000000000000000000000
000000000aaaaaa00aaaaaa00888888003b333303b33333307070700000707000007000000070000000000000000000000000000000000000000000000000000
00700700aa0aa0aaaa0aa0aa8898898803b333300000000007070000000700000007000000000000000000000000000000000000000000000000000000000000
00077000aaaaaaaaaaaaaaaa8888888803b3333003b3333000070000000700000007000000000000000000000000000000000000000000000000000000000000
00077000aa0000aaaaa00aaa8889988803b3333003b3333000070000000700000000000000000000000000000000000000000000000000000000000000000000
00700700aaa00aaaaaa00aaa8898898803b3333003b3333000070000000000000000000000000000000000000000000000000000000000000000000000000000
000000000aaaaaa00aaaaaa00888888003b3333003b3333000070000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aaaa0000aaaa000088880003b3333003b3333000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000000150021500415006150081500a1500c1500e15010150121501515017150191501b1501e1502100023000260002700000100001500215006150091500b1500e150101501315016150181501b1501e150

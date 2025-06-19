pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

player = {}
obstacles = {}
screen_height = 128
screen_width = 128
sprite_height = 16
sprite_width = 16
screen_sprite_width = screen_width / sprite_width
screen_sprite_height = screen_height / sprite_height
gravity = 0
game_over = false


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
end



function reset_game()
    print("resetting")
    make_player()
    game_over = false
end


function _init()
    reset_game()
    gravity = 0.3
    menuitem(1, "reset game", reset_game())
end


function accept_player_input()
    if btn(5) then
        player.dy = player.jump_speed
    end
end


function make_obstacle_column(x, minGapSize)
    local output = {}    
    local x = 0
    output.upper_length = sprite_height * rnd(screen_sprite_height)
    output.lower_length = screen_height - sprite_height * rnd(screen_sprite_height - minGapSize - output.upper_length)    
    output.is_off_screen = false
    output.entities = {}

    for x = 0, output.height do
        local buffer = {}
        buffer.x = x
        buffer.y = sprite_height * x
        if x-1 == output.height then
            buffer.buffer.sprite_version = 5
        else
            buffer.buffer.sprite_version = 4
        end

        output.entities[0] = buffer
    end

    return output
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
        if (element.x > 0) and (element.x < screen_width) then
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
    local box_p2_y = box_p2_y + box.height

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
    mob_corner_3.x = mob.y
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


function _update()
    if not game_over then
        update_obstacles()
        accept_player_input()    
        normal_game_tick()
        collision_detection()
    else
        conditionally_reset_game()
    end
end

function draw_pipe(input)
    spr(input.sprite, input.x, input.y, false, input.is_top)
end


function _draw()
    cls()
    sprite_number_to_draw = 0
    print("current score: " .. tostr(player.score))
    if game_over then
        --player game over sequence, then reset with init
        sprite_number_to_draw = player.dead
        print("game over", screen_width / 4, screen_height / 3, 8)
        print("press z to restart")
    elseif player.dy > 0 then
        --player is falling
        sprite_number_to_draw = player.falling
    else
        --player is rising
        sprite_number_to_draw = player.alive
    end

    foreach(obstacles, draw_pipe) --draw obstacles
    spr(sprite_number_to_draw, player.x, player.y)
end



__gfx__
0000000000aaaa0000aaaa000088880003b333303b33333300000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000aaaaaa00aaaaaa00888888003b333303b33333300000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700aa0aa0aaaa0aa0aa8898898803b333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000aaaaaaaaaaaaaaaa8888888803b3333003b3333000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000aa0000aaaaa00aaa8889988803b3333003b3333000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700aaa00aaaaaa00aaa8898898803b3333003b3333000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000aaaaaa00aaaaaa00888888003b3333003b3333000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aaaa0000aaaa000088880003b3333003b3333000000000000000000000000000000000000000000000000000000000000000000000000000000000

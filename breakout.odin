package breakout

// https://youtu.be/vfgZOEvO0kM?t=5864

// About better timestamps:"https://gafferongames.com/post/fix_your_timestep/"

import "core:fmt"
// import "core:strings"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import rl "vendor:raylib"

WIN_SIZE                :: 960
SCREEN_SIZE             :: 320
PADDLE_WIDTH            :: 50
PADDLE_HEIGHT           :: 8
PADDLE_POS_Y            :: 300
PADDLE_SPEED            :: 200
BALL_SPEED              :f32 = 200.0
BALL_INCREMENT_SPEED    :f32 = 0.5
BALL_RADIUS             :: 4
BALL_START_Y            :: 160
NUM_BLOCKS_X            :: 10
NUM_BLOCKS_Y            :: 8
BLOCK_WIDTH             :: 28
BLOCK_HEIGHT            :: 10

Block_Color :: enum {
    Yellow,
    Green,
    Orange,
    Red,
}

row_colors := [NUM_BLOCKS_Y]Block_Color {
    .Red,
    .Red,
    .Orange,
    .Orange,
    .Green,
    .Green,
    .Yellow,
    .Yellow
}

block_color_values := [Block_Color]rl.Color {
    .Red = { 255, 25, 25, 255 },
    .Orange = { 255, 163, 0, 255 },
    .Yellow = { 233, 233, 0, 255 },
    .Green = { 0, 210, 0, 255 },
}

block_color_score := [Block_Color]int {
    .Yellow = 2,
    .Green  = 4,
    .Orange = 6,
    .Red    = 8,
}


blocks                      : [NUM_BLOCKS_X][NUM_BLOCKS_Y]bool
paddle_pos_x                : f32
show_info                   : bool = false
ball_pos                    : rl.Vector2
ball_dir                    : rl.Vector2
// ball                        : BALL
started                     : bool
game_over                   : bool
score                       : int
accumulated_time            : f32
previous_ball_position      : rl.Vector2
previous_paddle_position_x  : f32
fallow_paddle               : bool = false
game_win                    : bool = false


// BALL :: struct {
//     radius: f32,
//     color: rl.Color
//     pos: rl.Vector2
// }

// make_ball :: proc(radius: f32, color: rl.Color) -> BALL {
//     new_ball := BALL {
//         radius = radius,
//         color  = color
//     }

//     return new_ball
// }

// draw_ball :: proc(ball: BALL) {
//     rl.DrawCircleV(ball_pos, BALL_RADIUS, {200, 90, 20, 255})
// }

loose :: proc () {
    FontSIZE :: 12
    TxtLine1 :: "YOU LOOSE!"
    T1Width := rl.MeasureText(TxtLine1, FontSIZE * 2)
    TxtLine2 := fmt.ctprintf("Final Score: %v. PRESS [SPACE] to restart", score)
    DynColorHUE := f32(rl.GetTime() * 200)
    T2Width := rl.MeasureText(TxtLine2, FontSIZE)
    rl.DrawText(TxtLine1, SCREEN_SIZE/2 - T1Width/2, BALL_START_Y - 30, FontSIZE * 2, rl.ColorFromHSV(DynColorHUE, 1.0, 1.0))
    rl.DrawText(TxtLine2, SCREEN_SIZE/2 - T2Width/2, BALL_START_Y, FontSIZE, rl.ColorFromHSV(DynColorHUE + 150, 1.0, 1.0))
    if rl.IsKeyPressed( .SPACE ) {
        restart()
    }
}

win :: proc () {
    FontSIZE :: 12
    TxtLine1 :: "YOU WIN!!!"
    T1Width := rl.MeasureText(TxtLine1, FontSIZE * 2)
    TxtLine2 := fmt.ctprintf("Final Score: %v. PRESS [SPACE] to restart", score)
    DynColorHUE := f32(rl.GetTime() * 200)
    T2Width := rl.MeasureText(TxtLine2, FontSIZE)
    rl.DrawText(TxtLine1, SCREEN_SIZE/2 - T1Width/2, BALL_START_Y - 30, FontSIZE * 2, rl.ColorFromHSV(DynColorHUE, 1.0, 1.0))
    rl.DrawText(TxtLine2, SCREEN_SIZE/2 - T2Width/2, BALL_START_Y, FontSIZE, rl.ColorFromHSV(DynColorHUE + 150, 1.0, 1.0))
    if rl.IsKeyPressed( .SPACE ) {
        restart()
    }
}

restart :: proc() {
    paddle_pos_x = SCREEN_SIZE / 2 - PADDLE_WIDTH / 2
    previous_paddle_position_x = paddle_pos_x
    ball_pos = { SCREEN_SIZE/2, BALL_START_Y }
    previous_ball_position = ball_pos
    started = false
    score = 0
    game_over = false
    BALL_SPEED = f32(200.0)
    BALL_INCREMENT_SPEED = f32(0.5)
    fallow_paddle = false
    game_win = false

    for x in 0..<NUM_BLOCKS_X {
        for y in 0..<NUM_BLOCKS_Y {
            blocks[x][y] = true
        }
    }

}

reflect :: proc(dir, normal: rl.Vector2) -> rl.Vector2 {
    new_dir := linalg.reflect(dir, linalg.normalize(normal))
    BALL_SPEED += BALL_INCREMENT_SPEED
    return linalg.normalize(new_dir)
}

calc_block_rect :: proc(x, y : int) -> rl.Rectangle {
    return {
        f32(20 + x * BLOCK_WIDTH),
        f32(40 + y * BLOCK_HEIGHT),
        BLOCK_WIDTH, // - 1,
        BLOCK_HEIGHT, // - 1
    }
}

block_exists :: proc(x, y: int) -> bool {
    if x < 0 || y < 0 || x >= NUM_BLOCKS_X || y >= NUM_BLOCKS_Y {
        return false
    }

    return blocks[x][y]
}

remaining_blocks :: proc() -> int {
    total_blocks_found : int = 0
    for x in 0..<NUM_BLOCKS_X {
        for y in 0..<NUM_BLOCKS_Y {
            if blocks[x][y] == true {
                total_blocks_found += 1
            }
        }
    }
    return total_blocks_found
}

main :: proc() {
    rl.SetConfigFlags({ .VSYNC_HINT })    
    rl.InitWindow(WIN_SIZE, WIN_SIZE, "Breakout!")
    // rl.SetWindowPosition(0, 35)
    rl.InitAudioDevice()
    rl.SetTargetFPS(500)
    rl.HideCursor()

    ball_texture := rl.LoadTexture("ball.png")
    paddle_texture := rl.LoadTexture("paddle.png")
    hit_block_sound := rl.LoadSound("hit_block_2.wav")
    hit_paddle_sound := rl.LoadSound("hit_paddle.wav")
    game_over_sound := rl.LoadSound("game_over.wav")
    game_win_sound := rl.LoadSound("game_win.wav")
    
    restart()

    // ball = make_ball(BALL_RADIUS, {56,56,89, 255})
    
    for !rl.WindowShouldClose() {
    DT:: 1.0 / 60.0 //16 ms or 0.016s
        paddle_move_velocity: f32
        /////////// Game play logic
        if !started {
            ball_pos = {
                SCREEN_SIZE/2 + f32(math.cos(rl.GetTime() * 2.0) * SCREEN_SIZE / 2.5 ),
                BALL_START_Y
            }

            previous_ball_position = ball_pos

            if rl.IsKeyPressed( .SPACE ) {
                paddle_middle := rl.Vector2 { paddle_pos_x + PADDLE_WIDTH / 2, PADDLE_POS_Y }
                ball_to_paddle := paddle_middle - ball_pos
                
                ball_dir = linalg.normalize0(ball_to_paddle) //{0, 1}
                started = true
            }
        } else {
           accumulated_time += rl.GetFrameTime()
        }

        
        for  accumulated_time >= DT {
            previous_ball_position = ball_pos //keep track of previous position
            previous_paddle_position_x = paddle_pos_x
            
            ball_pos += ball_dir * BALL_SPEED * DT

            if ball_pos.x + BALL_RADIUS > SCREEN_SIZE {
                ball_pos.x = SCREEN_SIZE - BALL_RADIUS
                ball_dir = reflect(ball_dir, rl.Vector2({-1, 0}))
            }
            
            if ball_pos.x - BALL_RADIUS < 0 {
                ball_pos.x = BALL_RADIUS
                ball_dir = reflect(ball_dir, rl.Vector2({1, 0}))
            }
            
            if ball_pos.y - BALL_RADIUS < 0 {
                ball_pos.y = BALL_RADIUS
                ball_dir = reflect(ball_dir, rl.Vector2({0, 1}))
            }
            

            if rl.IsKeyPressed( .F7 ) {
                show_info = !show_info
            }
        
            if rl.IsKeyPressed( .F5 ) {
                restart()
            } 
            
            if rl.IsKeyPressed(.F1) {
                fallow_paddle = !fallow_paddle
            }
        
            if rl.IsKeyDown(.LEFT) {
                paddle_move_velocity -= PADDLE_SPEED
            }
        
            if rl.IsKeyDown(.RIGHT) {
                paddle_move_velocity += PADDLE_SPEED
            }



            paddle_pos_x += paddle_move_velocity * DT
            
            // if use_mouse_x {
            //     paddle_pos_x = f32(rl.GetMouseX()) - PADDLE_WIDTH / 2
            //     // fmt.print(paddle_pos_x)
            // }
            
            paddle_pos_x = clamp(paddle_pos_x, 0, SCREEN_SIZE - PADDLE_WIDTH)

            //////////////////// SHEAT
            if fallow_paddle {
                paddle_pos_x = ball_pos.x - (PADDLE_WIDTH / 2)
            }

            paddle_rect := rl.Rectangle {
                paddle_pos_x, PADDLE_POS_Y, PADDLE_WIDTH, PADDLE_HEIGHT,
            }
            
            if rl.CheckCollisionCircleRec(ball_pos, BALL_RADIUS, paddle_rect) {
                collision_normal: rl.Vector2

                if previous_ball_position.y < paddle_rect.y + paddle_rect.height {
                    // response := (ball_pos.x * (paddle_rect.x + (paddle_rect.width / 2))) * -0.05
                    collision_normal += {0, -1}
                    ball_pos.y = paddle_rect.y - BALL_RADIUS
                }

                // If ball hits "laterally" under middle of paddle, 
                // it goes down and you loose
                if previous_ball_position.y > paddle_rect.y + paddle_rect.height {
                    collision_normal += {0, 1}
                    ball_pos.y = paddle_rect.y + paddle_rect.height + BALL_RADIUS
                }

                if previous_ball_position.x < paddle_rect.x {
                    collision_normal += {-1, 0}
                }

                if previous_ball_position.x > paddle_rect.x + paddle_rect.width {
                    collision_normal += {1, 0}
                }

                if collision_normal != 0 {
                    ball_dir = reflect(ball_dir, linalg.normalize(collision_normal))
                }
                rl.PlaySound(hit_paddle_sound)
            }

            block_x_loop: for x in 0..< NUM_BLOCKS_X {
                for y in 0..< NUM_BLOCKS_Y {
                    if blocks[x][y] == false {
                        continue
                    }

                    block_rect := calc_block_rect(x, y)

                    if rl.CheckCollisionCircleRec(ball_pos, BALL_RADIUS, block_rect) {
                        collision_normal: rl.Vector2

                        // Hit block from above
                        if previous_ball_position.y < block_rect.y {
                            collision_normal += {0, -1}
                        }

                        // Hit block from under
                        if previous_ball_position.y > block_rect.y + block_rect.height {
                            collision_normal += {0, 1}
                        }

                        // Hit block from left
                        if previous_ball_position.x < block_rect.x {
                            collision_normal += {-1, 0}
                        }

                        //Hit block from right
                        if previous_ball_position.x > block_rect.x + block_rect.width {
                            collision_normal += {1, 0}
                        }

                        // Check for neibghor block, if yes, cancell collision normal
                        if block_exists(x + int(collision_normal.x), y) {
                            collision_normal.x = 0
                        }

                        // Check for neibghor block, if yes, cancell collision normal
                        if block_exists(x, y + int(collision_normal.y) ) {
                            collision_normal.y = 0
                        }

                        //Check if there is a collision
                        if collision_normal != 0 {
                            ball_dir = reflect(ball_dir, collision_normal)
                        }

                        blocks[x][y] = false
                        row_color := row_colors[y]
                        score += block_color_score[row_color]
                        rl.SetSoundPitch(hit_block_sound, rand.float32_range(0.8, 1.35))
                        rl.PlaySound(hit_block_sound)
                        break block_x_loop
                    }

                }
            }

            accumulated_time -= DT

        }

        blend := accumulated_time / DT
        ball_render_pos := math.lerp(previous_ball_position, ball_pos, blend)
        paddle_render_pos_x := math.lerp(previous_paddle_position_x, paddle_pos_x, blend)

        /////////// Game draw functions
        rl.BeginDrawing()
        // rl.ClearBackground({0, 87, 165, 255})
        rl.ClearBackground(rl.GetColor(0x9fb4c1ff))

        camera := rl.Camera2D({
            zoom = f32(rl.GetScreenHeight()/SCREEN_SIZE)
        })
        
        rl.BeginMode2D(camera)

        if show_info {
            rl.DrawFPS(10, 10)
            DT_Text := fmt.ctprintf("dt: %.5f", DT)
            rl.DrawText(DT_Text, 10, 30, 20, {24, 24, 42, 255})
        }


        // rl.DrawRectangleRec(paddle_rect, {50, 150, 90, 255})
        rl.DrawTextureV(paddle_texture, {paddle_render_pos_x, PADDLE_POS_Y}, rl.WHITE)
        // rl.DrawCircleV(ball_pos, BALL_RADIUS, {200, 90, 20, 255})
        rl.DrawTextureV(ball_texture, ball_render_pos - {BALL_RADIUS, BALL_RADIUS}, rl.WHITE)
        // draw_ball(ball)
        PAD :: 10

        for x in 0..<NUM_BLOCKS_X {
            for y in 0..<NUM_BLOCKS_Y {
                if blocks[x][y] == false {
                    continue
                }

                block_rect := calc_block_rect(x, y)

                top_left := rl.Vector2 {
                    block_rect.x, block_rect.y
                }

                top_right := rl.Vector2 {
                    block_rect.x + block_rect.width, block_rect.y
                }

                bottom_left := rl.Vector2 {
                    block_rect.x, block_rect.y + block_rect.height
                }

                bottom_right := rl.Vector2 {
                    block_rect.x + block_rect.width, block_rect.y + block_rect.height
                }

                // rl.DrawRectangleRec(block_rect, {u8(45 + y * 3), 45, u8(45 + x * 3), 255})
                rl.DrawRectangleRec(block_rect, block_color_values[row_colors[y]])
                
                lineThickness : f32 = 0.50
                // borderColor : rl.Color = rl.ColorFromHSV(f32(rl.GetTime() * 50), 1.0, 1.0) //rl.GetColor(0x3d0090ff)
                rl.DrawLineEx(top_left, top_right, lineThickness, rl.WHITE)
                rl.DrawLineEx(top_left, bottom_left, lineThickness, rl.WHITE)
                rl.DrawLineEx(bottom_left, bottom_right, lineThickness, rl.GRAY)
                rl.DrawLineEx(top_right, bottom_right, lineThickness, rl.GRAY)

            }
        }

        if ball_pos.y - BALL_RADIUS > SCREEN_SIZE + BALL_RADIUS * 2 {
            if !game_over {
                game_over = true
                rl.PlaySound(game_over_sound)
            }
            loose()
        }

        if remaining_blocks() <= 0 {
            if !game_win {
                game_win = true
                fallow_paddle = true
                BALL_INCREMENT_SPEED = 0.0
                rl.PlaySound(game_win_sound)
            }
            win()
        }
        
        score_text := fmt.ctprintf("%d", score)
        rl.DrawText(score_text, 5, 5, 10, rl.WHITE)

        rl.EndMode2D()
        rl.EndDrawing()

        free_all(context.temp_allocator)
    }

    rl.ShowCursor()
    rl.CloseAudioDevice()
    rl.CloseWindow()
}
package breakout

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

render :: proc(gs: ^Game_State) {
    /////////// Game draw functions
    rl.BeginDrawing()
    // rl.ClearBackground({0, 87, 165, 255})
    // rl.ClearBackground(rl.GetColor(0x9fb4c1ff))
    rl.ClearBackground(rl.RAYWHITE)
    rl.DrawRectangleGradientV(0, 0, WIN_SIZE, WIN_SIZE, rl.GetColor(0x9fb4c1ff), rl.GetColor(0x9fb4c1aa))

    camera := rl.Camera2D({
        zoom = f32(rl.GetScreenHeight()/SCREEN_SIZE)
    })
    
    rl.BeginMode2D(camera)

    if gs.show_info {
        rl.DrawFPS(10, 10)
        DT_Text := fmt.ctprintf("dt: %.5f", gs.DT)
        rl.DrawText(DT_Text, 10, 30, 20, {24, 24, 42, 255})
    }

    blend := gs.accumulated_time / gs.DT
    gs.ball_render_pos = math.lerp(gs.previous_ball_position, gs.ball_pos, blend)
    gs.paddle_render_pos_x = math.lerp(gs.previous_paddle_position_x, gs.paddle_pos_x, blend)


    // rl.DrawRectangleRec(paddle_rect, {50, 150, 90, 255})
    rl.DrawTextureV(gs.resources.paddle_texture, {gs.paddle_render_pos_x, PADDLE_POS_Y}, rl.WHITE)
    // rl.DrawCircleV(ball_pos, BALL_RADIUS, {200, 90, 20, 255})
    rl.DrawTextureV(gs.resources.ball_texture, gs.ball_render_pos - {BALL_RADIUS, BALL_RADIUS}, rl.WHITE)
    // draw_ball(ball)
    PAD :: 10

    for x in 0..<NUM_BLOCKS_X {
        for y in 0..<NUM_BLOCKS_Y {
            if gs.blocks[x][y] == false {
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
            rl.DrawLineEx(top_left, top_right, lineThickness, rl.ColorAlpha(rl.WHITE, 1.0))
            rl.DrawLineEx(top_left, bottom_left, lineThickness, rl.ColorAlpha(rl.WHITE, 1.0))
            lineThickness = 0.9
            rl.DrawLineEx(bottom_left, bottom_right, lineThickness, rl.ColorAlpha(rl.GRAY, 0.85))
            rl.DrawLineEx(top_right, bottom_right, lineThickness, rl.ColorAlpha(rl.GRAY, 0.85))

        }
    }
}
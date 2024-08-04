package breakout

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

render :: proc(gs: ^Game_State) {
    /////////// Game draw functions
    CBG1 :: 0x4284adff //0x8fc4d1ff
    CBG2 :: 0x213b4cff //0x9fb4c133
    rl.BeginDrawing()

    rl.ClearBackground(rl.RAYWHITE)
    rl.DrawRectangleGradientV(0, 0, WIN_SIZE, WIN_SIZE, rl.GetColor(CBG1), rl.GetColor(CBG2))

    camera := rl.Camera2D({
        zoom = f32(rl.GetScreenHeight()/SCREEN_SIZE)
    })
    
    rl.BeginMode2D(camera)

    if gs.show_info {
        rl.DrawFPS(110, 8)
        // DT_Text := fmt.ctprintf("dt: %.5f", gs.DT)
        // rl.DrawText(DT_Text, 10, 30, 20, {24, 24, 42, 255})
    }

    blend := gs.accumulated_time / gs.DT
    gs.ball_render_pos = math.lerp(gs.previous_ball_position, gs.ball_pos, blend)
    gs.paddle_render_pos_x = math.lerp(gs.previous_paddle_position_x, gs.paddle_pos_x, blend)

    rl.DrawTextureV(gs.resources.paddle_texture, {gs.paddle_render_pos_x, PADDLE_POS_Y}, rl.WHITE)
    rl.DrawTextureV(gs.resources.ball_texture, gs.ball_render_pos - {BALL_RADIUS, BALL_RADIUS}, rl.WHITE)

    PAD :: 1

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

            rl.DrawTextureV(gs.resources.block_texture[row_colors[y]], {block_rect.x, block_rect.y}, rl.WHITE)

        }
    }

    check_game_status(gs)

    draw_score(gs)

    draw_particles(gs)


    rl.EndMode2D()
    rl.EndDrawing()

    if gs.can_play_music {
        rl.UpdateMusicStream(gs.resources.music_1)
    }

}
package breakout

import "core:fmt"
import "core:strings"
import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

check_game_status :: proc(gs: ^Game_State) {
    if gs.ball_pos.y - BALL_RADIUS > SCREEN_SIZE + BALL_RADIUS * 2 {
        if !gs.game_over {
            gs.game_over = true
            rl.PlaySound(gs.resources.game_over_sound)
        }
        loose(gs)
    }

    if remaining_blocks(gs) <= 0 {
        if !gs.game_win {
            gs.game_win = true
            gs.fallow_paddle = true
            BALL_INCREMENT_SPEED = 0.0
            rl.PlaySound(gs.resources.game_win_sound)
        }
        win(gs)
    }
}

init_game :: proc(gs: ^Game_State) {
    rl.SetConfigFlags({ .VSYNC_HINT }) 
    // rl.SetTraceLogLevel( .ERROR )
    rl.InitWindow(WIN_SIZE, WIN_SIZE, "Breakout!")
    // rl.SetWindowPosition(0, 35)
    rl.InitAudioDevice()
    rl.SetTargetFPS(500)
    rl.HideCursor()

    gs.resources.ball_texture = rl.LoadTexture(strings.clone_to_cstring(strings.concatenate({RSC_FOLDER, "ball.png"})))
    gs.resources.paddle_texture = rl.LoadTexture(strings.clone_to_cstring(strings.concatenate({RSC_FOLDER, "new_paddle.png"})))
    gs.resources.hit_block_sound = rl.LoadSound(strings.clone_to_cstring(strings.concatenate({RSC_FOLDER, "hit_block_2.wav"})))
    gs.resources.hit_paddle_sound = rl.LoadSound(strings.clone_to_cstring(strings.concatenate({RSC_FOLDER, "hit_paddle_2.wav"})))
    gs.resources.game_over_sound = rl.LoadSound(strings.clone_to_cstring(strings.concatenate({RSC_FOLDER, "game_over.wav"})))
    gs.resources.game_win_sound = rl.LoadSound(strings.clone_to_cstring(strings.concatenate({RSC_FOLDER, "game_win.wav"})))
   
    gs.resources.block_texture[.Red] = rl.LoadTexture(strings.clone_to_cstring(strings.concatenate({RSC_FOLDER, block_color_textures[.Red]})))
    gs.resources.block_texture[.Orange] = rl.LoadTexture(strings.clone_to_cstring(strings.concatenate({RSC_FOLDER, block_color_textures[.Orange]})))
    gs.resources.block_texture[.Yellow] = rl.LoadTexture(strings.clone_to_cstring(strings.concatenate({RSC_FOLDER, block_color_textures[.Yellow]})))
    gs.resources.block_texture[.Green] = rl.LoadTexture(strings.clone_to_cstring(strings.concatenate({RSC_FOLDER, block_color_textures[.Green]})))
    gs.resources.block_texture[.Purple] = rl.LoadTexture(strings.clone_to_cstring(strings.concatenate({RSC_FOLDER, block_color_textures[.Purple]})))

}

loose :: proc (gs: ^Game_State) {
    FontSIZE :: 12
    TxtLine1 :: "YOU LOOSE!"
    T1Width := rl.MeasureText(TxtLine1, FontSIZE * 2)
    TxtLine2 := fmt.ctprintf("Final Score: %v. PRESS [SPACE] to restart", gs.score)
    DynColorHUE := f32(rl.GetTime() * 200)
    T2Width := rl.MeasureText(TxtLine2, FontSIZE)
    rl.DrawText(TxtLine1, SCREEN_SIZE/2 - T1Width/2, BALL_START_Y, FontSIZE * 2, rl.ColorFromHSV(DynColorHUE, 1.0, 1.0))
    rl.DrawText(TxtLine2, SCREEN_SIZE/2 - T2Width/2, BALL_START_Y + 30, FontSIZE, rl.ColorFromHSV(DynColorHUE + 150, 1.0, 1.0))
    if rl.IsKeyPressed( .SPACE ) {
        restart(gs)
    }
}

win :: proc (gs: ^Game_State) {
    FontSIZE :: 12
    TxtLine1 :: "YOU WIN!!!"
    T1Width := rl.MeasureText(TxtLine1, FontSIZE * 3)
    TxtLine2 := fmt.ctprintf("Final Score: %v. PRESS [SPACE] to restart", gs.score)
    T2Width := rl.MeasureText(TxtLine2, FontSIZE)
    DynColorHUE := f32(rl.GetTime() * 200)
    Text_y := i32(BALL_START_Y * math.cos(rl.GetTime()) * 0.10) + 65
    rl.DrawText(TxtLine1, SCREEN_SIZE/2 - T1Width/2, Text_y, FontSIZE * 3, rl.ColorFromHSV(DynColorHUE, 1.0, 1.0))
    rl.DrawText(TxtLine2, SCREEN_SIZE/2 - T2Width/2, BALL_START_Y, FontSIZE, rl.ColorFromHSV(DynColorHUE + 150, 1.0, 1.0))
    if rl.IsKeyPressed( .SPACE ) {
        restart(gs)
    }
}

restart :: proc(gs: ^Game_State) {
    gs.paddle_pos_x = SCREEN_SIZE / 2 - PADDLE_WIDTH / 2
    gs.previous_paddle_position_x = gs.paddle_pos_x
    gs.ball_pos = { SCREEN_SIZE/2, BALL_START_Y }
    gs.previous_ball_position = gs.ball_pos
    gs.started = false
    gs.score = 0
    gs.game_over = false
    BALL_SPEED = f32(200.0)
    BALL_INCREMENT_SPEED = f32(0.5)
    gs.fallow_paddle = false
    gs.game_win = false

    for x in 0..<NUM_BLOCKS_X {
        for y in 0..<NUM_BLOCKS_Y {
            gs.blocks[x][y] = true
        }
    }

}
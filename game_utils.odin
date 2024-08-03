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
            gs.can_play_music = false
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
    
    context.allocator = context.temp_allocator

    when ODIN_DEBUG {
        rl.SetTraceLogLevel( .ALL )
    } else {
        rl.SetTraceLogLevel( .WARNING )
    }
    rl.SetConfigFlags({ .VSYNC_HINT }) 
    rl.InitWindow(WIN_SIZE, WIN_SIZE, "ODIN Breakout!")
    rl.InitAudioDevice()
    rl.SetTargetFPS(60)
    rl.HideCursor() 

    gs.resources.hit_block_sound        = rl.LoadSound(strings.clone_to_cstring(strings.concatenate({RSC_FOLDER, "hit_block_2.wav"})))
    gs.resources.hit_paddle_sound       = rl.LoadSound(strings.clone_to_cstring(strings.concatenate({RSC_FOLDER, "hit_paddle_2.wav"})))
    gs.resources.game_over_sound        = rl.LoadSound(strings.clone_to_cstring(strings.concatenate({RSC_FOLDER, "game_over.wav"})))
    gs.resources.game_win_sound         = rl.LoadSound(strings.clone_to_cstring(strings.concatenate({RSC_FOLDER, "game_win.wav"})))
    gs.resources.glass_break_1          = rl.LoadSound(strings.clone_to_cstring(strings.concatenate({RSC_FOLDER, "glass_1.wav"})))
    gs.resources.glass_break_2          = rl.LoadSound(strings.clone_to_cstring(strings.concatenate({RSC_FOLDER, "glass_2.wav"})))
    gs.resources.glass_break_3          = rl.LoadSound(strings.clone_to_cstring(strings.concatenate({RSC_FOLDER, "glass_3.wav"})))

    gs.resources.music_1                = rl.LoadMusicStream(strings.clone_to_cstring(strings.concatenate({RSC_FOLDER, "music_1.wav"})))
    
    gs.resources.ball_texture           = rl.LoadTexture(strings.clone_to_cstring(strings.concatenate({RSC_FOLDER, "ball.png"})))
    gs.resources.paddle_texture         = rl.LoadTexture(strings.clone_to_cstring(strings.concatenate({RSC_FOLDER, "new_paddle.png"})))
    gs.resources.block_texture[.Red]    = rl.LoadTexture(strings.clone_to_cstring(strings.concatenate({RSC_FOLDER, block_color_textures[.Red]})))
    gs.resources.block_texture[.Orange] = rl.LoadTexture(strings.clone_to_cstring(strings.concatenate({RSC_FOLDER, block_color_textures[.Orange]})))
    gs.resources.block_texture[.Yellow] = rl.LoadTexture(strings.clone_to_cstring(strings.concatenate({RSC_FOLDER, block_color_textures[.Yellow]})))
    gs.resources.block_texture[.Green]  = rl.LoadTexture(strings.clone_to_cstring(strings.concatenate({RSC_FOLDER, block_color_textures[.Green]})))
    gs.resources.block_texture[.Purple] = rl.LoadTexture(strings.clone_to_cstring(strings.concatenate({RSC_FOLDER, block_color_textures[.Purple]})))


    gs.resources.window_icon            = rl.LoadImage(strings.clone_to_cstring(strings.concatenate({RSC_FOLDER, "app-icon.png"})))
    rl.SetWindowIcon(gs.resources.window_icon)

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

    gs.resources.music_volume -= 0.0025
    if gs.resources.music_volume <= 0.0 {
        gs.resources.music_volume = 0
        rl.StopMusicStream(gs.resources.music_1)
        gs.can_play_music = false
    } else {
        rl.SetMusicVolume(gs.resources.music_1, gs.resources.music_volume)
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
    BALL_SPEED = f32(BALL_SPEED_INIT)
    BALL_INCREMENT_SPEED = f32(0.5)
    gs.fallow_paddle = false
    gs.game_win = false
    gs.last_block_score = 0
    gs.resources.music_volume = MUSIC_VOLUME_INIT

    for x in 0..<NUM_BLOCKS_X {
        for y in 0..<NUM_BLOCKS_Y {
            gs.blocks[x][y] = true
        }
    }


}

unload_resources :: proc(gs: ^Game_State) {
    rl.UnloadSound(gs.resources.hit_block_sound)
    rl.UnloadSound(gs.resources.hit_paddle_sound)
    rl.UnloadSound(gs.resources.game_over_sound)
    rl.UnloadSound(gs.resources.game_win_sound)
    rl.UnloadSound(gs.resources.glass_break_1)
    rl.UnloadSound(gs.resources.glass_break_2)
    rl.UnloadSound(gs.resources.glass_break_3)

    rl.UnloadTexture(gs.resources.ball_texture)
    rl.UnloadTexture(gs.resources.paddle_texture)
    rl.UnloadTexture(gs.resources.block_texture[.Red])
    rl.UnloadTexture(gs.resources.block_texture[.Orange])
    rl.UnloadTexture(gs.resources.block_texture[.Yellow])
    rl.UnloadTexture(gs.resources.block_texture[.Green])
    rl.UnloadTexture(gs.resources.block_texture[.Purple])

    rl.StopMusicStream(gs.resources.music_1)
    rl.UnloadMusicStream(gs.resources.music_1)
    
    rl.UnloadImage(gs.resources.window_icon)


}
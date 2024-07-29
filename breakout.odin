package breakout

// https://youtu.be/vfgZOEvO0kM?t=5864

// About better timestamps:"https://gafferongames.com/post/fix_your_timestep/"

import "core:fmt"

import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"


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

Game_Resources :: struct {
    ball_texture                : rl.Texture2D,
    paddle_texture              : rl.Texture2D,
    hit_block_sound             : rl.Sound,
    hit_paddle_sound            : rl.Sound,
    game_over_sound             : rl.Sound,
    game_win_sound              : rl.Sound,
}

Game_State :: struct {
    blocks                      : [NUM_BLOCKS_X][NUM_BLOCKS_Y]bool,
    paddle_pos_x                : f32,
    show_info                   : bool, // = false,
    ball_pos                    : rl.Vector2,
    ball_dir                    : rl.Vector2,
    started                     : bool,
    game_over                   : bool,
    score                       : int,
    accumulated_time            : f32,
    previous_ball_position      : rl.Vector2,
    previous_paddle_position_x  : f32,
    fallow_paddle               : bool, // = false,
    game_win                    : bool, // = false,
    ball_render_pos             : rl.Vector2,
    paddle_render_pos_x         : f32,
    DT                          : f32,
    resources                   : Game_Resources,
}

make_game_state :: proc() -> Game_State {
    new_game_state := Game_State {}
    new_game_state.show_info = false
    new_game_state.fallow_paddle = false
    new_game_state.game_win = false
    new_game_state.DT = 1.0 / 60.0 //16 ms or 0.016s

    return new_game_state
}


main :: proc() {

    game_state := make_game_state()

    init_game(&game_state)
    restart(&game_state)

    // ball = make_ball(BALL_RADIUS, {56,56,89, 255})
    
    for !rl.WindowShouldClose() {

        update(&game_state)

        render(&game_state)

        free_all(context.temp_allocator)
    }

    rl.ShowCursor()
    rl.CloseAudioDevice()
    rl.CloseWindow()
}
package breakout

// https://youtu.be/vfgZOEvO0kM?t=5864

// About better timestamps:"https://gafferongames.com/post/fix_your_timestep/"

import rl "vendor:raylib"

main :: proc() {

    game_state := make_game_state()

    init_game(&game_state)
    restart(&game_state)

    // ball = make_ball(BALL_RADIUS, {56,56,89, 255})
    
    for !rl.WindowShouldClose() {

        update(&game_state)

        render(&game_state)

        //free_all(context.temp_allocator)
    }

    rl.ShowCursor()
    rl.CloseAudioDevice()
    rl.CloseWindow()
}
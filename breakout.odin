package breakout

// From https://youtu.be/vfgZOEvO0kM

// About better timestamps:"https://gafferongames.com/post/fix_your_timestep/"

import "core:mem"
import "core:fmt"
import rl "vendor:raylib"

_main :: proc() {

    game_state := make_game_state()

    init_game(&game_state)
    restart(&game_state)
    
    for !rl.WindowShouldClose() {

        update(&game_state)

        render(&game_state)

    }

    rl.ShowCursor()
    rl.CloseAudioDevice()
    rl.CloseWindow()
    unload_resources(&game_state)

}

main :: proc() {

    when ODIN_DEBUG {

        track: mem.Tracking_Allocator
        mem.tracking_allocator_init(&track, context.allocator)
        defer mem.tracking_allocator_destroy(&track)
        context.allocator = mem.tracking_allocator(&track)

        _main()

        fmt.println(">>> MEMORY LEAK REPORT")
        leak_total_size : int

        for _, leak in track.allocation_map {
            fmt.printf("%v leaked %m\n", leak.location, leak.size)
            leak_total_size += leak.size
        }

        for bad_free in track.bad_free_array {
            fmt.printf("%v allocation %p was freed badly\n", bad_free.location, bad_free.memory)
        }

        if leak_total_size == 0 {
            fmt.println(">>> NO LEAKS FOUND")
        }

        fmt.println(">>> END MEMORY LEAK REPORT")


} else {
    _main()
}

}
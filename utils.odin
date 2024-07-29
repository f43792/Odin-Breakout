package breakout

import "core:fmt"
import "core:math/linalg"
import rl "vendor:raylib"

draw_score :: proc(gs: ^Game_State) {
    score_text := fmt.ctprintf("%d", gs.score)
    rl.DrawText(score_text, 6, 6, 20, rl.GRAY)
    rl.DrawText(score_text, 5, 5, 20, rl.WHITE)
}

remaining_blocks :: proc(gs: ^Game_State) -> int {
    total_blocks_found : int = 0
    for x in 0..<NUM_BLOCKS_X {
        for y in 0..<NUM_BLOCKS_Y {
            if gs.blocks[x][y] == true {
                total_blocks_found += 1
            }
        }
    }
    return total_blocks_found
}

block_exists :: proc(gs: ^Game_State, x, y: int) -> bool {
    if x < 0 || y < 0 || x >= NUM_BLOCKS_X || y >= NUM_BLOCKS_Y {
        return false
    }

    return gs.blocks[x][y]
}

reflect :: proc(dir, normal: rl.Vector2) -> rl.Vector2 {
    new_dir := linalg.reflect(dir, linalg.normalize(normal))
    BALL_SPEED += BALL_INCREMENT_SPEED
    return linalg.normalize(new_dir)
}

calc_block_rect :: proc(x, y : int) -> rl.Rectangle {
    PAD :: 1
    X := (SCREEN_SIZE / 2) - ((NUM_BLOCKS_X * (BLOCK_WIDTH + PAD)) / 2)
    return {
        f32(X + x * (BLOCK_WIDTH + PAD)),
        f32(35 + y * (BLOCK_HEIGHT + PAD)),
        BLOCK_WIDTH - PAD, // - 1,
        BLOCK_HEIGHT - PAD, // - 1
    }
}
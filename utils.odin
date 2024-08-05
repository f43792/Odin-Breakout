package breakout

import "core:fmt"
import "core:math/linalg"
import "core:math/rand"
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
            if gs.blocks[x][y].active == true {
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

    return gs.blocks[x][y].active
}

reflect :: proc(dir, normal: rl.Vector2, inc_ball_speed: bool = true) -> rl.Vector2 {
    new_dir := linalg.reflect(dir, linalg.normalize(normal))
    if inc_ball_speed {
        BALL_SPEED += BALL_INCREMENT_SPEED
    }
    return linalg.normalize(new_dir)
}

calc_dest_block_rect :: proc(x, y : int) -> rl.Rectangle {
    X := (SCREEN_SIZE / 2) - ((NUM_BLOCKS_X * (BLOCK_WIDTH + BLOCK_PAD)) / 2)
    return {
        f32(X + x * (BLOCK_WIDTH + BLOCK_PAD)),
        f32(Y_BLOCK_START + y * (BLOCK_HEIGHT + BLOCK_PAD)),
        BLOCK_WIDTH - BLOCK_PAD, // - 1,
        BLOCK_HEIGHT - BLOCK_PAD, // - 1
    }
}

calc_source_block_rect :: proc(block_color: Block_Color, block_variant: int) -> rl.Rectangle {
    res := rl.Rectangle{0, 0, 0, 0}
    res.x = f32(block_variant) * (BLOCK_WIDTH + BLOCK_PAD)

    total_block_colors := len(Block_Color)
    //f32( int(block_color) - total_block_colors) * (BLOCK_HEIGHT + BLOCK_PAD)
    res.y = f32(total_block_colors * (BLOCK_PAD + BLOCK_HEIGHT)) - f32(((int(block_color) + 1) * (BLOCK_PAD + BLOCK_HEIGHT)))

    res.width = BLOCK_WIDTH
    res.height = BLOCK_HEIGHT

    return res
}

choose_variations :: proc() -> int {
    res  : int
    pick : f32
    // percents : [_]f32 = {0.0, 0.84, 0.88, 0.92, 0.96, 1.00}
    
    // res = rand.int_max(BLOCK_VARIATIONS)
    pick = rand.float32()

    if pick <= 0.96 {
        res = 0
    } else {
        res = rand.int_max(4) + 1
    }


    return res
}
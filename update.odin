package breakout

import "core:math"
import "core:math/linalg"
import "core:math/rand"
import rl "vendor:raylib"

update :: proc(gs: ^Game_State) {
    paddle_move_velocity: f32
    /////////// Game play logic
    if !gs.started {
        gs.ball_pos = {
            SCREEN_SIZE/2 + f32(math.cos(rl.GetTime() * 2.0) * SCREEN_SIZE / 2.5 ),
            BALL_START_Y
        }

        gs.previous_ball_position = gs.ball_pos

        if rl.IsKeyPressed( .SPACE ) {
            paddle_middle := rl.Vector2 { gs.paddle_pos_x + PADDLE_WIDTH / 2, PADDLE_POS_Y }
            ball_to_paddle := paddle_middle - gs.ball_pos
            
            gs.ball_dir = linalg.normalize0(ball_to_paddle) //{0, 1}
            gs.started = true
        }
    } else {
        gs.accumulated_time += rl.GetFrameTime()
    }

    
    for  gs.accumulated_time >= gs.DT {
        gs.previous_ball_position = gs.ball_pos //keep track of previous position
        gs.previous_paddle_position_x = gs.paddle_pos_x
        
        gs.ball_pos += gs.ball_dir * BALL_SPEED * gs.DT

        if gs.ball_pos.x + BALL_RADIUS > SCREEN_SIZE {
            gs.ball_pos.x = SCREEN_SIZE - BALL_RADIUS
            gs.ball_dir = reflect(gs.ball_dir, rl.Vector2({-1, 0}))
        }
        
        if gs.ball_pos.x - BALL_RADIUS < 0 {
            gs.ball_pos.x = BALL_RADIUS
            gs.ball_dir = reflect(gs.ball_dir, rl.Vector2({1, 0}))
        }
        
        if gs.ball_pos.y - BALL_RADIUS < 0 {
            gs.ball_pos.y = BALL_RADIUS
            gs.ball_dir = reflect(gs.ball_dir, rl.Vector2({0, 1}))
        }
        

        if rl.IsKeyPressed( .F7 ) {
            gs.show_info = !gs.show_info
        }
    
        if rl.IsKeyPressed( .F5 ) {
            restart(gs)
        } 
        
        if rl.IsKeyPressed(.F) {
            gs.fallow_paddle = !gs.fallow_paddle
        }
    
        if rl.IsKeyDown(.LEFT) {
            paddle_move_velocity -= PADDLE_SPEED
        }
    
        if rl.IsKeyDown(.RIGHT) {
            paddle_move_velocity += PADDLE_SPEED
        }

        if rl.IsKeyPressed( .KP_ADD ) {
            BALL_SPEED += 25.0
        }

        if rl.IsKeyPressed( .KP_SUBTRACT ) {
            BALL_SPEED -= 25.0
        }

        if rl.IsKeyPressed( .KP_0 ) {
            BALL_SPEED = 200.0
        }



        gs.paddle_pos_x += paddle_move_velocity * gs.DT
        
        // if use_mouse_x {
        //     paddle_pos_x = f32(rl.GetMouseX()) - PADDLE_WIDTH / 2
        //     // fmt.print(paddle_pos_x)
        // }
        
        gs.paddle_pos_x = clamp(gs.paddle_pos_x, 0, SCREEN_SIZE - PADDLE_WIDTH)

        //////////////////// SHEAT
        if gs.fallow_paddle {
            gs.paddle_pos_x = gs.ball_pos.x - (PADDLE_WIDTH / 2)
        }

        paddle_rect := rl.Rectangle {
            gs.paddle_pos_x, PADDLE_POS_Y, PADDLE_WIDTH, PADDLE_HEIGHT,
        }
        
        if rl.CheckCollisionCircleRec(gs.ball_pos, BALL_RADIUS, paddle_rect) {
            collision_normal: rl.Vector2

            if gs.previous_ball_position.y < paddle_rect.y + paddle_rect.height {
                // response := (ball_pos.x * (paddle_rect.x + (paddle_rect.width / 2))) * -0.05
                collision_normal += {0, -1}
                gs.ball_pos.y = paddle_rect.y - BALL_RADIUS
            }

            // If ball hits "laterally" under middle of paddle, 
            // it goes down and you loose
            if gs.previous_ball_position.y > paddle_rect.y + paddle_rect.height {
                collision_normal += {0, 1}
                gs.ball_pos.y = paddle_rect.y + paddle_rect.height + BALL_RADIUS
            }

            if gs.previous_ball_position.x < paddle_rect.x {
                collision_normal += {-1, 0}
            }

            if gs.previous_ball_position.x > paddle_rect.x + paddle_rect.width {
                collision_normal += {1, 0}
            }

            if collision_normal != 0 {
                gs.ball_dir = reflect(gs.ball_dir, linalg.normalize(collision_normal))
            }
            if !gs.game_win { rl.PlaySound(gs.resources.hit_paddle_sound) }
        }

        block_x_loop: for x in 0..< NUM_BLOCKS_X {
            for y in 0..< NUM_BLOCKS_Y {
                if gs.blocks[x][y] == false {
                    continue
                }

                block_rect := calc_block_rect(x, y)

                if rl.CheckCollisionCircleRec(gs.ball_pos, BALL_RADIUS, block_rect) {
                    collision_normal: rl.Vector2

                    // Hit block from above
                    if gs.previous_ball_position.y < block_rect.y {
                        collision_normal += {0, -1}
                    }

                    // Hit block from under
                    if gs.previous_ball_position.y > block_rect.y + block_rect.height {
                        collision_normal += {0, 1}
                    }

                    // Hit block from left
                    if gs.previous_ball_position.x < block_rect.x {
                        collision_normal += {-1, 0}
                    }

                    //Hit block from right
                    if gs.previous_ball_position.x > block_rect.x + block_rect.width {
                        collision_normal += {1, 0}
                    }

                    // Check for neibghor block, if yes, cancell collision normal
                    if block_exists(gs, x + int(collision_normal.x), y) {
                        collision_normal.x = 0
                    }

                    // Check for neibghor block, if yes, cancell collision normal
                    if block_exists(gs, x, y + int(collision_normal.y) ) {
                        collision_normal.y = 0
                    }

                    //Check if there is a collision
                    if collision_normal != 0 {
                        gs.ball_dir = reflect(gs.ball_dir, collision_normal)
                    }

                    gs.blocks[x][y] = false
                    row_color := row_colors[y]
                    gs.score += block_color_score[row_color]
                    rl.SetSoundPitch(gs.resources.hit_block_sound, rand.float32_range(0.8, 1.35))
                    rl.PlaySound(gs.resources.hit_block_sound)
                    break block_x_loop
                }

            }
        }

        gs.accumulated_time -= gs.DT

    }
}
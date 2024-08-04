package breakout

import "core:math"
import "core:math/linalg"
import "core:math/rand"
import "core:fmt"
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
            gs.can_play_music = true
        }
    } else {
        gs.accumulated_time += rl.GetFrameTime()

        // Start play music
        if gs.can_play_music {
            if rl.IsMusicReady(gs.resources.music_1) {
                rl.SetMusicVolume(gs.resources.music_1, gs.resources.music_volume)
                rl.PlayMusicStream(gs.resources.music_1)
            } else {
                fmt.println("Music not ready...")
            }
        }
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

        if rl.IsKeyDown(.LEFT) {
            paddle_move_velocity -= PADDLE_SPEED
        }
    
        if rl.IsKeyDown(.RIGHT) {
            paddle_move_velocity += PADDLE_SPEED
        }        
        
        if ODIN_DEBUG {
            if rl.IsKeyPressed( .F7 ) {
                gs.show_info = !gs.show_info
            }
        
            if rl.IsKeyPressed( .F5 ) {
                restart(gs)
            } 
            
            if rl.IsKeyPressed(.F) {
                gs.fallow_paddle = !gs.fallow_paddle
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
        }
    

        gs.paddle_pos_x += paddle_move_velocity * gs.DT 
        
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

            //if touch paddle...
            gs.last_block_score = 0
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

                    new_score := block_color_score[row_color] + gs.last_block_score
                    gs.score += new_score
                    gs.last_block_score = new_score //block_color_score[row_color]
                    hit_block_color := block_color_values[row_color]

                    rl.SetSoundPitch(gs.resources.hit_block_sound, rand.float32_range(0.95, 1.05) * block_sound_pitch[row_color])
                    rl.PlaySound(gs.resources.hit_block_sound)
                    
                    glass_sound := rand.int_max(2) + 1
                    switch glass_sound {
                        case 0: {
                                    rl.SetSoundPitch(gs.resources.glass_break_1, rand.float32_range(1.0, 1.15) * block_sound_pitch[row_color])
                                    rl.PlaySound(gs.resources.glass_break_1)
                                }
                                case 1: {
                                    rl.SetSoundPitch(gs.resources.glass_break_2, rand.float32_range(1.0, 1.15) * block_sound_pitch[row_color])
                                    rl.PlaySound(gs.resources.glass_break_2)
                                }
                                case 2: {
                                    rl.SetSoundPitch(gs.resources.glass_break_3, rand.float32_range(1.0, 1.15) * block_sound_pitch[row_color])
                                    rl.PlaySound(gs.resources.glass_break_3)
                                }
                    }

                    add_emitter(gs, gs.ball_pos, gs.ball_dir, collision_normal, hit_block_color)
                    break block_x_loop
                }

            }
        }

        update_particles(gs)

        gs.accumulated_time -= gs.DT

    }
}
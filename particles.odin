package breakout

import "core:math/rand"
import "core:math/linalg"
import "core:fmt"
import rl "vendor:raylib"

Particle :: struct {
    speed               : f32,
    direction           : rl.Vector2,
    position            : rl.Vector2,
    lifetime            : i32,
    color               : rl.Color,
    opacity             : f32,
    still_live          : bool,
    size                : f32,
    opacity_step        : f32,
}

Emitter :: struct {
    particles       : [dynamic]Particle,
    still_live      : bool

}

Emitter_group :: struct {
    emitters        : [dynamic]Emitter
}

make_emitter_group :: proc() -> Emitter_group {
    new_emitters_group := Emitter_group{}
    rand.create(777)

    return new_emitters_group
}

add_emitter :: proc(gs: ^Game_State, position: rl.Vector2, direction: rl.Vector2, normal: rl.Vector2, hit_color: rl.Color) {
    TOTAL_PARTICLES :: 32
    HUE_RANGE :: f32(6.35)
    new_emiter := Emitter{
        still_live      = true
    }
    for i in 0 ..< TOTAL_PARTICLES {
        
        HSV_color := rl.ColorToHSV(hit_color)
        var_color := rl.ColorFromHSV(HSV_color.r + rand.float32_range(-HUE_RANGE, HUE_RANGE), HSV_color.g, HSV_color.b)

        new_particle := Particle {
            speed               = rand.float32_range(0.05, 1.5),
            position            = position,
            direction           = reflect(direction * rl.Vector2({rand.float32_range(0, 0.25), rand.float32_range(0, 0.25)}), normal, false), // * rand.float32_range(2.0, 145),
            lifetime            = i32(rand.float32_range(200.0, 2500.0)),
            opacity             = 1.0,
            still_live          = true,
            color               = var_color,
            size                = rand.float32_range(0.1, 4.5),
            opacity_step        = rand.float32_range(0.005, 0.085),
        }
        append(&new_emiter.particles, new_particle)
    }
    append(&gs.particles.emitters, new_emiter)
}

is_emitter_live :: proc(emitter: Emitter) -> bool {
    res : bool = true
    for particle in emitter.particles {
        res = res && particle.still_live
    }
    return res
}

destroy_emitter :: proc(gs: ^Game_State, emitter: ^Emitter) {
    part := emitter.particles
    clear(&part)
}

update_particles :: proc(gs: ^Game_State) {
    for &emitter in gs.particles.emitters {
        for &particle in emitter.particles {

            // particle.position += particle.position * particle.direction * particle.speed * gs.DT
            particle.position += particle.position * particle.direction * particle.speed * gs.DT

            if particle.position.x <= 0 - 16 || 
               particle.position.x >= SCREEN_SIZE + 16 ||
               particle.position.y <= 0 - 16 || 
               particle.position.y >= SCREEN_SIZE + 16 || 
               particle.opacity <= 0 ||
               particle.lifetime <= 0 {
                particle.still_live = false
            }

            block_x_loop: for x in 0..< NUM_BLOCKS_X {
                for y in 0..< NUM_BLOCKS_Y {
                    if gs.blocks[x][y] == false {
                        continue
                    }
                block_rect := calc_block_rect(x, y)

                if rl.CheckCollisionCircleRec(particle.position, BALL_RADIUS, block_rect) {
                    collision_normal: rl.Vector2

                    // Hit block from above
                    if particle.position.y < block_rect.y {
                        collision_normal += {0, -1}
                    }

                    // Hit block from under
                    if particle.position.y > block_rect.y + block_rect.height {
                        collision_normal += {0, 1}
                    }

                    // Hit block from left
                    if particle.position.x < block_rect.x {
                        collision_normal += {-1, 0}
                    }

                    //Hit block from right
                    if particle.position.x > block_rect.x + block_rect.width {
                        collision_normal += {1, 0}
                    }

                    //Check if there is a collision
                    if collision_normal != 0 {
                        particle.direction = reflect(particle.direction, collision_normal, false)
                        particle.opacity -= particle.opacity_step * 2
                    }   
                    
                    break block_x_loop

                }
            }
        }


            particle.opacity -= particle.opacity_step
            particle.color = rl.ColorAlpha(particle.color, particle.opacity)
        }
        if !is_emitter_live(emitter) {
            emitter.still_live = false
            destroy_emitter(gs, &emitter)
        }
    }
}

draw_particles :: proc(gs: ^Game_State) {
    for emitter in gs.particles.emitters {
        for &particle in emitter.particles {
            if particle.still_live {
                //rl.DrawCircle(i32(particle.position.x), i32(particle.position.y), particle.size, particle.color)
                rl.DrawRectangle(i32(particle.position.x), i32(particle.position.y), i32(particle.size), i32(particle.size), particle.color)
            }
        }
    }
}
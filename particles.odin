package breakout

import "core:math/rand"
import "core:math/linalg"
import rl "vendor:raylib"

Particle :: struct {
    speed               : f32,
    direction           : rl.Vector2,
    position            : rl.Vector2,
    lifetime            : i32,
    color               : rl.Color,
    opacity             : f32,
    still_live          : bool,
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

add_emitter :: proc(gs: ^Game_State, position: rl.Vector2, direction: rl.Vector2) {
    new_emiter := Emitter{
        still_live      = true
    }
    for i in 0 ..< 8 {
        new_particle := Particle {
            speed               = rand.float32_range(2.0, 5.0),
            direction           = linalg.normalize(direction * rand.float32_range(-0.5, 0.5)),
            position            = position,
            lifetime            = 200.0,
            opacity             = 1.0,
            still_live          = true,
            color               = {255, 255, 255, 255}
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

destroy_emitter :: proc(emitter: Emitter) {

}

update_particles :: proc(gs: ^Game_State) {
    for emitter in gs.particles.emitters {
        for &particle in emitter.particles {
            particle.position = particle.position * particle.direction * particle.speed * gs.DT
            if particle.position.x <= 0 - 16 || 
               particle.position.x >= SCREEN_SIZE + 16 ||
               particle.position.y <= 0 - 16 || 
               particle.position.y >= SCREEN_SIZE + 16 || 
               particle.opacity <= 0 {
                particle.still_live = false
            }
            particle.opacity -= 0.1
            particle.speed -= 0.125
            particle.color = rl.ColorAlpha(particle.color, particle.opacity)
        }
        if !is_emitter_live(emitter) {
            destroy_emitter(emitter)
        }
    }
}

draw_particles :: proc(gs: ^Game_State) {
    for emitter in gs.particles.emitters {
        for &particle in emitter.particles {
            if particle.still_live {
                rl.DrawCircle(i32(particle.position.x), i32(particle.position.y), 2.0, particle.color)
            }
        }
    }
}
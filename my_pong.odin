package main

import "core:fmt"
import "core:math"
import "core:strings"
import rl "vendor:raylib"

INITIAL_SCREEN_WIDTH :: 1024
INITIAL_SCREEN_HEIGHT :: 720
screen_width := f32(INITIAL_SCREEN_WIDTH)
screen_height := f32(INITIAL_SCREEN_HEIGHT)

BACKGROUND_COLOR :: rl.DARKGRAY

PADDLE_COLOR :: rl.RAYWHITE
PADDLE_HEIGHT : f32 : 112
PADDLE_WIDTH : f32 : 24
PADDLE_SPEED : f32 : 300
left_paddle_pos := rl.Vector2{PADDLE_WIDTH, 0.5 * INITIAL_SCREEN_HEIGHT - 0.5 * PADDLE_HEIGHT}
right_paddle_pos := rl.Vector2{INITIAL_SCREEN_WIDTH - 2 * PADDLE_WIDTH, 0.5 * INITIAL_SCREEN_HEIGHT - 0.5 * PADDLE_HEIGHT}
left_paddle_vel : rl.Vector2
right_paddle_vel : rl.Vector2

BALL_COLOR :: rl.RAYWHITE
BALL_HEIGHT : f32 : 24
BALL_WIDTH : f32 : 24
BALL_INITIAL_SPEED : f32 : 200
BALL_INITIAL_VELOCITY :: rl.Vector2{
    BALL_INITIAL_SPEED / math.SQRT_TWO, BALL_INITIAL_SPEED / math.SQRT_TWO
}
ball_pos := rl.Vector2{0.5 * (INITIAL_SCREEN_WIDTH - BALL_WIDTH), 0.5 * (INITIAL_SCREEN_HEIGHT - BALL_HEIGHT)}
ball_pos_prev : rl.Vector2
ball_vel := BALL_INITIAL_VELOCITY

frame_time : f32

SCORE_FONT_SIZE :: 64
player_score := 0
ai_score := 0

game_over := false
paused := false

// Winner :: enum {PLAYER, AI}

main :: proc() {
    rl.InitWindow(INITIAL_SCREEN_WIDTH, INITIAL_SCREEN_HEIGHT, "My Pong")
    defer rl.CloseWindow()

    // init_game()  // Will need this for restarts

    rl.SetTargetFPS(60)

    for !rl.WindowShouldClose() {
        screen_height = f32(rl.GetScreenHeight())
        screen_width = f32(rl.GetScreenWidth())
        update_game()
        draw_game()
    }
}

update_game :: proc() {
    if game_over {

    }

    if rl.IsKeyPressed(.P) {
        paused = !paused
    }

    if paused {
        return
    }

    frame_time = rl.GetFrameTime()

    // Input.
    if rl.IsKeyDown(.UP) {
        right_paddle_vel.y = -PADDLE_SPEED
    } else if rl.IsKeyDown(.DOWN) {
        right_paddle_vel.y = PADDLE_SPEED
    } else {
        right_paddle_vel.y = 0
    }

    // AI. /////////////////////////////////////////////////////////////////////
    if ball_pos.y + 0.5 * BALL_HEIGHT < left_paddle_pos.y + 0.4 * PADDLE_HEIGHT {
        left_paddle_vel.y = -PADDLE_SPEED
    } else if ball_pos.y + 0.5 * BALL_HEIGHT > left_paddle_pos.y + 0.6 * PADDLE_HEIGHT {
        left_paddle_vel.y = PADDLE_SPEED
    } else {
        left_paddle_vel.y = math.clamp(ball_vel.y, -PADDLE_SPEED, PADDLE_SPEED)
    }

    // Physics. ////////////////////////////////////////////////////////////////
    // TODO(melmer): Change reflection angle based on where ball hits paddle.
    // Ball-paddle collision.
    if ball_pos.x <= left_paddle_pos.x + PADDLE_WIDTH &&\
            ball_pos_prev.x >= left_paddle_pos.x + PADDLE_WIDTH &&\
            ball_pos.y > left_paddle_pos.y - BALL_HEIGHT &&\
            ball_pos.y < left_paddle_pos.y + PADDLE_HEIGHT {
        ball_pos.x = left_paddle_pos.x + PADDLE_WIDTH
        ball_vel.x *= -1.05
        ball_vel.y *= 1.05
    } else if ball_pos.x >= right_paddle_pos.x - BALL_WIDTH &&\
            ball_pos_prev.x <= right_paddle_pos.x - BALL_WIDTH &&\
            ball_pos.y > right_paddle_pos.y - BALL_HEIGHT &&\
            ball_pos.y < right_paddle_pos.y + PADDLE_HEIGHT {
        ball_pos.x = right_paddle_pos.x - BALL_WIDTH
        ball_vel.x *= -1.05
        ball_vel.y *= 1.05
    }

    // Ball-wall collision.
    if ball_pos.y >= screen_height - BALL_HEIGHT {
        ball_pos.y = screen_height - BALL_HEIGHT
        ball_vel.y *= -1
    } else if ball_pos.y <= 0 {
        ball_pos.y = 0
        ball_vel.y *= -1
    }

    // Paddle-wall collision
    if left_paddle_pos.y >= screen_height - PADDLE_HEIGHT {
        left_paddle_pos.y = screen_height - PADDLE_HEIGHT
        left_paddle_vel.y = min(0, left_paddle_vel.y)
    } else if left_paddle_pos.y <= 0 {
        left_paddle_pos.y = 0
        left_paddle_vel.y = max(0, left_paddle_vel.y)
    }
    if right_paddle_pos.y >= screen_height - PADDLE_HEIGHT {
        right_paddle_pos.y = screen_height - PADDLE_HEIGHT
        right_paddle_vel.y = min(0, right_paddle_vel.y)
    } else if right_paddle_pos.y <= 0 {
        right_paddle_pos.y = 0
        right_paddle_vel.y = max(0, right_paddle_vel.y)
    }

    ball_pos_prev = ball_pos

    // Update. /////////////////////////////////////////////////////////////////
    ball_pos += ball_vel * frame_time
    left_paddle_pos += left_paddle_vel * frame_time
    right_paddle_pos += right_paddle_vel * frame_time

    // TODO(melmer): Check for back wall collision and award victory/defeat
    if ball_pos.x <= 0 {
        player_score += 1
        start_new_point("You")
    } else if ball_pos.x + BALL_WIDTH >= screen_width {
        ai_score += 1
        start_new_point("Opponent")
    }
}

// TODO(melmer): Do this a different way. Set a flag like how you did for pause.
start_new_point :: proc(scorer: string) {
    rl.BeginDrawing()
    defer rl.EndDrawing()

    ball_pos = {0.5 * (screen_width + BALL_WIDTH), 0.5 * (screen_height + BALL_HEIGHT)}

    // score_text := fmt.tprintf("%v scored a point!", scorer)
    // objective_text_width := len(score_text) * SCORE_FONT_SIZE
    // rl.DrawText(strings.clone_to_cstring(score_text), i32(0.5 * (screen_width - 0.5 * f32(objective_text_width))), i32(0.75 * screen_height), SCORE_FONT_SIZE, rl.LIGHTGRAY)
    
    // rl.WaitTime(3)

    ball_vel = BALL_INITIAL_VELOCITY * (1 + 0.1 * f32(player_score + ai_score))
}

draw_game :: proc() {
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(BACKGROUND_COLOR)

    player_score_str := fmt.tprintf("%v", player_score)
    ai_score_str := fmt.tprintf("%v", ai_score)

    objective_text: cstring = "First to 5 wins!"
    objective_text_width := len(objective_text) * SCORE_FONT_SIZE
    rl.DrawText(objective_text, i32(0.5 * (screen_width - 0.5 * f32(objective_text_width))), i32(0.5 * screen_height), SCORE_FONT_SIZE, rl.LIGHTGRAY)
    rl.DrawText(strings.clone_to_cstring(player_score_str), i32(0.5 * screen_width + 256), i32(0.5 * screen_height - 256), SCORE_FONT_SIZE, rl.LIGHTGRAY)
    rl.DrawText(strings.clone_to_cstring(ai_score_str), i32(0.5 * screen_width - 256 - SCORE_FONT_SIZE), i32(screen_height / 2 - 256), SCORE_FONT_SIZE, rl.LIGHTGRAY)

    rl.DrawRectangleV(left_paddle_pos, {PADDLE_WIDTH, PADDLE_HEIGHT}, PADDLE_COLOR)
    rl.DrawRectangleV(right_paddle_pos, {PADDLE_WIDTH, PADDLE_HEIGHT}, PADDLE_COLOR)
    rl.DrawRectangleV(ball_pos, {BALL_WIDTH, BALL_HEIGHT}, BALL_COLOR)

    rl.DrawFPS(0, 0)
}

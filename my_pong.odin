package main

import "core:fmt"
import "core:math"
import "core:math/linalg"
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
left_paddle_pos : rl.Vector2
right_paddle_pos : rl.Vector2
left_paddle_vel : rl.Vector2
right_paddle_vel : rl.Vector2

BALL_COLOR :: rl.RAYWHITE
BALL_HEIGHT : f32 : 24
BALL_WIDTH : f32 : 24
BALL_INITIAL_SPEED : f32 : 250
BALL_INITIAL_VELOCITY :: rl.Vector2{
    BALL_INITIAL_SPEED / math.SQRT_TWO, BALL_INITIAL_SPEED / math.SQRT_TWO
}
ball_pos : rl.Vector2
ball_pos_prev : rl.Vector2
ball_vel : rl.Vector2

frame_time : f32

FONT_SMALL :: 32
FONT_MEDIUM :: 64
FONT_LARGE :: 96

WINNING_SCORE :: 2
player_score := 0
ai_score := 0

round_timer : f32
message: cstring

draw_ball: bool

paused := false

main :: proc() {
    rl.SetTraceLogLevel(.ERROR)
    rl.SetConfigFlags({.VSYNC_HINT})
    rl.InitWindow(INITIAL_SCREEN_WIDTH, INITIAL_SCREEN_HEIGHT, "My Pong")
    defer rl.CloseWindow()

    init_game()

    rl.SetTargetFPS(144)

    message = "Press Enter to begin"
    wait_for_key(.ENTER)

    for !rl.WindowShouldClose() {
        screen_height = f32(rl.GetScreenHeight())
        screen_width = f32(rl.GetScreenWidth())
        frame_time = rl.GetFrameTime()
        update_game()
        draw_game()
    }
}

init_game :: proc() {
    screen_width = INITIAL_SCREEN_WIDTH
    screen_height = INITIAL_SCREEN_HEIGHT
    left_paddle_pos = {PADDLE_WIDTH, 0.5 * INITIAL_SCREEN_HEIGHT - 0.5 * PADDLE_HEIGHT}
    right_paddle_pos = {INITIAL_SCREEN_WIDTH - 2 * PADDLE_WIDTH, 0.5 * INITIAL_SCREEN_HEIGHT - 0.5 * PADDLE_HEIGHT}
    ball_pos = {0.5 * (screen_width - BALL_WIDTH), 0.5 * (screen_height - BALL_HEIGHT)}
    ball_vel = BALL_INITIAL_VELOCITY * (1 + 0.1 * f32(player_score + ai_score))
    player_score = 0
    ai_score = 0
    round_timer = 0
    draw_ball = true
}

update_game :: proc() {
    if rl.IsKeyPressed(.P) {
        paused = !paused
    }

    if paused {
        return
        // TODO(melmer): Instead, call `wait_to_unpause` procedure. OR WAIT,
        // maybe instead simply use `wait_for_key(.P)`
    }

    round_timer += frame_time

    if round_timer > 2 {
        message = ""
    } else {
        message = rl.TextFormat("First to %d wins!", WINNING_SCORE)
    }

    // Input
    if rl.IsKeyDown(.UP) {
        right_paddle_vel.y = -PADDLE_SPEED
    } else if rl.IsKeyDown(.DOWN) {
        right_paddle_vel.y = PADDLE_SPEED
    } else {
        right_paddle_vel.y = 0
    }

    // AI //////////////////////////////////////////////////////////////////////
    if ball_pos.y + 0.5 * BALL_HEIGHT < left_paddle_pos.y + 0.4 * PADDLE_HEIGHT {
        left_paddle_vel.y = -PADDLE_SPEED
    } else if ball_pos.y + 0.5 * BALL_HEIGHT > left_paddle_pos.y + 0.6 * PADDLE_HEIGHT {
        left_paddle_vel.y = PADDLE_SPEED
    } else {
        left_paddle_vel.y = math.clamp(ball_vel.y, -PADDLE_SPEED, PADDLE_SPEED)
    }
    // FUTURE WORK(melmer): Could be smarter by taking into account the sign of
    // the velocity of the ball and trying to lead it such that it gets its
    // paddle off the wall just a bit quicker.
    // FUTURE WORK(melmer): Could be even smarter by predicting one or more
    // bounces, possibly with random precision based on difficulty level.

    // Physics /////////////////////////////////////////////////////////////////
    // Ball-paddle collision
    if ball_pos.x <= left_paddle_pos.x + PADDLE_WIDTH &&\
            ball_pos_prev.x >= left_paddle_pos.x + PADDLE_WIDTH &&\
            ball_pos.y > left_paddle_pos.y - BALL_HEIGHT &&\
            ball_pos.y < left_paddle_pos.y + PADDLE_HEIGHT {
        // Map collision y to -1, 1
        max_collision_y := left_paddle_pos.y + PADDLE_HEIGHT
        min_collision_y := left_paddle_pos.y - BALL_HEIGHT
        mapped_collision_y := 2 * (ball_pos.y - min_collision_y) / (max_collision_y - min_collision_y) - 1

        // Use mapped collision y to determine reflection angle
        y_frac := mapped_collision_y + 0.25 * math.sign(mapped_collision_y) * (1 - mapped_collision_y)
        x_frac := 1 - abs(y_frac)
        ball_speed := linalg.vector_length(ball_vel)

        ball_pos.x = left_paddle_pos.x + PADDLE_WIDTH
        ball_vel.x = -(ball_vel.x - 0.25 * ball_speed * x_frac)
        ball_vel.y = (ball_vel.y + 0.25 * ball_speed * y_frac)
    } else if ball_pos.x >= right_paddle_pos.x - BALL_WIDTH &&\
            ball_pos_prev.x <= right_paddle_pos.x - BALL_WIDTH &&\
            ball_pos.y > right_paddle_pos.y - BALL_HEIGHT &&\
            ball_pos.y < right_paddle_pos.y + PADDLE_HEIGHT {
        // Map collision y to -1, 1
        max_collision_y := right_paddle_pos.y + PADDLE_HEIGHT
        min_collision_y := right_paddle_pos.y - BALL_HEIGHT
        mapped_collision_y := 2 * (ball_pos.y - min_collision_y) / (max_collision_y - min_collision_y) - 1

        // Use mapped collision y to determine reflection angle
        y_frac := mapped_collision_y + 0.25 * math.sign(mapped_collision_y) * (1 - mapped_collision_y)
        x_frac := 1 - abs(y_frac)
        ball_speed := linalg.vector_length(ball_vel)

        ball_pos.x = right_paddle_pos.x - BALL_WIDTH
        ball_vel.x = -(ball_vel.x + 0.25 * ball_speed * x_frac)
        ball_vel.y = (ball_vel.y + 0.25 * ball_speed * y_frac)
    }
    // TODO(melmer): Ball and side-of-paddle collision
    // TODO(melmer): Perhaps use RayLib's collision detection functions

    // Ball-wall collision
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

    // Update //////////////////////////////////////////////////////////////////
    // Move things
    ball_pos += ball_vel * frame_time
    left_paddle_pos += left_paddle_vel * frame_time
    right_paddle_pos += right_paddle_vel * frame_time

    // Track score
    player_scored := ball_pos.x <= 0
    ai_scored := ball_pos.x + BALL_WIDTH >= screen_width
    if player_scored || ai_scored {
        if player_scored {
            player_score += 1
            message = "You scored!"
        } else if ai_scored {
            ai_score += 1
            message = "Opponent scored."
        }
        draw_ball = false
        timeout(2)
        draw_ball = true
        ball_pos = {0.5 * (screen_width - BALL_WIDTH), 0.5 * (screen_height - BALL_HEIGHT)}
        ball_vel = BALL_INITIAL_VELOCITY * (1 + 0.1 * f32(player_score + ai_score))
        left_paddle_pos = {PADDLE_WIDTH, 0.5 * INITIAL_SCREEN_HEIGHT - 0.5 * PADDLE_HEIGHT}
        right_paddle_pos = {INITIAL_SCREEN_WIDTH - 2 * PADDLE_WIDTH, 0.5 * INITIAL_SCREEN_HEIGHT - 0.5 * PADDLE_HEIGHT}
    }
    player_scored = false
    ai_scored = false

    player_won := player_score >= WINNING_SCORE
    ai_won := ai_score >= WINNING_SCORE
    if player_won || ai_won {
        if player_won {
            message = "You won!"
        } else if ai_won {
            message = "You lost."
        }
        timeout(2)
        message = "Press Enter to restart."
        wait_for_key(.ENTER)
        init_game()
    }
}

timeout :: proc(duration: f32) {
    timeout_remaining := duration
    for timeout_remaining > 0 {
        draw_game()
        if rl.WindowShouldClose() {
            rl.CloseWindow()
        }
        timeout_remaining -= rl.GetFrameTime()
    }
}

wait_for_key :: proc(key: rl.KeyboardKey) {
    waiting_for_key := true
    for waiting_for_key {
        if rl.IsKeyPressed(key) {
            waiting_for_key = false
        }
        if rl.WindowShouldClose() {
            rl.CloseWindow()
        }
        draw_game()
    }
}

draw_game :: proc() {
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(BACKGROUND_COLOR)

    message_width := rl.MeasureText(message, FONT_MEDIUM)
    player_score_text := rl.TextFormat("%d", player_score)
    player_score_text_width := rl.MeasureText(player_score_text, FONT_MEDIUM)
    ai_score_text := rl.TextFormat("%d", ai_score)
    ai_score_text_width := rl.MeasureText(ai_score_text, FONT_MEDIUM)
    rl.DrawText(message, i32(0.5 * (screen_width - f32(message_width))), i32(0.75 * screen_height - FONT_MEDIUM), FONT_MEDIUM, rl.LIGHTGRAY)
    rl.DrawText(player_score_text, i32(0.75 * screen_width - f32(player_score_text_width)), i32(0.25 * screen_height - FONT_MEDIUM), FONT_MEDIUM, rl.LIGHTGRAY)
    rl.DrawText(ai_score_text,     i32(0.25 * screen_width - f32(ai_score_text_width)),     i32(0.25 * screen_height - FONT_MEDIUM), FONT_MEDIUM, rl.LIGHTGRAY)

    rl.DrawRectangleV(left_paddle_pos, {PADDLE_WIDTH, PADDLE_HEIGHT}, PADDLE_COLOR)
    rl.DrawRectangleV(right_paddle_pos, {PADDLE_WIDTH, PADDLE_HEIGHT}, PADDLE_COLOR)

    if draw_ball {
        rl.DrawRectangleV(ball_pos, {BALL_WIDTH, BALL_HEIGHT}, BALL_COLOR)
    }

    rl.DrawFPS(0, 0)
}

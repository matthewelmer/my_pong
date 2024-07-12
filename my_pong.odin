package main

import "core:fmt"
import "core:math"
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
ball_vel := BALL_INITIAL_VELOCITY

frame_time : f32

main :: proc() {
    rl.InitWindow(INITIAL_SCREEN_WIDTH, INITIAL_SCREEN_HEIGHT, "My Pong")
    defer rl.CloseWindow()

    // init_game()

    rl.SetTargetFPS(60)

    for !rl.WindowShouldClose() {
        update_game()
        draw_game()
    }
}

update_game :: proc() {
    // Query. //////////////////////////////////////////////////////////////////
    frame_time = rl.GetFrameTime()
    screen_height = f32(rl.GetScreenHeight())
    screen_width = f32(rl.GetScreenWidth())

    // Input.
    if rl.IsKeyDown(.UP) {
        right_paddle_vel.y = -PADDLE_SPEED
    } else if rl.IsKeyDown(.DOWN) {
        right_paddle_vel.y = PADDLE_SPEED
    } else {
        right_paddle_vel.y = 0
    }

    // AI. /////////////////////////////////////////////////////////////////////
    left_paddle_vel.y = math.clamp(ball_vel.y, -PADDLE_SPEED, PADDLE_SPEED)

    // Physics. ////////////////////////////////////////////////////////////////
    // Ball-paddle collision.
    if ball_pos.x <= left_paddle_pos.x + PADDLE_WIDTH &&\
            ball_pos.y > left_paddle_pos.y - BALL_HEIGHT &&\
            ball_pos.y < left_paddle_pos.y + PADDLE_HEIGHT {
        ball_pos.x = left_paddle_pos.x + PADDLE_WIDTH
        ball_vel.x *= -1.05
        ball_vel.y *= 1.05
    } else if ball_pos.x >= right_paddle_pos.x - BALL_WIDTH &&\
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

    // Update. /////////////////////////////////////////////////////////////////
    ball_pos += ball_vel * frame_time
    left_paddle_pos += left_paddle_vel * frame_time
    right_paddle_pos += right_paddle_vel * frame_time
}

draw_game :: proc() {
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(BACKGROUND_COLOR)

    // Left paddle.
    rl.DrawRectangleV(left_paddle_pos, {PADDLE_WIDTH, PADDLE_HEIGHT}, PADDLE_COLOR)

    // Right paddle.
    rl.DrawRectangleV(right_paddle_pos, {PADDLE_WIDTH, PADDLE_HEIGHT}, PADDLE_COLOR)

    // Ball.
    rl.DrawRectangleV(ball_pos, {BALL_WIDTH, BALL_HEIGHT}, BALL_COLOR)
}

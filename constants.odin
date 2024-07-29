package breakout

WIN_SIZE                :: 960
SCREEN_SIZE             :: 320
PADDLE_WIDTH            :: 50
PADDLE_HEIGHT           :: 8
PADDLE_POS_Y            :: 300
PADDLE_SPEED            :: 200
BALL_SPEED              :f32 = 200.0
BALL_INCREMENT_SPEED    :f32 = 0.5
BALL_RADIUS             :: 4
BALL_START_Y            :: 160
NUM_BLOCKS_X            :: 10
NUM_BLOCKS_Y            :: 8
BLOCK_WIDTH             :: 28
BLOCK_HEIGHT            :: 10
RSC_FOLDER              :string: "rsc/"

Block_Color :: enum {
    Yellow,
    Green,
    Orange,
    Red,
}

use strict;
use warnings;
use Test::More;
use Games::Maze::SDL::Model;

can_ok( 'Games::Maze::SDL::Model',
    qw( new width height maze entry_x entry_y exit_x exit_y player_x player_y )
);

my ( $width, $height ) = ( 30, 20 );

my $model = Games::Maze::SDL::Model->new(
    width  => $width,
    height => $height
);

cmp_ok( $model->entry_x, '>=', 1,       'entry_x >= 1' );
cmp_ok( $model->entry_y, '>=', 1,       'entry_y >= 1' );
cmp_ok( $model->entry_x, '<=', $width,  'entry_x <= width' );
cmp_ok( $model->entry_y, '<=', $height, 'entry_y <= height' );

cmp_ok( $model->exit_x, '>=', 1,       'exit_x >= 1' );
cmp_ok( $model->exit_y, '>=', 1,       'exit_y >= 1' );
cmp_ok( $model->exit_x, '<=', $width,  'exit_x <= width' );
cmp_ok( $model->exit_y, '<=', $height, 'exit_y <= height' );

is( $model->player_x, $model->entry_x, 'player_x is entry_x' );
is( $model->player_y, $model->entry_y, 'player_y is entry_y' );

is( $model->player_direction, 'stop', 'player_direction is "stop"' );

my $cells = $model->cells;
is( scalar @$cells, $model->height, 'cells has correct number of rows' );

is( scalar(grep { @$_ == $model->width } @$cells),
    $model->height, 'cell rows have correct number of columns' );

done_testing;

use strict;
use warnings;
use Test::More;
use Games::Maze::SDL::Model::Maze;

can_ok(
    'Games::Maze::SDL::Model::Maze',
    qw( new cells_x cells_y cell_width cell_height maze cells entry_x entry_y
        exit_x exit_y )
);

my $cells_x     = 15;
my $cells_y     = 12;
my $cell_width  = 40;
my $cell_height = 40;

my $maze = Games::Maze::SDL::Model::Maze->new(
    cells_x     => $cells_x,
    cells_y     => $cells_y,
    cell_width  => $cell_width,
    cell_height => $cell_height,
);

cmp_ok( $maze->entry_x, '>=', 1,        'entry_x >= 1' );
cmp_ok( $maze->entry_y, '>=', 1,        'entry_y >= 1' );
cmp_ok( $maze->entry_x, '<=', $cells_x, 'entry_x <= cells_x' );
cmp_ok( $maze->entry_y, '<=', $cells_y, 'entry_y <= cells_y' );

cmp_ok( $maze->exit_x, '>=', 1,        'exit_x >= 1' );
cmp_ok( $maze->exit_y, '>=', 1,        'exit_y >= 1' );
cmp_ok( $maze->exit_x, '<=', $cells_x, 'exit_x <= cells_x' );
cmp_ok( $maze->exit_y, '<=', $cells_y, 'exit_y <= cells_Y' );

my $cells = $maze->cells;
is( scalar @$cells, $maze->cells_y, 'cells has correct number of rows' );

is( scalar( grep { @$_ == $maze->cells_x } @$cells ),
    $maze->cells_y, 'cell rows have correct number of columns' );

done_testing;

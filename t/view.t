use strict;
use warnings;
use Test::More;
use Games::Maze::SDL::View;

can_ok( 'Games::Maze::SDL::View',
    qw( new model width height cell_width cell_height display player ) );

done_testing;

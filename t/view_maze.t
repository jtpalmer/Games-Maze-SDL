use strict;
use warnings;
use Test::More;
use Games::Maze::SDL::View::Maze;

can_ok( 'Games::Maze::SDL::View::Maze', qw( new model width height ) );

done_testing;

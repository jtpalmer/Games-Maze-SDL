#!perl

use strict;
use warnings;

package
    sdl_maze;

use Games::Maze::SDL;

# ABSTRACT: Play the game!

Games::Maze::SDL->new->run(@ARGV);

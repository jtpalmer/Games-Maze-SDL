#!perl
use strict;
use warnings;

BEGIN {
    if ( $^O eq 'darwin' && $^X !~ /SDLPerl$/ ) {
        exec 'SDLPerl', $0, @ARGV or die "Failed to exec SDLPerl: $!";
    }
}

use Games::Maze::SDL;

# PODNAME: maze.pl
# ABSTRACT: Play the game!

Games::Maze::SDL->new->run(@ARGV);


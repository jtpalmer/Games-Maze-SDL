#!perl

# ABSTRACT: Play the game
# PODNAME: maze.pl

use strict;
use warnings;

BEGIN {
    if ( $^O eq 'darwin' && $^X !~ /SDLPerl$/ ) {
        exec 'SDLPerl', $0, @ARGV or die "Failed to exec SDLPerl: $!";
    }
}

use Games::Maze::SDL;

Games::Maze::SDL->new->run(@ARGV);

exit;

__END__


package Games::Maze::SDL::Types;
use strict;
use warnings;
use Moose::Util::TypeConstraints;

# ABSTRACT: Moose types used internally.

enum 'Games::Maze::SDL::Direction' => qw(north south west east);

1;

=pod

=cut


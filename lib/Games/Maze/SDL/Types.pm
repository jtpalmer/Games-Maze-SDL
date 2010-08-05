package Games::Maze::SDL::Types;

# ABSTRACT: Moose types used internally.

use Moose::Util::TypeConstraints;

enum 'Games::Maze::SDL::Direction' => qw(up down left right);

no Moose::Util::TypeConstraints;

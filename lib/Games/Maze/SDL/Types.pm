package Games::Maze::SDL::Types;

# ABSTRACT: Moose types used internally.

use Moose::Util::TypeConstraints;

enum 'Games::Maze::SDL::Direction' => qw(north south west east);

no Moose::Util::TypeConstraints;

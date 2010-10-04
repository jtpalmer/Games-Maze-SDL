package Games::Maze::SDL::Model::Wall;

use strict;
use warnings;

use Class::XSAccessor {
    constructor => 'new',
    accessors   => [ 'x', 'y', 'w', 'h' ],
};

sub v_x { 0 }
sub v_y { 0 }

1;

__END__

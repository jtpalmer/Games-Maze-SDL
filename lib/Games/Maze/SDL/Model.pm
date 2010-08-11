package Games::Maze::SDL::Model;

# ABSTRACT: Model.

use Moose;
use Games::Maze;
use Games::Maze::SDL::Types;
use Games::Maze::SDL::Observable;
use POSIX 'floor';

with 'Games::Maze::SDL::Observable';

has 'cells_x' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'cells_y' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'cell_width' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'cell_height' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'maze' => (
    is         => 'ro',
    lazy_build => 1,
    init_arg   => undef,
);

has 'cells' => (
    is         => 'ro',
    isa        => 'ArrayRef[ArrayRef[Int]]',
    lazy_build => 1,
    init_arg   => undef,
);

has 'entry_x' => (
    is         => 'ro',
    isa        => 'Int',
    lazy_build => 1,
    init_arg   => undef,
);

has 'entry_y' => (
    is         => 'ro',
    isa        => 'Int',
    lazy_build => 1,
    init_arg   => undef,
);

has 'exit_x' => (
    is         => 'ro',
    isa        => 'Int',
    lazy_build => 1,
    init_arg   => undef,
);

has 'exit_y' => (
    is         => 'ro',
    isa        => 'Int',
    lazy_build => 1,
    init_arg   => undef,
);

has 'player_x' => (
    is         => 'rw',
    isa        => 'Num',
    lazy_build => 1,
    init_arg   => undef,
);

has 'player_y' => (
    is         => 'rw',
    isa        => 'Num',
    lazy_build => 1,
    init_arg   => undef,
);

has 'player_width' => (
    is       => 'rw',
    isa      => 'Int',
    required => 1,
);

has 'player_height' => (
    is       => 'rw',
    isa      => 'Int',
    required => 1,
);

has 'player_direction' => (
    is      => 'rw',
    isa     => 'Games::Maze::SDL::Direction',
    default => 'south',
);

has 'player_velocity' => (
    is      => 'rw',
    isa     => 'Num',
    default => 0,
);

sub BUILD {
    my ($self) = @_;

    $self->cells->[ $self->entry_y - 1 ][ $self->entry_x - 1 ]
        &= ~$Games::Maze::North;
    $self->cells->[ $self->exit_y - 1 ][ $self->exit_x - 1 ]
        &= ~$Games::Maze::South;
}

sub _build_maze {
    my ($self) = @_;
    my $maze = Games::Maze->new(
        dimensions => [ $self->cells_x, $self->cells_y, 1 ] );
    $maze->make();
    return $maze;
}

sub _build_cells {
    my ($self) = @_;
    my @rows = ( split /\n/, $self->maze->to_hex_dump )[ 1 .. $self->cells_y ];
    my @cells = map {
        [ ( map {hex} split /\W/ )[ 2 .. $self->cells_x + 1 ] ]
    } @rows;
    return \@cells;
}

sub _maze_attr {
    my ($self) = @_;
    my %attr = $self->maze->describe;
    return \%attr;
}

sub _build_entry_x {
    my ($self) = @_;
    return $self->_maze_attr->{entry}->[0];
}

sub _build_entry_y {
    my ($self) = @_;
    return $self->_maze_attr->{entry}->[1];
}

sub _build_exit_x {
    my ($self) = @_;
    return $self->_maze_attr->{exit}->[0];
}

sub _build_exit_y {
    my ($self) = @_;
    return $self->_maze_attr->{exit}->[1];
}

sub _build_player_x {
    my ($self) = @_;
    return $self->entry_x;
}

sub _build_player_y {
    my ($self) = @_;
    return $self->entry_y;
}

after qw(player_x player_y player_direction player_velocity) => sub {
    my $self = shift;

    if (@_) {
        $self->changed(1);
    }
};

after 'player_direction' => sub {
    my $self = shift;

    if (@_) {
        $self->player_velocity(0.1);
        $self->notify_observers( { type => 'player_turned' } );
    }
};

sub scale_x {
    my ( $self, $x ) = @_;
    return $self->cell_width * $x;
}

sub scale_y {
    my ( $self, $y ) = @_;
    return $self->cell_height * $y;
}

sub translate_x {
    my ( $self, $x ) = @_;
    return $self->cell_width * ( $x - 1 ) + $self->cell_width / 2;
}

sub translate_y {
    my ( $self, $y ) = @_;
    return $self->cell_height * ( $y - 1 ) + $self->cell_height / 2;
}

sub paths {
    my ( $self, $x, $y ) = @_;
    my $cell = $self->cells->[ $y - 1 ][ $x - 1 ];
    return {
        north => $cell & $Games::Maze::North,
        south => $cell & $Games::Maze::South,
        east  => $cell & $Games::Maze::East,
        west  => $cell & $Games::Maze::West,
    };
}

sub move_player {
    my ( $self, $dt ) = @_;

    my ( $x, $y ) = ( $self->player_x,        $self->player_y );
    my ( $v, $d ) = ( $self->player_velocity, $self->player_direction );

    return if $v == 0;

    my $cell_x = floor( $self->player_x / $self->cell_width ) + 1;
    my $cell_y = floor( $self->player_y / $self->cell_height  ) + 1;
    my $paths  = $self->paths( $cell_x, $cell_y );

    $cell_x = ($cell_x - 1) * $self->cell_width;
    $cell_y = ($cell_y - 1) * $self->cell_height;

    my $cell_y_min = $cell_y + 1;
    my $cell_y_max = $cell_y + $self->cell_width - $self->player_width;
    my $cell_x_min = $cell_x + 1;
    my $cell_x_max = $cell_x + $self->cell_height - $self->player_width;

    if ( $d eq 'south' ) {
        my $new_y = $y + $v * $dt;
        if ( $new_y > $cell_y_max ) {
            if ( $paths->{$d} ) {
                $new_y = $cell_y_max if $x > $cell_x_max;
                $new_y = $cell_y_max if $x < $cell_x_min;
            }
            else {
                $new_y = $cell_y_max;
            }
        }
        $self->player_y($new_y);
    }
    elsif ( $d eq 'north' ) {
        my $new_y = $y - $v * $dt;
        if ( $new_y < $cell_y_min ) {
            if ( $paths->{$d} ) {
                $new_y = $cell_y_min if $x > $cell_x_max;
                $new_y = $cell_y_min if $x < $cell_x_min;
            }
            else {
                $new_y = $cell_y_min;
            }
        }
        $self->player_y($new_y);
    }
    elsif ( $d eq 'east' ) {
        my $new_x = $x + $v * $dt;
        if ( $new_x > $cell_x_max ) {
            if ( $paths->{$d} ) {
                $new_x = $cell_x_max if $y > $cell_y_max;
                $new_x = $cell_x_max if $y < $cell_y_min;
            }
            else {
                $new_x = $cell_x_max;
            }
        }
        $self->player_x($new_x);
    }
    elsif ( $d eq 'west' ) {
        my $new_x = $x - $v * $dt;
        if ( $new_x < $cell_x_min ) {
            if ( $paths->{$d} ) {
                $new_x = $cell_x_min if $y > $cell_y_max;
                $new_x = $cell_x_min if $y < $cell_y_min;
            }
            else {
                $new_x = $cell_x_min;
            }
        }
        $self->player_x($new_x);
    }

    $self->notify_observers( { type => 'player_moved' } );
}

sub stop_player {
    my ($self) = @_;
    $self->player_velocity(0);
    $self->notify_observers( { type => 'player_stopped' } );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

    use Games::Maze::SDL::Model;

    my $model = Games::Maze::SDL::Model->new(
    );

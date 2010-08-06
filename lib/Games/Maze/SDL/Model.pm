package Games::Maze::SDL::Model;

# ABSTRACT: Model.

use Moose;
use Games::Maze;
use Games::Maze::SDL::Types;

has 'width' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'height' => (
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

has 'player_direction' => (
    is      => 'ro',
    isa     => 'Games::Maze::SDL::Direction',
    default => 'down',
);

sub _build_maze {
    my ($self) = @_;
    my $maze = Games::Maze->new(
        dimensions => [ $self->width, $self->height, 1 ] );
    $maze->make();
    return $maze;
}

sub _build_cells {
    my ($self) = @_;
    my @rows = ( split /\n/, $self->maze->to_hex_dump )[ 1 .. $self->height ];
    my @cells = map {
        [ ( map {hex} split /\W/ )[ 2 .. $self->width + 1 ] ]
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

    # TODO
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

    use Games::Maze::SDL::Model;

    my $model = Games::Maze::SDL::Model->new(
        width  => $width,
        height => $height,
    );

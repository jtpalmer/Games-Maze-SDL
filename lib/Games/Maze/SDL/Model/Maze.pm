package Games::Maze::SDL::Model::Maze;

# ABSTRACT: Maze model.

use Moose;
use Games::Maze;
use Games::Maze::SDL::Role::Observable;
use POSIX 'floor';

with 'Games::Maze::SDL::Role::Observable';

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
        form       => 'Rectangle',
        cell       => 'Quad',
        dimensions => [ $self->cells_x, $self->cells_y, 1 ]
    );
    $maze->make();
    return $maze;
}

sub _build_cells {
    my ($self) = @_;
    my @rows
        = ( split /\n/, $self->maze->to_hex_dump )[ 1 .. $self->cells_y ];
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

sub cell_walls {
    my ( $self, $x, $y ) = @_;

    my $paths = $self->paths( $x, $y );

    my $min_x = ( $x - 1 ) * $self->cell_width;
    my $min_y = ( $y - 1 ) * $self->cell_height;
    my $max_x = $min_x + $self->cell_height;
    my $max_y = $min_y + $self->cell_width;

    my @walls;

    if ( !$paths->{north} ) {
        push @walls,
            {
            x => $min_x,
            y => $min_y,
            w => $self->cell_width,
            h => 1,
            };
    }

    if ( !$paths->{south} ) {
        push @walls,
            {
            x => $min_x,
            y => $max_y,
            w => $self->cell_width,
            h => 1,
            };
    }

    if ( !$paths->{west} ) {
        push @walls,
            {
            x => $min_x,
            y => $min_y,
            w => 1,
            h => $self->cell_height,
            };
    }

    if ( !$paths->{east} ) {
        push @walls,
            {
            x => $max_x,
            y => $min_y,
            w => 1,
            h => $self->cell_height,
            };
    }

    foreach my $x ( $min_x, $max_x ) {
        foreach my $y ( $min_y, $max_y ) {
            push @walls,
                {
                x => $x,
                y => $y,
                w => 1,
                h => 1,
                };
        }
    }

    return \@walls;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

    use Games::Maze::SDL::Model::Maze;

    my $model = Games::Maze::SDL::Model::Maze->new(
        cells_x     => $cells_x,
        cells_y     => $cells_y,
        cell_width  => $cell_width,
        cell_height => $cell_height,
    );

package Games::Maze::SDL::Model::Player;

# ABSTRACT: Player model.

use Moose;
use Games::Maze::SDL::Types;
use Games::Maze::SDL::Role::Observable;
use Games::Maze::SDL::Model::Maze;
use POSIX 'floor';

with 'Games::Maze::SDL::Role::Observable';

has 'maze' => (
    is       => 'rw',
    isa      => 'Games::Maze::SDL::Model::Maze',
    required => 1,
);

has 'width' => (
    is       => 'rw',
    isa      => 'Int',
    required => 1,
);

has 'height' => (
    is       => 'rw',
    isa      => 'Int',
    required => 1,
);

has 'direction' => (
    is      => 'rw',
    isa     => 'Games::Maze::SDL::Direction',
    default => 'south',
);

has 'x' => (
    is         => 'rw',
    isa        => 'Num',
    lazy_build => 1,
    init_arg   => undef,
);

has 'y' => (
    is         => 'rw',
    isa        => 'Num',
    lazy_build => 1,
    init_arg   => undef,
);

has 'velocity_x' => (
    is      => 'rw',
    isa     => 'Num',
    default => 0,
);

has 'velocity_y' => (
    is      => 'rw',
    isa     => 'Num',
    default => 0,
);

has 'max_velocity' => (
    is      => 'ro',
    isa     => 'Num',
    default => 0.1,
);

has 'acceleration_y' => (
    is      => 'rw',
    isa     => 'Num',
    default => 0,
);

has 'acceleration_x' => (
    is      => 'rw',
    isa     => 'Num',
    default => 0,
);

sub _build_x {
    my ($self) = @_;
    return $self->maze->translate_x( $self->maze->entry_x )
        - $self->width / 2;
}

sub _build_y {
    my ($self) = @_;
    return $self->maze->translate_y( $self->maze->entry_y )
        - $self->height / 2;
}

after qw( x y direction velocity_x velocity_y ) => sub {
    my $self = shift;

    if (@_) {
        $self->changed(1);
    }
};

after 'direction' => sub {
    my $self = shift;

    if (@_) {
        my $d = shift;
        if ( $d eq 'north' ) {
            $self->acceleration_x(0);
            $self->acceleration_y(-0.0001);
        }
        if ( $d eq 'south' ) {
            $self->acceleration_x(0);
            $self->acceleration_y(0.0001);
        }
        if ( $d eq 'west' ) {
            $self->acceleration_x(-0.0001);
            $self->acceleration_y(0);
        }
        if ( $d eq 'east' ) {
            $self->acceleration_x(0.0001);
            $self->acceleration_y(0);
        }

        $self->notify_observers( { type => 'turned' } );
    }
};

sub velocity {
    my ($self) = @_;

    my $vx = $self->velocity_x;
    my $vy = $self->velocity_y;

    return sqrt( $vx * $vx + $vy * $vy );
}

sub move {
    my ( $self, undef, $dt ) = @_;

    my %d = ( x => $self->x,              y => $self->y );
    my %v = ( x => $self->velocity_x,     y => $self->velocity_y );
    my %a = ( x => $self->acceleration_x, y => $self->acceleration_y );

    my $cell_x = floor( $self->x / $self->maze->cell_width ) + 1;
    my $cell_y = floor( $self->y / $self->maze->cell_height ) + 1;

    foreach my $dimension (qw( x y )) {
        my ( $d, $v, $a ) = map { $_->{$dimension} } \( %d, %v, %a );

        if ( $a == 0 ) {
            $v = $v * 0.9;
        }
        else {
            $v = $v + $dt * $a;
        }

        my $direction = $v <=> 0;
        if ( abs($v) < 0.00000001 ) {
            $v = 0;
        }
        elsif ( abs($v) > $self->max_velocity ) {
            $v = $direction * $self->max_velocity;
        }

        $d += $v * $dt;

        my $set_d = $dimension;
        my $set_v = 'velocity_' . $dimension;
        $self->$set_d($d);
        $self->$set_v($v);
    }

    my $paths = $self->maze->paths( $cell_x, $cell_y );
    my $borders = $self->maze->cell_borders( $cell_x, $cell_y );

    my %limits = (
        x => {
            -1 => [ $paths->{west}, $borders->{min_x} ],
            1  => [ $paths->{east}, $borders->{max_x} - $self->width ],
        },
        y => {
            -1 => [ $paths->{north}, $borders->{min_y} ],
            1  => [ $paths->{south}, $borders->{max_y} - $self->width ],
        }
    );

    my @dimensions
        = abs( $v{y} ) > abs( $v{x} )
        ? ( [qw( x y )], [qw( y x )] )
        : ( [qw( y x )], [qw( x y )] );
    foreach my $dimensions (@dimensions) {
        my ( $dimension, $other_dimension ) = @$dimensions;

        %d = ( x => $self->x,          y => $self->y );
        %v = ( x => $self->velocity_x, y => $self->velocity_y );

        my ( $d, $v, $l ) = map { $_->{$dimension} } \( %d, %v, %limits );

        my ( $other_d, $other_l )
            = map { $_->{$other_dimension} } \( %d, %limits );

        my $other_d_min = $other_l->{-1}->[1];
        my $other_d_max = $other_l->{1}->[1];

        my $direction = $v <=> 0;

        next if $v == 0;

        my ( $path, $limit ) = @{ $l->{$direction} };

        if ( ( $d <=> $limit ) == $direction ) {
            if ( !$path ) {
                $d = $limit;
                $v = 0;
            }
            elsif ( $other_d > $other_d_max || $other_d < $other_d_min ) {
                $d = $limit;
                $v = 0;
            }
        }

        my $set_d = $dimension;
        my $set_v = 'velocity_' . $dimension;
        $self->$set_d($d);
        $self->$set_v($v);
    }

    if ( $self->velocity_x == 0 && $self->velocity_y == 0 ) {
        $self->notify_observers( { type => 'stopped' } );
    }
    else {
        $self->notify_observers( { type => 'moved' } );
    }
}

sub stop {
    my ($self) = @_;
    $self->acceleration_x(0);
    $self->acceleration_y(0);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

    use Games::Maze::SDL::Model::Player;

    my $model = Games::Maze::SDL::Model::Player->new(
        width  => $width,
        height => $height,
        maze   => $maze,
    );

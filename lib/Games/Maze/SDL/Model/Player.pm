package Games::Maze::SDL::Model::Player;

# ABSTRACT: Player model.

use Moose;
use Games::Maze::SDL::Types;
use Games::Maze::SDL::Role::Observable;
use Games::Maze::SDL::Model::Maze;
use Collision::Util ':interval';
use POSIX 'floor';
use Data::Dumper;

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
    default => 0.25,
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

sub v_x {
    my ($self) = @_;
    return $self->velocity_x;
}

sub v_y {
    my ($self) = @_;
    return $self->velocity_y;
}

sub w {
    my ($self) = @_;
    return $self->width;
}

sub h {
    my ($self) = @_;
    return $self->height;
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
            $self->acceleration_y(-0.1);
        }
        if ( $d eq 'south' ) {
            $self->acceleration_x(0);
            $self->acceleration_y(0.1);
        }
        if ( $d eq 'west' ) {
            $self->acceleration_x(-0.1);
            $self->acceleration_y(0);
        }
        if ( $d eq 'east' ) {
            $self->acceleration_x(0.1);
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
    my ( $self, $dt ) = @_;

    my %d = ( x => $self->x,              y => $self->y );
    my %v = ( x => $self->velocity_x,     y => $self->velocity_y );
    my %a = ( x => $self->acceleration_x, y => $self->acceleration_y );

    foreach my $dim (qw( x y )) {
        if ( $a{$dim} == 0 ) {
            $v{$dim} *= 0.99;
        }
        else {
            $v{$dim} += $dt * $a{$dim};

            if ( abs( $v{$dim} ) > $self->max_velocity ) {
                $v{$dim} = ( $v{$dim} <=> 0 ) * $self->max_velocity;
            }
        }

        if ( abs( $v{$dim} ) < 0.01 ) {
            $v{$dim} = 0;
        }

        $d{$dim} += $dt * $v{$dim};
    }

    my $cell_x = floor( ( $self->x + $self->width / 2 ) / $self->maze->cell_width ) + 1;
    my $cell_y = floor( ( $self->y + $self->height / 2 ) / $self->maze->cell_height ) + 1; 
    my @collisions;

    foreach my $wall ( @{ $self->maze->cell_walls( $cell_x, $cell_y ) } ) {
        my $c = $self->check_collision_interval( $wall, 1 );
        push @collisions, [ $wall, $c ] if $c;
    }

    foreach my $c (@collisions) {
        my ( $wall, $axis ) = @$c;

        print Dumper( $axis, $wall ) if $axis->[0] || $axis->[1];

        if ( $axis->[0] ) {
            $d{x} = $wall->x - $self->width - 1 if $axis->[0] == -1;
            $d{x} = $wall->x + 2                if $axis->[0] == 1;
            $v{x} = 0;
        }
        if ( $axis->[1] ) {
            $d{y} = $wall->y - $self->height - 1 if $axis->[1] == 1;
            $d{y} = $wall->y + 2                 if $axis->[1] == -1;
            $v{y} = 0;
        }
    }

    $self->x( $d{x} );
    $self->y( $d{y} );
    $self->velocity_x( $v{x} );
    $self->velocity_y( $v{y} );

    if ( $v{x} == 0 && $v{y} == 0 && $a{x} == 0 && $a{y} == 0 ) {
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

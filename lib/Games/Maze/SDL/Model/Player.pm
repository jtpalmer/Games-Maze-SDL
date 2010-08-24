package Games::Maze::SDL::Model::Player;

# ABSTRACT: Player model.

use Moose;
use Games::Maze::SDL::Types;
use Games::Maze::SDL::Role::Observable;
use Games::Maze::SDL::Model::Maze;
use Collision::2D ':all';
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

    my $rect = hash2rect(
        {   x  => $d{x},
            y  => $d{y},
            xv => $v{x},
            yv => $v{y},
            w  => $self->width,
            h  => $self->height,
        }
    );

    foreach my $dim (qw( x y )) {
        if ( $a{$dim} == 0 ) {
            $v{$dim} *= 0.9;
        }
        else {
            $v{$dim} += $dt * $a{$dim};

            if ( $v{$dim} > $self->max_velocity ) {
                $v{$dim} = $self->max_velocity;
            }
        }

        if (abs($v{$dim}) < 1.0e-3) {
            $v{$dim} = 0;
        }

        $d{$dim} += $dt * $v{$dim};
    }

    my $cell_x = floor( $self->x / $self->maze->cell_width ) + 1;
    my $cell_y = floor( $self->y / $self->maze->cell_height ) + 1;

    my @collisions;

    foreach my $wall ( @{ $self->maze->cell_walls( $cell_x, $cell_y ) } ) {
        my $c = dynamic_collision(
            $rect,
            hash2rect($wall),
            interval   => $dt,
            keep_order => 1,
        );
        push @collisions, [ $wall, $c ] if $c;
    }

    if (@collisions) {
        my ($c) = sort { $a->[1]->time <=> $b->[1]->time } @collisions;

        my ( $wall, $collision ) = @$c;

        if ( $collision->axis eq 'x' ) {
            $d{x}
                = ( $v{x} <=> 0 ) == 1
                ? $wall->{x} - $self->width - 1
                : $wall->{x} + 2;
            $v{x} = 0;
        }
        else {
            $d{y}
                = ( $v{y} <=> 0 ) == 1
                ? $wall->{y} - $self->height - 1
                : $wall->{y} + 2;
            $v{y} = 0;
        }
    }

    $self->x( $d{x} );
    $self->y( $d{y} );
    $self->velocity_x( $v{x} );
    $self->velocity_y( $v{y} );

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

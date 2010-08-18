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

    foreach my $dim (qw( x y )) {
        my ( $d, $v, $a ) = map { $_->{$dim} } \( %d, %v, %a );

        if ( $a == 0 ) {
            $v = $v * 0.9;
        }
        else {
            $v = $v + $dt * $a;
        }

        my $dir = $v <=> 0;
        if ( abs($v) < 0.00000001 ) {
            $v = 0;
        }
        elsif ( abs($v) > $self->max_velocity ) {
            $v = $dir * $self->max_velocity;
        }

        $d += $v * $dt;

        my $set_d = $dim;
        my $set_v = 'velocity_' . $dim;
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

    my %old_d = %d;

    %d = ( x => $self->x,          y => $self->y );
    %v = ( x => $self->velocity_x, y => $self->velocity_y );

    foreach my $dims ( [qw( x y )], [qw( y x )] ) {
        my ( $dim, $odim ) = @$dims;

        my ( $d, $v, $l ) = map { $_->{$dim} } \( %d, %v, %limits );
        my ( $od, $ov, $ol ) = map { $_->{$odim} } \( %d, %v, %limits );

        next unless $ov == 0 && $v != 0;

        my $od_min = $ol->{-1}->[1];
        my $od_max = $ol->{1}->[1];

        my $dir = $v <=> 0;

        my ( $path, $limit ) = @{ $l->{$dir} };

        if ( ( $d <=> $limit ) == $dir ) {
            if ( !$path ) {
                $d = $limit;
                $v = 0;
            }
            elsif ( $od > $od_max || $od < $od_min ) {
                $d = $limit;
                $v = 0;
            }
        }

        my $set_d = $dim;
        my $set_v = 'velocity_' . $dim;
        $self->$set_d($d);
        $self->$set_v($v);
    }

    if ( $v{x} != 0 && $v{y} != 0 ) {
        my $xdir = $v{x} <=> 0;
        my $ydir = $v{y} <=> 0;

        my $xmin = $limits{x}->{-1}->[1];
        my $xmax = $limits{x}->{1}->[1];
        my $ymin = $limits{y}->{-1}->[1];
        my $ymax = $limits{y}->{1}->[1];

        my $xpath = $limits{x}->{$xdir}->[0];
        my $ypath = $limits{y}->{$ydir}->[0];
        my $xlim  = $limits{x}->{$xdir}->[1];
        my $ylim  = $limits{y}->{$ydir}->[1];

        if ( ($d{x} <=> $xlim) == $xdir && ($d{y} <=> $ylim) == $ydir ) {
            my $m = ($old_d{y} - $d{y}) / ($old_d{x} - $d{x});
        

        }
        elsif ( ($d{x} <=> $xlim) == $xdir ) {
            if ( !$xpath ) {
                $d{x} = $xlim;
                $v{x} = 0;
            }
            elsif ( $d{y} > $ymax || $d{y} < $ymin) {
                $d{x} = $xlim;
                $v{x} = 0;
            }
        }
        elsif ( ($d{y} <=> $ylim) == $ydir ) {
            if ( !$ypath ) {
                $d{y} = $ylim;
                $v{y} = 0;
            }
            elsif ( $d{x} > $xmax || $d{x} < $xmin) {
                $d{y} = $ylim;
                $v{y} = 0;
            }
        }

        $self->x($d{x});
        $self->y($d{y});
        $self->velocity_x($v{x});
        $self->velocity_y($v{y});
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

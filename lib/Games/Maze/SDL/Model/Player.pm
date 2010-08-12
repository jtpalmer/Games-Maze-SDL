package Games::Maze::SDL::Model::Player;

# ABSTRACT: Player model.

use Moose;
use Games::Maze::SDL::Types;
use Games::Maze::SDL::Role::Observable;
use Games::Maze::SDL::Model::Maze;
use POSIX 'floor';

with 'Games::Maze::SDL::Role::Observable';

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

has 'velocity' => (
    is      => 'rw',
    isa     => 'Num',
    default => 0,
);

has 'maze' => (
    is       => 'rw',
    isa      => 'Games::Maze::SDL::Model::Maze',
    required => 1,
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

after qw( x y direction velocity ) => sub {
    my $self = shift;

    if (@_) {
        $self->changed(1);
    }
};

after 'direction' => sub {
    my $self = shift;

    if (@_) {
        $self->velocity(0.1);
        $self->notify_observers( { type => 'turned' } );
    }
};

sub move {
    my ( $self, $dt ) = @_;

    my ( $x, $y ) = ( $self->x,        $self->y );
    my ( $v, $d ) = ( $self->velocity, $self->direction );

    return if $v == 0;

    my $cell_x = floor( $self->x / $self->maze->cell_width ) + 1;
    my $cell_y = floor( $self->y / $self->maze->cell_height ) + 1;
    my $paths  = $self->maze->paths( $cell_x, $cell_y );

    $cell_x = ( $cell_x - 1 ) * $self->maze->cell_width;
    $cell_y = ( $cell_y - 1 ) * $self->maze->cell_height;

    my $cell_y_min = $cell_y + 1;
    my $cell_y_max = $cell_y + $self->maze->cell_width - $self->width;
    my $cell_x_min = $cell_x + 1;
    my $cell_x_max = $cell_x + $self->maze->cell_height - $self->width;

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
        $self->y($new_y);
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
        $self->y($new_y);
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
        $self->x($new_x);
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
        $self->x($new_x);
    }

    $self->notify_observers( { type => 'moved' } );
}

sub stop {
    my ($self) = @_;
    $self->velocity(0);
    $self->notify_observers( { type => 'stopped' } );
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

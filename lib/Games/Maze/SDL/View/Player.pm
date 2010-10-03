package Games::Maze::SDL::View::Player;

# ABSTRACT: Player view.

use Moose;
use Games::Maze::SDL::Model::Player;
use SDL::Rect;
use SDLx::Sprite::Animated;
use POSIX 'floor';

has 'model' => (
    is       => 'ro',
    isa      => 'Games::Maze::SDL::Model::Player',
    required => 1,
);

has 'sprite' => (
    is         => 'ro',
    isa        => 'SDLx::Sprite::Animated',
    lazy_build => 1,
    init_arg   => undef,
    handles    => [qw( rect )],
);

sub BUILD {
    my ($self) = @_;

    $self->model->add_observer( sub { $self->handle_event(@_) } );

    return $self;
}

sub _build_sprite {
    my ($self) = @_;

    my $sprite = SDLx::Sprite::Animated->new(
        image           => Games::Maze::SDL->share_dir->file('hero.png'),
        rect            => SDL::Rect->new( 0, 0, 24, 24 ),
        ticks_per_frame => 10,
        type            => 'reverse',
        sequences       => {
            'north' => [ [ 0, 1 ], [ 0, 2 ], [ 0, 0 ] ],
            'south' => [ [ 2, 1 ], [ 2, 2 ], [ 2, 0 ] ],
            'west'  => [ [ 3, 0 ], [ 3, 1 ], [ 3, 2 ] ],
            'east'  => [ [ 1, 0 ], [ 1, 1 ], [ 1, 2 ] ],
            'stop'  => [ [ 4, 0 ] ],
        },
    );

    $sprite->alpha_key( [ 255, 0, 0 ] );
    $sprite->sequence( $self->model->direction );

    $sprite->x( $self->model->x );
    $sprite->y( $self->model->y );

    return $sprite;
}

sub draw {
    my ( $self, $display ) = @_;

    $self->sprite->draw($display);
}

sub handle_event {
    my ( $self, $event ) = @_;

    if ( $event->{type} eq 'moved' ) {
        $self->sprite->x( $self->model->x );
        $self->sprite->y( $self->model->y );

        my $v = $self->model->velocity;
        $self->sprite->ticks_per_frame( floor( 5 / $v ) + 5 )
            unless $v == 0;
    }
    elsif ( $event->{type} eq 'turned' ) {
        $self->sprite->sequence( $self->model->direction );
        $self->sprite->start;
    }
    elsif ( $event->{type} eq 'stopped' ) {
        $self->sprite->reset;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

    use Games::Maze::SDL::View::Player;

    my $view = Games::Maze::SDL::View::Player->new(
        model => $model,
    );

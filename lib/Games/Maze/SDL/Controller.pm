package Games::Maze::SDL::Controller;

# ABSTRACT: Controller.

use Moose;
use MooseX::NonMoose::InsideOut;
use SDL::Event;
use SDL::Events ':all';

extends 'SDLx::Controller';

has 'model' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

has 'view' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

sub BUILD {
    my ($self) = @_;

    $self->add_event_handler( sub { $self->on_event(@_) } );
    $self->add_move_handler( sub  { $self->model->{player}->move(@_) } );
    $self->add_show_handler( sub  { $self->view->{maze}->draw(@_) } );

    return $self;
}

sub on_event {
    my ( $self, $e ) = @_;

    return 0 if $e->type == SDL_QUIT;
    return 0 if $e->key_sym == SDLK_ESCAPE;

    my $player = $self->model->{player};

    if ( $e->type == SDL_KEYDOWN ) {
        $player->direction('west')  if $e->key_sym == SDLK_LEFT;
        $player->direction('east')  if $e->key_sym == SDLK_RIGHT;
        $player->direction('south') if $e->key_sym == SDLK_DOWN;
        $player->direction('north') if $e->key_sym == SDLK_UP;
    }
    elsif ( $e->type == SDL_KEYUP ) {
        my $d = $player->direction;

        $player->stop if $e->key_sym == SDLK_LEFT  && $d eq 'west';
        $player->stop if $e->key_sym == SDLK_RIGHT && $d eq 'east';
        $player->stop if $e->key_sym == SDLK_DOWN  && $d eq 'south';
        $player->stop if $e->key_sym == SDLK_UP    && $d eq 'north';
    }

    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

    use Games::Maze::SDL::Controller;

    my $controller = Games::Maze::SDL::Controller->new(
        dt    => $dt
        model => {
            maze   => $maze_model,
            player => $player_model,
        },
        view => {
            maze   => $maze_view,
            player => $player_view,
        },
    );

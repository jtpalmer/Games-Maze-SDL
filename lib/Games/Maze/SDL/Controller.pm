package Games::Maze::SDL::Controller;

# ABSTRACT: Controller.

use Moose;
use MooseX::NonMoose::InsideOut;
use Games::Maze::SDL::Model::Player;
use Games::Maze::SDL::View::Maze;
use SDL::Event;
use SDL::Events ':all';

extends 'SDLx::Controller';

has 'player' => (
    is       => 'ro',
    isa      => 'Games::Maze::SDL::Model::Player',
    required => 1,
);

has 'view' => (
    is       => 'ro',
    isa      => 'Games::Maze::SDL::View::Maze',
    required => 1,
);

sub BUILD {
    my ($self) = @_;

    $self->add_event_handler( sub { $self->on_event(@_) } );
    $self->add_move_handler( sub  { $self->player->move(@_) } );
    $self->add_show_handler( sub  { $self->view->draw(@_) } );

    return $self;
}

sub on_event {
    my ( $self, $e ) = @_;

    return 0 if $e->type == SDL_QUIT;
    return 0 if $e->key_sym == SDLK_ESCAPE;

    if ( $e->type == SDL_KEYDOWN ) {
        $self->player->direction('west')  if $e->key_sym == SDLK_LEFT;
        $self->player->direction('east')  if $e->key_sym == SDLK_RIGHT;
        $self->player->direction('south') if $e->key_sym == SDLK_DOWN;
        $self->player->direction('north') if $e->key_sym == SDLK_UP;
    }
    elsif ( $e->type == SDL_KEYUP ) {
        my $d = $self->player->direction;

        $self->player->stop if $e->key_sym == SDLK_LEFT  && $d eq 'west';
        $self->player->stop if $e->key_sym == SDLK_RIGHT && $d eq 'east';
        $self->player->stop if $e->key_sym == SDLK_DOWN  && $d eq 'south';
        $self->player->stop if $e->key_sym == SDLK_UP    && $d eq 'north';
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
        dt     => $dt
        player => $player_model,
        view   => $maze_view,
    );

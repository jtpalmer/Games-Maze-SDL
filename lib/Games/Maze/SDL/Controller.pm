package Games::Maze::SDL::Controller;

# ABSTRACT: Controller.

use Moose;
use MooseX::NonMoose::InsideOut;
use Games::Maze::SDL::Model;
use Games::Maze::SDL::View;
use SDL::Event;
use SDL::Events ':all';

extends 'SDLx::Controller';

has 'model' => (
    is       => 'ro',
    isa      => 'Games::Maze::SDL::Model',
    required => 1,
);

has 'view' => (
    is       => 'ro',
    isa      => 'Games::Maze::SDL::View',
    required => 1,
);

sub BUILD {
    my ($self) = @_;

    $self->add_event_handler( sub { $self->on_event(@_) } );
    $self->add_move_handler( sub  { $self->model->move_player(@_) } );
    $self->add_show_handler( sub  { $self->view->draw(@_) } );

    return $self;
}

sub on_event {
    my ( $self, $e ) = @_;

    return 0 if $e->type == SDL_QUIT;
    return 0 if $e->key_sym == SDLK_ESCAPE;

    if ( $e->type == SDL_KEYDOWN ) {
        $self->model->player_direction('west')  if $e->key_sym == SDLK_LEFT;
        $self->model->player_direction('east')  if $e->key_sym == SDLK_RIGHT;
        $self->model->player_direction('south') if $e->key_sym == SDLK_DOWN;
        $self->model->player_direction('north') if $e->key_sym == SDLK_UP;
    }
    elsif ( $e->type == SDL_KEYUP ) {
        $self->model->stop_player
            if $e->key_sym == SDLK_LEFT
                && $self->model->player_direction eq 'west';
        $self->model->stop_player
            if $e->key_sym == SDLK_RIGHT
                && $self->model->player_direction eq 'east';
        $self->model->stop_player
            if $e->key_sym == SDLK_DOWN
                && $self->model->player_direction eq 'south';
        $self->model->stop_player
            if $e->key_sym == SDLK_UP
                && $self->model->player_direction eq 'north';
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
        model => $model,
        view  => $view,
    );

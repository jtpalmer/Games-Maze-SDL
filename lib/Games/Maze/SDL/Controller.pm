package Games::Maze::SDL::Controller;
use strict;
use warnings;
use MooseX::InsideOut;
use MooseX::NonMoose::InsideOut;
use namespace::clean -except => 'meta';
use SDL 2.500;
use SDL::Event;
use SDL::Events qw(:all);

# ABSTRACT: Controller.

extends qw(SDLx::Controller);

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

    $self->add_move_handler( sub  {
            $self->model->{player}->apply_force;
            $self->model->{box2d}->step(@_);
        } );

    $self->add_show_handler( sub  { $self->view->{maze}->draw(@_) } );

    return $self;
}

sub on_event {
    my ( $self, $e ) = @_;

    $self->stop if $e->type == SDL_QUIT;
    $self->stop if $e->key_sym == SDLK_ESCAPE;

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

__PACKAGE__->meta->make_immutable;

1;

=pod

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

=cut


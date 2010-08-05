package Games::Maze::SDL::Controller;

# ABSTRACT: Controller.

use Moose;
use MooseX::NonMoose;
use Games::Maze::SDL::Model;
use Games::Maze::SDL::View;

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

sub init {
    my ($self) = @_;

    $self->add_event_handler( sub { $self->on_event(@_) } );
    $self->add_move_handler( sub  { $self->model->move_player(@_) } );
    $self->add_show_handler( sub  { $self->view->draw(@_) } );
}

sub on_event {
    my ($self, $e) = @_;

    return 0 if $e->type == SDL_QUIT;
    return 0 if $e->key_sym == SDLK_ESCAPE;

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

package Games::Maze::SDL::View::Maze;

# ABSTRACT: View.

use Moose;
use Games::Maze::SDL::Model::Maze;
use Games::Maze::SDL::View::Player;
use SDL::Rect;
use POSIX 'floor';

has 'model' => (
    is       => 'ro',
    isa      => 'Games::Maze::SDL::Model::Maze',
    required => 1,
);

has 'player' => (
    is       => 'ro',
    isa      => 'Games::Maze::SDL::View::Player',
    required => 1,
);

has 'width' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'height' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'player_old_rect' => (
    is         => 'rw',
    isa        => 'SDL::Rect',
    lazy_build => 1,
    init_arg   => undef,
);

has 'background_color' => (
    is      => 'ro',
    default => 0x000000,
);

has 'wall_color' => (
    is      => 'ro',
    default => sub { [ 255, 255, 255, 255 ] },
);

has 'exit_color' => (
    is      => 'ro',
    default => sub { [ 0, 255, 0, 255 ] },
);

has 'display' => (
    is         => 'ro',
    isa        => 'SDLx::Surface',
    lazy_build => 1,
    init_arg   => undef,
);

sub BUILD {
    my ($self) = @_;

    $self->draw_maze( $self->display );

    return $self;
}

sub _build_display {
    my ($self) = @_;

    return SDLx::Surface::display(
        width  => $self->width,
        height => $self->height,
    );
}

sub _build_player_old_rect {
    my ($self) = @_;
    my $rect = $self->player->rect;
    return SDL::Rect->new( $rect->x, $rect->y, $rect->w, $rect->h );
}

sub draw_cells {
    my ( $self, $display, $x_min, $y_min, $x_max, $y_max ) = @_;

    my $color = $self->wall_color;

    $y_min = 1                     if $y_min < 1;
    $x_min = 1                     if $x_min < 1;
    $y_max = $self->model->cells_y if $y_max > $self->model->cells_y;
    $x_max = $self->model->cells_x if $x_max > $self->model->cells_x;

    for my $y ( $y_min .. $y_max ) {

        my $y1 = $self->model->translate_y( $y - 0.5 );
        my $y2 = $self->model->translate_y( $y + 0.5 );

        for my $x ( $x_min .. $x_max ) {

            my $x1 = $self->model->translate_x( $x - 0.5 );
            my $x2 = $self->model->translate_x( $x + 0.5 );

            my $paths = $self->model->paths( $x, $y );

            $display->draw_line( [ $x2, $y1 ], [ $x2, $y2 ], $color )
                if !$paths->{east};

            $display->draw_line( [ $x1, $y2 ], [ $x2, $y2 ], $color )
                if !$paths->{south};
        }
    }
}

sub draw_maze {
    my ( $self, $display ) = @_;

    $self->draw_cells( $display, 1, 1, $self->model->cells_x,
        $self->model->cells_y );

    $display->draw_rect(
        [   $self->model->translate_x( $self->model->exit_x - 0.1 ),
            $self->model->translate_y( $self->model->exit_y - 0.1 ),
            $self->model->scale_x(0.2),
            $self->model->scale_y(0.2),
        ],
        $self->exit_color
    );
}

sub draw {
    my ( $self, $ticks ) = @_;

    $self->display->draw_rect( $self->player_old_rect,
        $self->background_color );
    $self->player->draw( $self->display );
    $self->player_old_rect->x( $self->player->rect->x );
    $self->player_old_rect->y( $self->player->rect->y );

    $self->display->update();

    return $self;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

    use Games::Maze::SDL::View::Maze;

    my $view = Games::Maze::SDL::View::Maze->new(
        model => $model,
    );

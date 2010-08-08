package Games::Maze::SDL::View;

# ABSTRACT: View.

use Moose;
use Games::Maze::SDL::Model;
use SDL::Rect;
use SDLx::Surface;
use SDLx::Sprite::Animated;
use POSIX 'floor';

has 'model' => (
    is       => 'ro',
    isa      => 'Games::Maze::SDL::Model',
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

has 'cell_width' => (
    is         => 'ro',
    isa        => 'Num',
    lazy_build => 1,
    init_arg   => undef,
);

has 'cell_height' => (
    is         => 'ro',
    isa        => 'Num',
    lazy_build => 1,
    init_arg   => undef,
);

has 'background_color' => (
    is      => 'ro',
    default => sub { [ 0, 0, 0, 255 ] },
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

has 'player' => (
    is         => 'ro',
    isa        => 'SDLx::Sprite::Animated',
    lazy_build => 1,
    init_arg   => undef,
);

has 'player_old_rect' => (
    is         => 'rw',
    isa        => 'SDL::Rect',
    lazy_build => 1,
    init_arg   => undef,
);

sub BUILD {
    my ($self) = @_;

    $self->model->add_observer( sub { $self->handle_event(@_) } );
    $self->player->x( $self->translate_player_x( $self->model->player_x ) );
    $self->player->y( $self->translate_player_y( $self->model->player_y ) );

    $self->clear;
    $self->draw_maze;

    return $self;
}

sub _build_display {
    my ($self) = @_;

    return SDLx::Surface::display(
        width  => $self->width,
        height => $self->height,
    );
}

sub _build_cell_width {
    my ($self) = @_;
    return $self->width / $self->model->width;
}

sub _build_cell_height {
    my ($self) = @_;
    return $self->height / $self->model->height;
}

sub _build_player {
    my ($self) = @_;

    my $sprite = SDLx::Sprite::Animated->new(
        image           => Games::Maze::SDL->sharedir->file('hero.png'),
        rect            => SDL::Rect->new( 0, 0, 48, 48 ),
        ticks_per_frame => 5,
        type            => 'reverse',
        sequences       => {
            'north' => [ [ 0, 1 ], [ 0, 2 ], [ 0, 0 ] ],
            'south' => [ [ 2, 1 ], [ 2, 2 ], [ 2, 0 ] ],
            'west'  => [ [ 3, 0 ], [ 3, 1 ], [ 3, 2 ] ],
            'east'  => [ [ 1, 0 ], [ 1, 1 ], [ 1, 2 ] ],
            'stop'  => [ [ 4, 0 ] ],
        },
    );

    $sprite->sequence( $self->model->player_direction );

    return $sprite;
}

sub _build_player_old_rect {
    my ($self) = @_;
    my $rect = $self->player->rect;
    return SDL::Rect->new( $rect->x, $rect->y, $rect->w, $rect->h );
}

sub scale_x {
    my ( $self, $x ) = @_;
    return $self->cell_width * $x;
}

sub scale_y {
    my ( $self, $y ) = @_;
    return $self->cell_height * $y;
}

sub translate_x {
    my ( $self, $x ) = @_;
    return $self->cell_width * ( $x - 1 ) + $self->cell_width / 2;
}

sub translate_y {
    my ( $self, $y ) = @_;
    return $self->cell_height * ( $y - 1 ) + $self->cell_height / 2;
}

sub translate_player_x {
    my ( $self, $x ) = @_;
    return $self->translate_x($x) - $self->player->clip->w / 2;
}

sub translate_player_y {
    my ( $self, $y ) = @_;
    return $self->translate_y($y) - $self->player->clip->h / 2;
}

sub clear {
    my ($self) = @_;
    $self->display->draw_rect( [ 0, 0, $self->width - 1, $self->height - 1 ],
        $self->background_color );
}

sub draw_cells {
    my ( $self, $x_range, $y_range ) = @_;

    my $color = $self->wall_color;

    $y_range->[0] = 1 if $y_range->[0] < 1;
    $x_range->[0] = 1 if $x_range->[0] < 1;
    $y_range->[1] = $self->model->height
        if $y_range->[0] > $self->model->height;
    $x_range->[1] = $self->model->width
        if $x_range->[0] > $self->model->width;

    for my $y ( $y_range->[0] .. $y_range->[1] ) {

        my $y1 = $self->translate_y( $y - 0.5 );
        my $y2 = $self->translate_y( $y + 0.5 );

        for my $x ( $x_range->[0] .. $x_range->[1] ) {

            my $x1 = $self->translate_x( $x - 0.5 );
            my $x2 = $self->translate_x( $x + 0.5 );

            my $paths = $self->model->paths( $x, $y );

            $self->display->draw_line( [ $x2, $y1 ], [ $x2, $y2 ], $color )
                if !$paths->{east};

            $self->display->draw_line( [ $x1, $y2 ], [ $x2, $y2 ], $color )
                if !$paths->{south};
        }
    }
}

sub draw_maze {
    my ($self) = @_;

    my $color = $self->wall_color;

    $self->display->draw_line( [ 0, 0 ], [ $self->width - 1, 0 ], $color );
    $self->display->draw_line( [ 0, 0 ], [ 0, $self->height - 1 ], $color );
    $self->display->draw_line( [ $self->width - 1, 0 ],
        [ $self->width - 1, $self->height - 1 ], $color );
    $self->display->draw_line( [ 0, $self->height - 1 ],
        [ $self->width - 1, $self->height - 1 ], $color );

    $self->draw_cells( [ 1, $self->model->width ],
        [ 1, $self->model->height ] );

    $self->display->draw_rect(
        [   $self->translate_x( $self->model->exit_x - 0.1 ),
            $self->translate_y( $self->model->exit_y - 0.1 ),
            $self->scale_x(0.2),
            $self->scale_y(0.2),
        ],
        $self->exit_color
    );
}

sub draw_player {
    my ($self) = @_;

    $self->display->draw_rect( $self->player_old_rect,
        $self->background_color );

    my $x = floor( $self->model->player_x + 0.5 );
    my $y = floor( $self->model->player_y + 0.5 );
    $self->draw_cells( [ $x - 1, $x + 1 ], [ $y - 1, $y + 1 ] );

    $self->player->draw( $self->display );

    my $rect     = $self->player->rect;
    my $old_rect = $self->player_old_rect;
    $old_rect->x( $rect->x );
    $old_rect->y( $rect->y );
}

sub draw {
    my ( $self, $ticks ) = @_;

    $self->draw_player;
    $self->display->update();

    return $self;
}

sub handle_event {
    my ( $self, $event ) = @_;

    if ( $event->{type} eq 'player_moved' ) {
        $self->player->x(
            $self->translate_player_x( $self->model->player_x ) );
        $self->player->y(
            $self->translate_player_y( $self->model->player_y ) );
    }
    elsif ( $event->{type} eq 'player_turned' ) {
        $self->player->sequence( $self->model->player_direction );
        $self->player->start;
    }
    elsif ( $event->{type} eq 'player_stopped' ) {
        $self->player->reset;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

    use Games::Maze::SDL::View;

    my $view = Games::Maze::SDL::View->new(
        model => $model,
    );

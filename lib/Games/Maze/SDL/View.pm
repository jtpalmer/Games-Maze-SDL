package Games::Maze::SDL::View;

# ABSTRACT: View.

use Moose;
use Games::Maze::SDL::Model;
use SDL::Rect;
use SDLx::Surface;
use SDLx::Sprite::Animated;

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
        ticks_per_frame => 10,
        sequences       => {
            'up'    => [ [ 0, 0 ], [ 0, 1 ], [ 0, 2 ] ],
            'down'  => [ [ 2, 0 ], [ 2, 1 ], [ 2, 2 ] ],
            'left'  => [ [ 3, 0 ], [ 3, 1 ], [ 3, 2 ] ],
            'right' => [ [ 1, 0 ], [ 1, 1 ], [ 1, 2 ] ],
        },
    );

    $sprite->sequence( $self->model->player_direction );

    return $sprite;
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

sub player_x {
    my ($self) = @_;
    return $self->translate_x( $self->model->player_x )
        - $self->player->clip->w / 2;
}

sub player_y {
    my ($self) = @_;
    return $self->translate_y( $self->model->player_y )
        - $self->player->clip->h / 2;
}

sub draw_maze {
    my ($self) = @_;

    my $color = [ 255, 255, 255, 255 ];

    $self->display->draw_line( [ 0, 0 ], [ $self->width - 1, 0 ], $color );
    $self->display->draw_line( [ 0, 0 ], [ 0, $self->height - 1 ], $color );
    $self->display->draw_line( [ $self->width - 1, 0 ],
        [ $self->width - 1, $self->height - 1 ], $color );
    $self->display->draw_line( [ 0, $self->height - 1 ],
        [ $self->width - 1, $self->height - 1 ], $color );

    for my $y ( 1 .. $self->model->height ) {

        my $y1 = $self->translate_y( $y - 0.5 );
        my $y2 = $self->translate_y( $y + 0.5 );

        for my $x ( 1 .. $self->model->width ) {

            my $x1 = $self->translate_x( $x - 0.5 );
            my $x2 = $self->translate_x( $x + 0.5 );

            my $paths = $self->model->paths( $x, $y );

            $self->display->draw_line( [ $x2, $y1 ], [ $x2, $y2 ], $color )
                if !$paths->{east};

            $self->display->draw_line( [ $x1, $y2 ], [ $x2, $y2 ], $color )
                if !$paths->{south};
        }
    }

    $self->display->draw_rect(
        [   $self->translate_x( $self->model->exit_x - 0.1 ),
            $self->translate_y( $self->model->exit_y - 0.1 ),
            $self->scale_x(0.2),
            $self->scale_y(0.2),
        ],
        [ 0, 255, 0, 255 ]
    );
}

sub draw {
    my ($self) = @_;

    $self->draw_maze;

    $self->player->draw_xy( $self->display, $self->player_x,
        $self->player_y );

    $self->display->update();
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
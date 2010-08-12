package Games::Maze::SDL;

# ABSTRACT: Maze game; using SDL!

use Moose;
use Games::Maze::SDL::Model::Maze;
use Games::Maze::SDL::Model::Player;
use Games::Maze::SDL::View::Maze;
use Games::Maze::SDL::View::Player;
use Games::Maze::SDL::Controller;
use FindBin;
use Path::Class;

sub run {
    my ( $self, %options ) = @_;

    my $width         = 640;
    my $height        = 480;
    my $cell_width    = 40;
    my $cell_height   = 40;
    my $player_width  = 24;
    my $player_height = 24;
    my $cells_x       = 15;
    my $cells_y       = 12;
    my $dt            = 25;

    my $maze_model = Games::Maze::SDL::Model::Maze->new(
        cells_x     => $cells_x,
        cells_y     => $cells_y,
        cell_width  => $cell_width,
        cell_height => $cell_height,
    );

    my $player_model = Games::Maze::SDL::Model::Player->new(
        maze   => $maze_model,
        width  => $player_width,
        height => $player_height,
    );

    my $player_view
        = Games::Maze::SDL::View::Player->new( model => $player_model, );

    my $maze_view = Games::Maze::SDL::View::Maze->new(
        model  => $maze_model,
        player => $player_view,
        width  => $width,
        height => $height,
    );

    my $controller = Games::Maze::SDL::Controller->new(
        dt     => $dt,
        player => $player_model,
        view   => $maze_view,
    );

    $controller->run;
}

sub sharedir {

    # TODO
    my $root = Path::Class::Dir->new( $FindBin::Bin, '..' );
    return $root->subdir('share');
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

    use Games::Maze::SDL;

    Games::Maze::SDL->play;

=head1 SEE ALSO

L<SDL>, L<Games::Maze>, L<Games::Maze::SVG>

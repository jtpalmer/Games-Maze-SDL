package Games::Maze::SDL;

# ABSTRACT: Maze game; using SDL!

use Moose;
use MooseX::ClassAttribute;
use Games::Maze::SDL::Model::Maze;
use Games::Maze::SDL::Model::Player;
use Games::Maze::SDL::View::Maze;
use Games::Maze::SDL::View::Player;
use Games::Maze::SDL::Controller;
use FindBin;
use Path::Class;
use File::ShareDir;

class_has 'share_dir' => (
    is         => 'ro',
    lazy_build => 1,
    init_arg   => undef,
);

sub _build_share_dir {
    my $root = Path::Class::Dir->new( $FindBin::Bin, '..' );
    if ( -f $root->file('dist.ini') ) {
        return $root->subdir('share');
    }
    else {
        return Path::Class::Dir->new(
            File::ShareDir::dist_dir('Games-Maze-SDL') );
    }
}

sub run {
    my ( $self, %options ) = @_;

    my $cells_x       = 16;
    my $cells_y       = 12;
    my $cell_width    = 40;
    my $cell_height   = 40;
    my $width         = $cell_width * $cells_x;
    my $height        = $cell_height * $cells_y;
    my $player_width  = 24;
    my $player_height = 24;
    my $dt            = 0.0025;

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
        = Games::Maze::SDL::View::Player->new( model => $player_model );

    my $maze_view = Games::Maze::SDL::View::Maze->new(
        model  => $maze_model,
        player => $player_view,
        width  => $width,
        height => $height,
    );

    my $controller = Games::Maze::SDL::Controller->new(
        dt    => $dt,
        model => {
            maze   => $maze_model,
            player => $player_model,
        },
        view => {
            maze   => $maze_view,
            player => $player_view,
        },
    );

    $controller->run;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

    use Games::Maze::SDL;

    Games::Maze::SDL->new->run( %options );

=head1 SEE ALSO

L<SDL>, L<Games::Maze>, L<Games::Maze::SVG>

package Games::Maze::SDL;

# ABSTRACT: Maze game; using SDL!

use Moose;
use Games::Maze::SDL::Model;
use Games::Maze::SDL::View;
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

    my $model = Games::Maze::SDL::Model->new(
        cells_x       => $cells_x,
        cells_y       => $cells_y,
        cell_width    => $cell_width,
        cell_height   => $cell_height,
        player_width  => $player_width,
        player_height => $player_height,
    );

    my $view = Games::Maze::SDL::View->new(
        model  => $model,
        width  => $width,
        height => $height,
    );

    my $controller = Games::Maze::SDL::Controller->new(
        dt    => $dt,
        model => $model,
        view  => $view,
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

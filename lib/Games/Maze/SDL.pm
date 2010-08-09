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

    my $width         = 1000;
    my $height        = 800;
    my $player_width  = 48;
    my $player_height = 48;
    my $cells_x       = 15;
    my $cells_y       = 12;
    my $dt            = 25;

    my $model = Games::Maze::SDL::Model->new(
        width         => $cells_x,
        height        => $cells_y,
        player_width  => $player_width / ( $width / $cells_x ),
        player_height => $player_height / ( $height / $cells_y ),
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

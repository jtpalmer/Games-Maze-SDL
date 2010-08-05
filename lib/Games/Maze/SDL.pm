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

    my $model = Games::Maze::SDL::Model->new(
        width  => 30,
        height => 20,
    );

    my $view = Games::Maze::SDL::View->new(
        model  => $model,
        width  => 600,
        height => 400,
    );

    my $controller = Games::Maze::SDL::Controller->new(
        model => $model,
        view  => $view,
    );

    $controller->run;
}

sub sharedir {
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

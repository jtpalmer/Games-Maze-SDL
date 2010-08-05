package Games::Maze::SDL;

# ABSTRACT: Maze game; using SDL!

use strict;
use warnings;

use Games::Maze::SDL::Model;
use Games::Maze::SDL::View;
use Games::Maze::SDL::Controller;

sub run {
    my (%options) = @_;

    my $model      = Games::Maze::SDL::Model->new();
    my $view       = Games::Maze::SDL::View->new( model => $model );
    my $controller = Games::Maze::SDL::Controller->new(
        model => $model,
        view  => $view,
    );
}

1;

__END__

=head1 SYNOPSIS

    use Games::Maze::SDL;

    Games::Maze::SDL->play;

=head1 SEE ALSO

L<SDL>, L<Games::Maze>, L<Games::Maze::SVG>

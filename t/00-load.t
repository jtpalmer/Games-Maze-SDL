#!perl
use strict;
use warnings;
use Test::More;

BEGIN {
    my @modules = qw(
        Games::Maze::SDL
        Games::Maze::SDL::Controller
        Games::Maze::SDL::Model::Box2D
        Games::Maze::SDL::Model::Maze
        Games::Maze::SDL::Model::Player
        Games::Maze::SDL::Role::Observable
        Games::Maze::SDL::Types
        Games::Maze::SDL::View::Maze
        Games::Maze::SDL::View::Player
    );

    for my $module (@modules) {
        use_ok($module) or BAIL_OUT("Failed to load $module");
    }
}

diag(
    sprintf(
        'Testing Games::Maze::SDL %f, Perl %f, %s',
        $Games::Maze::SDL::VERSION, $], $^X
    )
);

done_testing();


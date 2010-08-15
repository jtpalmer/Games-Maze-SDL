use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Games::Maze::SDL::Model::Player;

can_ok( 'Games::Maze::SDL::Model::Player',
    qw( new x y width height direction velocity max_velocity acceleration maze )
);

my $maze = Test::MockObject->new();
$maze->set_isa('Games::Maze::SDL::Model::Maze');

my $player = Games::Maze::SDL::Model::Player->new(
    maze   => $maze,
    width  => 24,
    height => 24,
);

is( $player->direction, 'south', 'player_direction is "south"' );

done_testing;

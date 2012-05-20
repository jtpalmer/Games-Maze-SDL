package Games::Maze::SDL::Model::Player;
use strict;
use warnings;
use Moose;
use namespace::clean -except => 'meta';
use Games::Maze::SDL::Types;
use Games::Maze::SDL::Role::Observable;
use Games::Maze::SDL::Model::Maze;
use POSIX qw(floor);

# ABSTRACT: Player model.

with qw(Games::Maze::SDL::Role::Observable);

has 'maze' => (
    is       => 'rw',
    isa      => 'Games::Maze::SDL::Model::Maze',
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

has 'box2d' => (
    is       => 'ro',
    isa      => 'Games::Maze::SDL::Model::Box2D',
    required => 1,
);

has 'body' => (
    is       => 'rw',
    isa      => 'Box2D::b2Body',
    builder  => '_build_body',
    lazy     => 1,
    init_arg => undef,
);

has 'direction' => (
    is      => 'rw',
    isa     => 'Games::Maze::SDL::Direction',
    default => 'south',
);

has 'force' => (
    is      => 'rw',
    isa     => 'Box2D::b2Vec2',
    default => sub { Box2D::b2Vec2->new( 0.0, 0.0 ) },
);

has 'max_velocity' => (
    is      => 'ro',
    isa     => 'Num',
    default => 0.25,
);

sub _build_body {
    my ($self) = @_;

    my $x = $self->maze->translate_x( $self->maze->entry_x ) - $self->w / 2;
    my $y = $self->maze->translate_y( $self->maze->entry_y ) - $self->h / 2;

    return $self->box2d->create_dynamic(
        {   x => $x,
            y => $y,
            w => $self->w,
            h => $self->h,
        }
    );
}

sub x {
    my ($self) = @_;
    return $self->body->GetPosition->x - $self->w / 2;
}

sub y {
    my ($self) = @_;
    return $self->body->GetPosition->y - $self->h / 2;
}

sub v_x {
    my ($self) = @_;
    return $self->body->GetLinearVelocity->x;
}

sub v_y {
    my ($self) = @_;
    return $self->body->GetLinearVelocity->y;
}

sub w {
    my ($self) = @_;
    return $self->width;
}

sub h {
    my ($self) = @_;
    return $self->height;
}

after 'direction' => sub {
    my $self = shift;

    if (@_) {
        $self->changed(1);
    }
};

after 'direction' => sub {
    my $self = shift;

    if (@_) {
        my $d = shift;
        if ( $d eq 'north' ) {
            $self->set_force( 0.0, -1.0 );
        }
        if ( $d eq 'south' ) {
            $self->set_force( 0.0, 1.0 );
        }
        if ( $d eq 'west' ) {
            $self->set_force( -1.0, 0.0 );
        }
        if ( $d eq 'east' ) {
            $self->set_force( 1.0, 0.0 );
        }

        $self->notify_observers( { type => 'turned' } );
    }
};

sub set_force {
    my ( $self, $x, $y ) = @_;
    $self->force( Box2D::b2Vec2->new( $x * 10, $y * 10 ) );
}

sub apply_force {
    my ($self) = @_;

    my $fx    = $self->force->x - $self->v_x * 1.5;
    my $fy    = $self->force->y - $self->v_y * 1.5;
    my $force = Box2D::b2Vec2->new( $fx, $fy );
    $self->body->ApplyLinearImpulse( $force, $self->body->GetWorldCenter );
}

sub velocity {
    my ($self) = @_;

    my $vx = $self->v_x;
    my $vy = $self->v_y;

    return sqrt( $vx * $vx + $vy * $vy );
}

sub stop {
    my ($self) = @_;
    $self->set_force( 0.0, 0.0 );
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=head1 SYNOPSIS

    use Games::Maze::SDL::Model::Player;

    my $model = Games::Maze::SDL::Model::Player->new(
        width  => $width,
        height => $height,
        maze   => $maze,
    );

=cut


package Games::Maze::SDL::Model::Box2D;

# ABSTRACT: Box2D model.

use Moose;
use Box2D;

has _world => (
    is      => 'ro',
    isa     => 'Box2D::b2World',
    lazy    => 1,
    builder => '_build_world',
);

has _gravity => (
    is      => 'ro',
    isa     => 'Box2D::b2Vec2',
    lazy    => 1,
    default => sub { Box2D::b2Vec2->new( 0.0, 0.0 ) },
);

has _time_step => (
    is      => 'ro',
    isa     => 'Num',
    default => 1.0 / 60.0,
);

has _velocity_iters => (
    is      => 'ro',
    isa     => 'Int',
    default => 6,
);

has _position_iters => (
    is      => 'ro',
    isa     => 'Int',
    default => 2,
);

sub BUILD {
    my ($self) = @_;

}

sub _build_world {
    my ($self) = @_;
    return Box2D::b2World->new( $self->_gravity, 0 );
}

sub step {
    my ($self) = @_;
    $self->_world->Step( $self->_time_step, $self->_velocity_iters,
        $self->_position_iters );
    $self->_world->ClearForces();
}

sub create_static {
    my ( $self, $static ) = @_;

    my $hx = $static->{w} / 2.0;
    my $hy = $static->{h} / 2.0;

    my $body_def = Box2D::b2BodyDef->new();
    $body_def->position->Set( $static->{x} + $hx, $static->{y} + $hy );
    my $body = $self->_world->CreateBody($body_def);

    my $shape = Box2D::b2PolygonShape->new();
    $shape->SetAsBox( $hx, $hy );
    $body->CreateFixture( $shape, 0.0 );

    return $body;
}

sub create_dynamic {
    my ( $self, $dynamic ) = @_;

    my $hx = $dynamic->{w} / 2.0;
    my $hy = $dynamic->{h} / 2.0;

    my $body_def = Box2D::b2BodyDef->new();
    $body_def->type(Box2D::b2_dynamicBody);
    $body_def->position->Set( $dynamic->{x} + $hx, $dynamic->{y} + $hy );
    my $body = $self->_world->CreateBody($body_def);

    my $shape = Box2D::b2PolygonShape->new();
    $shape->SetAsBox( $hx, $hy );

    my $fixture_def = Box2D::b2FixtureDef->new();
    $fixture_def->shape($shape);
    $fixture_def->density(1.0);
    $fixture_def->friction(0.3);
    $fixture_def->restitution(0.5);
    $body->CreateFixtureDef($fixture_def);

    return $body;
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;

__END__

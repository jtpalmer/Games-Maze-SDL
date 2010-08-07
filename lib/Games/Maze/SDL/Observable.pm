package Games::Maze::SDL::Observable;

# ABSTRACT: Observable role.

use Moose::Role;

has 'observers' => (
    is      => 'rw',
    isa     => 'ArrayRef[CodeRef]',
    default => sub { [] },
);

has 'changed' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

sub add_observer {
    my ( $self, $observer ) = @_;
    push @{ $self->observers }, $observer;
}

sub remove_observer {
    my ( $self, $observer ) = @_;
    my @observers = @{ $self->observers };
    $self->observers = [ @observers[ grep { $observers[$_] != $observer }
            ( 0 .. @observers - 1 ) ] ];
}

sub remove_observers {
    my ($self) = @_;
    $self->observers = [];
}

sub notify_observers {
    my ( $self, @args ) = @_;
    return if !$self->changed;
    $_->(@args) foreach @{ $self->observers };
    $self->changed(0);
}

1;

__END__

package Devel::CallerStack;
use strict;
use warnings;

use Devel::CallerStack::Level;
use base 'Exporter';
use Carp;

our $VERSION = '0.003';
our @EXPORT_OK = qw/ caller_stack /;

sub caller_stack { __PACKAGE__->new( 4 )}

sub new {
    my $class = shift;
    my ( $depth ) = @_;
    my $self = bless( [[], undef, 0], $class );
    $self->_build($depth || 3);
    return $self;
}

sub _build {
    my $self = shift;
    my ($depth) = @_;
    while ( my $level = Devel::CallerStack::Level->new( $depth++ )) {
        next if $level->package->isa( __PACKAGE__ );
        push @{ $self->all } => $level;
    }
    return $self;
}

sub _index { \shift->[2] }
sub index { ${ shift->_index }}

sub all { shift->[0] }
sub all_list { @{ shift->all }}

sub _filtered {
    my $self = shift;
    ($self->[1]) = @_ if @_;
    return $self->[1];
}
sub filtered {
    my $self = shift;
    return $self->_filtered( @_ ) || $self->all;
}
sub filtered_list { @{ shift->filtered }}
sub is_filtered { shift->_filtered ? 1 : 0 }

sub unfilter {
    my $self = shift;
    $self->_filtered( undef );
    return $self;
}

sub element {
    my $self = shift;
    my ( $i ) = @_;
    return $self->filtered->[$i];
}

sub recent_package_caller {
    my $self = shift;
    my ( $package ) = @_;
    croak "You must specify a package name" unless $package;
    for my $level ( @{ $self->filtered }) {
        return $level if $level->package( $package );
    }
    return undef;
}

sub distant_package_caller {
    my $self = shift;
    my ( $package ) = @_;
    croak "You must specify a package name" unless $package;
    for my $level ( reverse @{ $self->filtered }) {
        return $level if $level->package( $package );
    }
    return undef;
}

sub package_callers {
    my $self = shift;
    my ( $package ) = @_;
    croak "You must specify a package name" unless $package;

    my @out;
    for my $level ( @{ $self->filtered }) {
        push @out => $level if $level->package( $package );
    }

    return @out;
}

sub filter {
    my $self = shift;
    $self->reset;
    my ( $attr, $check ) = @_;
    my @list =  grep { $_->$attr( $check )} @{ $self->filtered };

    my $want = wantarray;

    return @list if $want;

    $self->filtered( \@list );

    return $self;
}

sub attribute_stack {
    my $self = shift;
    my ( $attribute ) = @_;
    return [ map { $_->$attribute } @{ $self->filtered }];
}

sub recent {
    my $self = shift;
    return $self->filtered->[0];
}

sub distant {
    my $self = shift;
    return $self->filtered->[-1];
}

sub next {
    my $self = shift;
    my $idx = $self->_index;
    return if $$idx >= @{ $self->filtered };
    return $self->filtered->[$$idx++];
}

sub previous {
    my $self = shift;
    my $idx = $self->_index;
    return if $$idx < 1;
    return $self->filtered->[--$$idx];
}

sub reset {
    my $self = shift;
    ${ $self->_index } = 0;
}

1;

__END__

=pod

=head1 NAME

Devel::CallerStack - Object-Oriented call stack and iterator.

=head1 DESCRIPION

Devel-CallerStack is an object-oriented interface to the call stack. When
constructed it will build a callstack and provide you access and filtration
methods. Each element of the stack is an instance of
L<Devel::CallerStack::Level>.

=head1 SYNOPSIS

    use Devel::CallerStack qw/caller_stack/;

    my $stack = Devel::CallerStack->new();
    # or
    my $stack = caller_stack();

    # Get all callers
    my @callers = $stack->all_list();

    # Limit to specific callers:
    $stack->filter( 'line', 100 );
    $stack->filter( 'subroutine', qr/mysub$/ );
    $stack->filter( 'package', 'My::Package' );

    my @specific_callers = $stack->filtered_list()

    # As an iterator

    while ( my $level = $stack->next ) {
        ...
    }

    1;

=head1 EXPORTS

Nothing is exported by default. However caller_stack() can be imported.

=over 4

=item $stack = caller_stack()

Shortcut for Devel::CallerStack->new();

=back

=head1 CONSTRUCTOR

=over 4

=item $stack = Devel::CallerStack->new()

Builds a new caller stack.

=back

=head1 OBJECT METHODS

=head2 COMPLETE CALLER STACK

The following will always return the complete unfiltered caller stack.

=over 4

=item $arrayref = $stack->all()

Return a reference to the actual array of caller levels. Each item will be an
instance of L<Devel::CallerStack::Level>.

=item @list = $stack->all_list()

Return a list of caller levels. Each item will be an instance of
L<Devel::CallerStack::Level>.

=back

=head2 FILTERING RESULTS

You can apply filters that will remove any levels from the stack that do not
match given check against it's attributes. You can apply multiple filters, each
will filter the remaining results from the previous filter.

=over 4

=item $stack->filter( $attribute, $check )

=item @list = $stack->filter( $attribute, $check )

Filter the stack so that only levels where the given attribute matches the
given check will be listed. $attribute should be the name of a caller attribute
(See L<Devel::CallerStack::Level>). $check may be a string against which to
compare, a regex, or a coderef.

B<NOTE:> When called in list context it will return the filtered results, but
will not modify the object in any way. In any other context the filter will be
applied to the object itself.

filter() returns $self in scalar context making the call chainable.

Filter out any levels where the package is not an instance of
'Wanted::Package':

    $stack->filter( 'package', sub {
        my $package = shift;
        $package->isa( 'Wanted::Package' );
    });

=item $arrayref = $stack->filtered()

Get a reference to the actual list of callers remaining after filters have been
applied. Each element is an instance of L<Devel::CallerStack::Level>.

=item @list = $stack->filtered_list()

Get a list of callers remaining after filters have been applied. Each element
is an instance of L<Devel::CallerStack::Level>.

=item $bool = $stack->is_filtered()

Returns true if filters have been applied

=item $stack->unfilter()

Removes all filters. unfilter() returns $self in scalar context making the call
chainable.

=back

=head2 ELEMENT ACCESS

=over 4

=item $level = $stack->element( $idx )

=item $arrayref = $stack->attribute_stack( $attribute )

Return an arrayref containing $attribute from each stack element.

=back

=head2 ITERATION

The caller stack is an array of L<Devel::CallerStack::Level> items progressing
from the most recent caller to the most distant.

=over 4

=item $level = $stack->recent()

Return the most recent caller.

=item $level = $stack->next()

Returns the next most recent caller, and increments the index. Returns undef at
the end of the stack.

=item $level = $stack->previous()

The reverse of next, used to go backwords.

=item $level = $stack->distant()

Return the most distant caller.

=item $level = $stack->index()

Returns the index of the iterator

=item $stack->reset()

Resets the iterator to index 0.

=back

=head2 PACKAGE SHORTCUTS

=over 4

=item $level = $stack->recent_package_caller( $package )

Return the most recent call from the specified package.

=item $level = distant_package_caller( $package )

Return the most distant call from the specified package.

=item @list = package_callers( $package )

Return all the calls from a given package.

=back

=head1 FENNEC PROJECT

This module is part of the Fennec project. See L<Fennec> for more details.
Fennec is a project to develop an extendable and powerful testing framework.
Together the tools that make up the Fennec framework provide a potent testing
environment.

The tools provided by Fennec are also useful on their own. Sometimes a tool
created for Fennec is useful outside the greator framework. Such tools are
turned into their own projects. This is one such project.

=over 2

=item L<Fennec> - The core framework

The primary Fennec project that ties them all together.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Devel-CallerStack is free software; Standard perl licence.

Devel-CallerStack is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the license for more details.

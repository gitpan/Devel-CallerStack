package Devel::CallerStack::Level;
use strict;
use warnings;
use Carp;

our @CARP_NOT = ( __PACKAGE__ );

our @ACCESSORS = qw/package filename line subroutine hasargs wantarray evaltext
                    is_require hints bitmask hinthash args/;

sub new {
    my $class = shift;
    my ( $depth ) = @_;
    my $self = bless( [], $class );
    package DB;
    my @caller = caller( $depth );
    return unless @caller;
    push @caller => undef unless @caller > 10;
    @$self = ( @caller, [@DB::args] );
    return $self;
}

{
    my $i = 0;
    for my $accessor ( @ACCESSORS ) {
        my $idx = $i++;
        my $sub = sub {
            my $self = shift;
            for my $check ( @_ ) {
                return unless $self->_check( $idx, $check );
            }
            return $self->[$idx];
        };
        no strict 'refs';
        *$accessor = $sub;
    }
}

sub _check {
    my $self = shift;
    my ( $idx, $check ) = @_;
    my $data = $self->[$idx];
    if( !ref( $check )) {
        return $data == $check if "$data$check" =~ m/^[\d\.e\-]+$/i;
        return "$data" eq "$check";
    }
    elsif (ref($check) eq 'Regexp') {
        return $data =~ $check ? 1 : 0;
    }
    elsif ( ref($check) eq 'CODE' ) {
        return $check->( $data );
    }
    else {
        croak( "Invalid check: $check" );
    }
}

sub check_ordered {
    my $self = shift;
    my $i = 0;
    for my $check ( @_ ) {
        next unless $self->_check( $i++, $check );
        return unless wantarray;
        return ( 0, $ACCESSORS[$i], $i );
    }
    return 1;
}

1;

__END__

=head1 NAME

Devel::CallerStack::Level - Element in a CallerStack, represents a single caller level.

=head1 SYNOPSIS

    my $level = Devel::CallerStack::Level->new( $depth );

    my $package = $caller->package;

    if ( $caller->package( $check )) {
        ...
    }

=head1 CONSTRUCTOR

=over 4

=item $level = Devel::CallerStack::Level->new( $depth )

Create a n instance representing the caller at $depth.

=back

=head1 ACCESSOR-CHECKERS

Accessors are read only. When called without an argument the value will be
returned. If there is an argument it will be treated as a check and return true
or false. A check can be a scalar, a regex, or a coderef. In the case of a
coderef, the value will be passed in as the only argument.

=over 4

=item $level->package()

=item $level->filename()

=item $level->line()

=item $level->subroutine()

=item $level->hasargs()

=item $level->wantarray()

=item $level->evaltext()

=item $level->is_require()

=item $level->hints()

=item $level->bitmask()

=item $level->hinthash()

=item @list = $level->args()

The list of args is not to be trusted. See
L<http://perldoc.perl.org/functions/caller.html> for caveats of caller args.

=back

=head1 EXTENDED CHECK

=over 4

=item $bool = $level->check_ordered( @checks )

Check each attribute in order against the check at the same index, undefinded
indexes in @check will not be checked. True if all checks are true.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Devel-CallerStack is free software; Standard perl licence.

Devel-CallerStack is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the license for more details.

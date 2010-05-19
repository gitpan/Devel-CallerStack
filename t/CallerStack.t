#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( 'Devel::CallerStack::Level' );
    use_ok( 'Devel::CallerStack', 'caller_stack' );
}

sub with_depth {
    my ( $depth ) = @_;
    return with_depth( --$depth ) if $depth > 1;
    return caller_stack;
}

my $stack = with_depth(5);
is( $stack->all_list, 5, "Depth of stack" );
ok( $stack->recent->line( 13 ), "Most recent caller was line 13" );
ok( $stack->distant->line( 17 ), "Most distant caller was line 17" );

my $i = 1;
while ( my $level = $stack->next ) {
    is( $level->args->[0], $i, "Proper arg looking back to depth $i" );
    die("loop getting to high") if $i > 5;
    $i++;
}
ok( !$stack->next, "End of iterator" );

$i--;
while ( my $level = $stack->previous ) {
    is( $level->args->[0], $i, "Proper arg going backwords - $i" );
    die("loop getting too low") if $i < 0;
    $i--;
}
ok( !$stack->previous, "Start of iterator" );

$stack->next for 1 .. 10;
is( $stack->index, 5, "Iterator maxed out" );
$stack->reset;
is( $stack->index, 0, "Iterator reset" );

ok( !$stack->is_filtered, "List is not filtered" );
$stack->filter( 'line', 17 );
is( $stack->filtered_list, 1, "Filtered to 1 by scalar" );
ok( $stack->is_filtered, "List is filtered" );

$stack->unfilter;
ok( !$stack->is_filtered, "List is not filtered" );
is( $stack->filtered_list, 5, "unfiltered results" );

ok( !$stack->is_filtered, "List is not filtered" );
$stack->filter( 'line', qr/^13$/ );
is( $stack->filtered_list, 4, "Filtered to 4 by regex" );
ok( $stack->is_filtered, "List is filtered" );

$stack->unfilter;
ok( !$stack->is_filtered, "List is not filtered" );
is( $stack->filtered_list, 5, "unfiltered results" );

ok( !$stack->is_filtered, "List is not filtered" );
$stack->filter( 'line', sub { $_[0] == 13 });
is( $stack->filtered_list, 4, "Filtered to 4 by coderef" );
ok( $stack->is_filtered, "List is filtered" );

$stack->unfilter;
ok( !$stack->is_filtered, "List is not filtered" );
is( $stack->filtered_list, 5, "unfiltered results" );

my $ref = [ $stack->filter( 'line', 13 )];
is( @$ref, 4, "Filtered to 4 in list context" );
ok( !$stack->is_filtered, "List is not filtered perminantly" );
is( $stack->filtered_list, 5, "unfiltered results" );

is( $stack->element(1), $stack->[0]->[1], "Access by element" );

is_deeply(
    $stack->attribute_stack( 'line' ),
    [ 13, 13, 13, 13, 17 ],
    "Get attribute stack"
);

{
    package AAAA;
    sub go { AAAA::go2() }
    sub go2 { BBBB::go() }
    package BBBB;
    sub go { BBBB::go2() }
    sub go2 { Devel::CallerStack->new }
}

$stack = AAAA::go();

my $level1 = $stack->recent_package_caller( 'AAAA' );
is( $level1->line, 86, "Got most recent package caller" );

my $level2 = $stack->distant_package_caller( 'AAAA' );
is( $level2->line, 85, "Got most distant package caller" );

is_deeply(
    [$stack->package_callers( 'AAAA' )],
    [ $level1, $level2 ],
    "Filtered by package"
);

done_testing;

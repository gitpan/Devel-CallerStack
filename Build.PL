#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Devel::CallerStack',
    license     => 'perl',
    dist_author => 'Chad Granum <exodist7@gmail.com>',
    create_readme => 1,
    build_requires => {
        'Test::More' => 0,
    },
    meta_merge => {
        resources => {
            repository  => 'http://github.com/exodist/Devel-CallerStack',
            bugtracker  => 'http://github.com/exodist/Devel-CallerStack/issues',
        },
    }
);

$build->create_build_script;

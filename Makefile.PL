use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME        => 'urlicious',
    VERSION     => '0.2',
    AUTHOR      => 'Mirko Westermeier <mail@memowe.de>',
    PREREQ_PM   => {'Mojolicious' => '2.0'},
    LICENSE     => 'MIT-LICENSE',
    test        => {TESTS => 't/*.t'}
);

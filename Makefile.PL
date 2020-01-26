use 5.010000;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'Kelp::Module::Symbiosis',
	VERSION_FROM => 'lib/Kelp/Module/Symbiosis.pm',
	MIN_PERL_VERSION => '5.010',

	PREREQ_PM => {
		'Kelp' => '>= 1',
		'Plack' => '>= 1',
	},

	META_MERGE => {
		resources => {
			license => 'https://dev.perl.org/licenses',
			# homepage => 'https://metacpan.org/release/Kelp-Module-Symbiosis',
			bugtracker => 'https://github.com/brtastic/perl-kelp-module-symbiosis/issues',
			repository => 'https://github.com/brtastic/perl-kelp-module-symbiosis',
		},
	},

	ABSTRACT_FROM => 'lib/Kelp/Module/Symbiosis.pm',
	AUTHOR => 'Bartosz Jarzyna <brtastic.dev@gmail.com>',
	LICENSE => 'perl',
);

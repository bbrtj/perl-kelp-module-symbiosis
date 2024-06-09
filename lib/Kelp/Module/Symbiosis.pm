package Kelp::Module::Symbiosis;

use Kelp::Base qw(Kelp::Module);
use KelpX::Symbiosis::Adapter;

attr adapter => sub { KelpX::Symbiosis::Adapter->new(app => $_[0]->app, engine => 'URLMap') };

sub build
{
	my ($self, %args) = @_;

	$self->adapter->build(%args);

	$self->register(
		symbiosis => $self->adapter,
		run_all => sub { shift->symbiosis->run(@_); },
	);

}

1;
__END__

=head1 NAME

Kelp::Module::Symbiosis - Manage an entire ecosystem of Plack organisms under Kelp

=head1 SYNOPSIS

	# in configuration file
	modules => [qw/Symbiosis SomeSymbioticModule/],
	modules_init => {
		Symbiosis => {
			mount => '/kelp', # a path to mount Kelp main instance
		},
		SomeSymbioticModule => {
			mount => '/elsewhere', # a path to mount SomeSymbioticModule
		},
	},

	# in kelp application - can be skipped if all mount paths are specified in config above
	my $symbiosis = $kelp->symbiosis;
	$symbiosis->mount('/app-path' => $kelp);
	$symbiosis->mount('/other-path' => $kelp->module_method);
	$symbiosis->mount('/other-path' => 'module_name'); # alternative - finds a module by name

	# in psgi script
	my $app = KelpApp->new();
	$app->run_all; # instead of run

=head1 DESCRIPTION

This module is an attempt to standardize the way many standalone Plack applications should be ran alongside the Kelp framework. The intended use is to introduce new "organisms" into symbiotic interaction by creating Kelp modules that are then attached onto Kelp. Then, the added method I<run_all> should be invoked in place of Kelp's I<run>, which will construct a L<Plack::App::URLMap> and return it as an application.

=head2 Why not just use Plack::Builder in a .psgi script?

One reason is not to put too much logic into .psgi script. It my opinion a framework should be capable enough not to make adding an additional application feel like a hack. This is of course subjective.

The main functional reason to use this module is the ability to access the Kelp application instance inside another Plack application. If that application is configurable, it can be configured to call Kelp methods. This way, Kelp can become a glue for multiple standalone Plack applications, the central point of a Plack mixture:

	# in Symbiont's Kelp module (extends Kelp::Module::Symbiosis::Base)

	sub psgi {
		my ($self) = @_;

		my $app = Some::Plack::App->new(
			on_something => sub {
				my $kelp = $self->app; # we can access Kelp!
				$kelp->something_happened;
			},
		);

		return $app->to_app;
	}

	# in Kelp application class

	sub something_happened {
		... # handle another app's signal
	}

=head2 What can be mounted?

The sole requirement for a module to be mounted into Symbiosis is its ability to I<run()>, returning the psgi application. A module also needs to be a blessed reference, of course. Fun fact: Symbiosis module itself meets that requirements, so one symbiotic app can be mounted inside another.

It can also be just a plain psgi app, which happens to be a code reference.

Whichever it is, it should be a psgi application ready to be ran by the server, wrapped in all the needed middlewares. This is made easier with L<Kelp::Module::Symbiosis::Base>, which allows you to add symbionts in the configuration for Kelp along with the middlewares. Because of this, this should be a preferred way of defining symbionts.

For very simple use cases, this will work though:

	# in application build method
	my $some_app = SomePlackApp->new->to_app;
	$self->symbiosis->mount('/path', $some_app);

=head1 METHODS

=head2 mount

	sig: mount($self, $path, $app)

Adds a new $app to the ecosystem under $path. I<$app> can be:

=over

=item

A blessed reference - will try to call run on it

=item

A code reference - will try calling it

=item

A string - will try finding a symbiotic module with that name and mounting it. See L<Kelp::Module::Symbiosis::Base/name>

=back

=head2 run

Constructs and returns a new L<Plack::App::URLMap> with all the mounted modules and Kelp itself.

Note: it will not run mounted object twice. This means that it is safe to mount something in two paths at once, and it will just be an alias to the same application.

=head2 mounted

	sig: mounted($self)

Returns a hashref containing a list of mounted modules, keyed by their specified mount paths.

=head2 loaded

	sig: loaded($self)

I<new in 1.10>

Returns a hashref containing a list of loaded modules, keyed by their names.

A module is loaded once it is added to Kelp configuration. This can be used to access a module that does not introduce new methods to Kelp.

=head1 METHODS INTRODUCED TO KELP

=head2 symbiosis

Returns an instance of this class.

=head2 run_all

Shortcut method, same as C<< $kelp->symbiosis->run() >>.

=head1 CONFIGURATION

	# Symbiosis MUST be specified as the first one
	modules => [qw/Symbiosis Module::Some/],
	modules_init => {
		Symbiosis => {
			mount => '/kelp',
		},
		'Module::Some' => {
			mount => '/some',
			...
		},
	}

Symbiosis should be the first of the symbiotic modules specified in your Kelp configuration. Failure to meet this requirement will cause your application to crash immediately.

=head2 mount

I<new in 1.10>

A path to mount the Kelp instance, which defaults to I<'/'>. Specify a string if you wish a to use different path. Specify an I<undef> or empty string to avoid mounting at all - you will have to run something like C<< $kelp->symbiosis->mount($mount_path, $kelp); >> in Kelp's I<build> method.

=head2 reverse_proxy

I<new in 1.11>

A boolean flag (I<1/0>) which enables reverse proxy for all the Plack apps at once. Requires L<Plack::Middleware::ReverseProxy> to be installed.

=head2 middleware, middleware_init

I<new in 1.12>

Middleware specs for the entire ecosystem. Every application mounted in Symbiosis will be wrapped in these middleware. They are configured exactly the same as middlewares in Kelp. Regular Kelp middleware will be used just for the Kelp application, so if you want to wrap all symbionts at once, this is the place to do it.

=head1 CAVEATS

Routes specified in symbiosis will be matched before routes in Kelp. Once you mount something under I</api> for example, you will no longer be able to specify Kelp route for anything under I</api>.

=head1 SEE ALSO

=over 2

=item * L<Kelp::Module::Symbiosis::Base>, a base for symbiotic modules

=item * L<Kelp::Module::WebSocket::AnyEvent>, a reference symbiotic module

=item * L<Plack::App::URLMap>, Plack URL mapper application

=back

=head1 AUTHOR

Bartosz Jarzyna, E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 - 2022 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut


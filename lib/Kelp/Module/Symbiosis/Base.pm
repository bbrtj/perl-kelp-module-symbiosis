package Kelp::Module::Symbiosis::Base;

use Kelp::Base qw(Kelp::Module);
use Plack::Util;

attr "-path";
attr "-middleware" => sub { [] };

sub attach
{
	my ($self, $auto) = @_;

	die "error attaching to ecosystem, Kelp cannot mount()"
		unless $self->app->can("mount");

	return $self->app->mount($self->path, $self, $auto // 0);
}

sub run
{
	my ($self) = shift;

	my $app = $self->psgi(@_);
	for (@{$self->middleware}) {
		my ($class, $args) = @$_;
		# Same middleware loading as Kelp
		next if $self->{_loaded_middleware}->{$class}++ && !$ENV{KELP_TESTING};

		my $mw = Plack::Util::load_class($class, "Plack::Middleware");
		$app = $mw->wrap($app, %{$args // {}});
	}
	return $app;
}

sub psgi
{
	die "psgi needs to be reimplemented";
}

sub build
{
	my ($self, %args) = @_;

	$self->{path} = $args{path} // $self->path;
	my $middleware = $self->middleware;
	foreach my $mw (@{$args{middleware}}) {
		my $config = $args{middleware_init}{$mw};
		push @$middleware, [$mw, $config];
	}

	$self->attach(1);
}

1;
__END__

=head1 NAME

Kelp::Module::Symbiosis::Base - base class for symbiotic modules

=head1 SYNOPSIS

	package Kelp::Module::MyModule;

	use Kelp::Base qw(Kelp::Module::Symbiosis::Base);

	sub psgi
	{
		# write code that returns psgi application without middlewares
	}

	sub build
	{
		my ($self, %args) = @_;
		$self->SUPER::build(%args);

		# write initialization code as usual
	}

=head1 DESCRIPTION

This module serves as a base for a Kelp module that is supposed to be ran as a standalone Plack application (mounted separately). It takes care of middleware management, mounting into Symbiosis manager and some basic initialization chores. To write a new module that introduces a standalone Plack application as a Kelp module, simply extend this class and override I<psgi> and I<build> methods.

=head1 METHODS

=head2 attach

	sig: attach($self, $auto = 0)

Attaches itself into Symbiosis ecosystem using configuration data. $auto flag is used for auto attaching during module building (controlled by Symbiosis configuration)

=head2 run

	sig: run($self)

Calls I<psgi()> and wraps its contents in middlewares. Returns a Plack application.

=head2 psgi

	sig: psgi($self, @more_data)

By default, this method will throw an exception. It has to be replaced with an actual application producing code in the child class. The resulting application will be wrapped in middlewares from config in I<run()>.

=head2 build

	sig: build($self, %args)

Standard Kelp module building method. When reimplementing it's best to call parent's implementation, as configuration initialization and application attaching happens in base implementation.

=head2 path

	sig: path($self)

Returns mounting URL path for this application, as specified in config. In child class implementation this can be reimplemented to have a default value like so:

	attr "path" => "/other_app";

=head2 middleware

	sig: middleware($self)

Returns an array containing all the middlewares in format: C<[ middleware_class, { middleware_config } ]>. By default, this config comes from module configuration.

=head1 CONFIGURATION

In configuration, a symbiotic module should be specified after I<Symbiosis> to be able to attach itself automatically. Module will complain with exception if it can't find I<mount()> method inside Kelp, but that method does not have to come from Symbiosis.

example configuration could look like this (for L<Kelp::Module::WebSocket>)

	modules => [qw/Symbiosis WebSocket/],
	modules_init => {
		Symbiosis => {
			kelp_path => '/website',
		},
		WebSocket => {
			path => '/stream',
			middleware => [qw/Recorder/],
			middleware_init => {
				Recorder => { output => "~/recorder.out" },
			}
		},
	}

=head2 path

Mounting point for the application instance.

=head2 middleware, middleware_init

Middleware specs for this application. Every module basing on this class can specify its own set of middlewares. They are configured exactly the same as middlewares in Kelp. There's currently no standarized way to retrieve middleware configurations from Kelp into another application, so custom code is needed if such need arise.

=head1 SEE ALSO

=over 2

=item L<Kelp::Module::Symbiosis>, the module manager

=back

package KelpX::Symbiosis::Engine;

use Kelp::Base;
use Carp;
use Scalar::Util qw(blessed refaddr);

attr adapter => sub { croak 'adapter is required' };
attr app_runners => sub { {} };

sub run_app
{
	my ($self, $app) = @_;

	if (blessed $app) {
		my $addr = refaddr $app;

		croak 'Symbiosis: class ' . ref($app) . ' cannot run()'
			unless $app->can("run");

		# cache the ran application so that it won't be ran twice
		$app = $self->app_runners->{$addr} //= $app->run(@_);
	}
	elsif (ref $app ne 'CODE') {
		croak "Symbiosis: mount point is neither an object nor a coderef: $app";
	}

	return $app;
}

sub build
{
	my ($self, %args) = @_;

	# mount through adapter so that it will be seen in mounted hash
	$self->adapter->mount($args{mount}, $self->adapter->app)
		if $args{mount};
}

sub mount
{
	croak 'mount needs to be overridden';
}

sub run
{
	croak 'run needs to be overridden';
}

1;

# This is not internal, but currently no documentation is provided


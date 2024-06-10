package KelpX::Symbiosis::Engine::URLMap;

use Kelp::Base 'KelpX::Symbiosis::Engine';
use Plack::App::URLMap;
use Carp;

attr handler => sub { Plack::App::URLMap->new };

sub build
{
	my ($self, %args) = @_;

	# even if not mounted, try to mount under /
	$args{mount} //= '/'
		unless exists $args{mount};

	$self->SUPER::build(%args);
}

sub mount
{
	my ($self, $path, $app) = @_;

	$self->handler->map($path, $self->run_app($app));
	return;
}

sub run
{
	my $self = shift;

	return $self->handler->to_app;
}

1;

# This is not internal, but currently no documentation is provided


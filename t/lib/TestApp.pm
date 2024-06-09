package TestApp;
use Kelp::Base 'KelpX::Symbiosis';

sub build
{
	my $self = shift;
	my $r = $self->routes;

	$r->add('/home', 'home');
}

sub build_from_methods
{
	my $self = shift;
	$self->symbiosis->mount(qr{^/test(/.+)?$}, $self->testmod);
}

sub build_from_loaded
{
	my $self = shift;

	$self->symbiosis->mount('/test/test2', 'AnotherTestSymbiont');
	$self->symbiosis->mount(qr{^/test(/.+)?$}, 'symbiont');
}

sub home
{
	'this is home';
}

1;


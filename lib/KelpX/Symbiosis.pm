package KelpX::Symbiosis;

use Kelp::Base qw(Kelp);
use KelpX::Symbiosis::Adapter;

attr -symbiosis => sub { KelpX::Symbiosis::Adapter->new(app => $_[0]->app) };

sub new
{
	my $class = shift;
	my $self = $self->SUPER::new(@_);

	$self->symbiosis->build($self->config_hash);

	return $self;
}

sub run
{
	my $self = shift;
	return $self->symbiosis->run;
}

# just for compatibility with Kelp::Module::Symbiosis
sub run_all
{
	goto \&run;
}

1;


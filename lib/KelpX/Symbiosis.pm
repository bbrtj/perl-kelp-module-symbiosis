package KelpX::Symbiosis;

use Kelp::Base qw(Kelp);
use KelpX::Symbiosis::Adapter;

# NOTE: circular reference
attr -symbiosis => sub { KelpX::Symbiosis::Adapter->new(app => $_[0], engine => 'Kelp') };

sub import
{
	my ($me) = @_;

	require Kelp::Less;
	if (defined $Kelp::Less::app) {
		$Kelp::Less::app = $me->new(%{$Kelp::Less::app});
	}
}

sub new
{
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	$self->symbiosis->build(%{$self->config_hash});

	return $self;
}

sub run
{
	my $self = shift;
	return $self->symbiosis->run;
}

# just for compatibility with older Kelp::Module::Symbiosis
sub run_all
{
	goto \&run;
}

1;


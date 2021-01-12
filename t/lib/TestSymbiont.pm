package TestSymbiont;

use Kelp::Base qw(Kelp::Module::Symbiosis::Base);
use Plack::Response;

# Some module that can be served by Plack via run()
# extending Symbiosis::Base

sub psgi
{
	return sub {
		my $res = Plack::Response->new(200);
		$res->body("mounted");
		return $res->finalize;
	};
}

sub build
{
	my ($self, %args) = @_;
	$self->SUPER::build(%args);

	$self->register(testmod => sub {
		return $self;
	});
}

1;

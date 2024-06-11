package KelpX::Symbiosis::Engine::Kelp;

use Kelp::Base 'KelpX::Symbiosis::Engine';
use Carp;

attr router => sub { shift->adapter->app->routes };

sub _get_destination
{
	my ($self, $cb) = @_;

	return sub {
		my $kelp = shift;
		my $path = pop() // '';
		my $env = $kelp->req->env;

		# remember script and path
		my $orig_script = $env->{SCRIPT_NAME};
		my $orig_path = $env->{PATH_INFO};

		# adjust slashes in paths
		my $trailing_slash = $orig_path =~ m{/$} ? '/' : '';
		$path =~ s{^/?}{/};
		$path =~ s{/?$}{$trailing_slash};

		# adjust script and path
		$env->{SCRIPT_NAME} = $orig_path;
		$env->{SCRIPT_NAME} =~ s{\Q$path\E$}{};
		$env->{PATH_INFO} = $path;

		# run the callback
		my $result = $cb->($env, @_);

		# restore old script and path
		$env->{SCRIPT_NAME} = $orig_script;
		$env->{PATH_INFO} = $orig_path;

		# produce a response
		if (ref $result eq 'ARRAY') {
			my ($status, $headers, $body) = @{$result};

			my $res = $kelp->res;
			$res->status($status) if $status;
			$res->headers($headers) if $headers;
			$res->body($body) if $body;
			$res->rendered(1);
		}
		elsif (ref $result eq 'CODE') {
			return $result;
		}

		# this should be an error unless already rendered
		return;
	};
}

sub mount
{
	my ($self, $path, $app) = @_;
	my $adapter = $self->adapter;

	croak "Symbiosis: application tries to mount itself under $path in kelp mode"
		if ref $app && $app == $adapter->app;

	$self->router->add($path, $self->_get_destination($self->run_app($app)));

}

sub run
{
	my $self = shift;
	my $adapter = $self->adapter;

	return sub { $adapter->app->psgi(@_) };
}

1;

# This is not internal, but currently no documentation is provided


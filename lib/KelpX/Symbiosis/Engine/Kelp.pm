package KelpX::Symbiosis::Engine::Kelp;

use Kelp::Base 'KelpX::Symbiosis::Engine';
use KelpX::Symbiosis::Util;
use Carp;

attr router => sub { shift->adapter->app->routes };

sub mount
{
	my ($self, $path, $app) = @_;
	my $adapter = $self->adapter;

	croak "Symbiosis: application tries to mount itself under $path in kelp mode"
		if ref $app && $app == $adapter->app;

	$self->router->add($path, KelpX::Symbiosis::Util::plack_to_kelp($self->run_app($app)));
}

sub run
{
	my $self = shift;
	return $self->adapter->app->run;
}

1;
__END__

=head1 NAME

KelpX::Symbiosis::Engine::Kelp - Use Kelp routes as an engine

=head1 DESCRIPTION

This is a reimplementation of L<KelpX::Symbiosis::Engine> using Kelp itself as
a runner. All other apps will have to go through Kelp first, which will be the
center of the application.

=head1 CAVEATS

=head2 All system routing goes through the Kelp router

You can mix apps and Kelp actions, set bridges and build urls to all application components.

=head2 Defined routes for apps do not match with suffixes by default

If you defined a static file app to be under C</static> and someone made a
request to C</static/file.txt>, it will not be matched under
L<KelpX::Symbiosis>. You should probably define the routes for symbionts as C<<
/static/>rest >>, which will match both C</static> and C</static/path/file.txt>.
Use the same techniques for defining paths as you would in Kelp, for example
you can mount an app under C<< [POST => qr/save$/] >>.

If you wish to properly preserve the rest of the path to the app (which you
should), it's a good idea to end your route with a named placeholder, like
C<< />rest >>. If you don't name it and the app contains other named
placeholders then path will not be preserved correctly (as it then won't be
included in route handler params).

It's also not correct to have a pattern like C<< /any:thing >>, because Plack
requires path to start with a slash. In this case of request C</anyone>, the
actual request would be to reach out for C</any/one>, where the script name
would end up being C</any> and the path would become C</one>. (it would still
match C</anyone>, but these are the values which will be set up for the mounted
app).

=head2 C<mount> cannot be configured for the main Kelp app

Kelp will always be mounted at the very root. The module will throw an
exception if you try to configure a different C<mount>.

=head2 Does not allow to assign specific middleware for the Kelp app

Middleware from the top-level C<middleware> will be wrapping the app the same
as Symbiosis middleware, and all other apps will have to go through it. It's
impossible to have middleware just for the Kelp app.

=head2 Plack adjustments for Kelp

Kelp could always handle plack apps with plain C<add_route>, but it required
you to build it yourself and did not handle PATH_INFO and SCRIPT_NAME
correctly. See L<KelpX::Symbiosis::Util/plack_to_kelp>.

=head2 Middleware redundancy

Wrapping some apps in the same middleware as your main app may be redundant at
times. For example, wrapping a static app in session middleware is probably
only going to reduce its performance. If it bothers you, you may want to switch
to URLMap engine or only mount specific apps under kelp using
L<KelpX::Symbiosis::Util/plack_to_kelp>.


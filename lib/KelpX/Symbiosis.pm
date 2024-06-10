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

# just for compatibility with Kelp::Module::Symbiosis
sub run_all
{
	goto \&run;
}

1;

__END__

=head1 NAME

KelpX::Symbiosis - Fertile ground for building Plack apps

=head1 SYNOPSIS

	# in configuration file
	modules => [qw/SomeSymbioticModule/],
	modules_init => {
		SomeSymbioticModule => {
			mount => '/elsewhere', # a path to mount SomeSymbioticModule
		},
	},

	# in main application file
	package KelpApp;
	use Kelp::Base 'KelpX::Symbiosis';

	sub build {
		my $symbiosis = $kelp->symbiosis;
		$symbiosis->mount('/other-path' => $kelp->module_method);
		$symbiosis->mount('/other-path' => 'module_name'); # alternative - finds a module by name
	}

	# in psgi script
	my $app = KelpApp->new();
	$app->run;

=head1 DESCRIPTION

KelpX::Symbiosis is a new, mostly backward-compatible approach to Symbiosis.
Instead of loading it as a Kelp module L<Kelp::Module::Symbiosis>, you base
your main class on C<KelpX::Symbiosis>. It will then use your Kelp application
router to reach all the Plack apps instead of L<Plack::App::URLMap>. Thanks to
this you can have more unified environment when it comes to stuff like error
pages, bridges and hooks.

=head2 Differences

Here are the differences when compared to L<Kelp::Module::Symbiosis>. See its
documentation for full reference, but keep these points below in mind.

=head3 Behavior

=head4 All system routing goes through the Kelp router

You can mix apps and Kelp actions, set bridges and build urls to all application components.

=head4 Defined routes for apps do not match with suffixes by default

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

=head4 C<run> method runs the whole ecosystem

C<run_all> is provided for backcompat, but is just an alias for C<run>.

=head3 Configuration

=head4 Symbiosis configuration values are at top-level of configuration

All configuration from L<Kelp::Module::Symbiosis/CONFIGURATION> is taken from
top-level hash instead of C<modules_init.Symbiosis> hash.

=head4 C<mount> cannot be configured for the main Kelp app

Kelp will always be mounted at the very root. The module will throw an
exception if you try to configure a different top-level C<mount>.

=head4 Does not allow to assign specific middleware for the Kelp app

Middleware from the top-level C<middleware> will be wrapping the app, but all
other apps will have to go through it. It's impossible to have middleware just
for the Kelp app.

=head3 Testing

=head4 KelpX::Symbiosis::Test is no longer required

L<KelpX::Symbiosis::Test> was used as a wrapper for testing Symbiosis-based
apps. Since now Symbiosis does not wrap Kelp in anything there is no need to
use it in favor of L<Kelp::Test> unless you use L<Kelp::Module::Symbiosis>. It
will continue to work with any Symbiosis variant though.

=head3 Miscellaneous

=head4 Kelp::Less

This module will try to detect if you're using L<Kelp::Less> on import. If you
do, it will replace the Less app instance with Symbiosis. Make sure you import
Kelp::Less before you import KelpX::Symbiosis.

	use Kelp::Less;
	use KelpX::Symbiosis;

	module 'Symbiont', mount => '/app1';

	run;

=head1 CAVEATS

Wrapping some apps in the same middleware as your main app may be redundant at
times. For example, wrapping a static app in session middleware is probably
only going to reduce its performance. If it bothers you, you may want to switch
to L<Kelp::Module::Symbiosis>.


package Kelp::Module::Symbiosis;

use Kelp::Base qw(Kelp::Module);
use Plack::App::URLMap;
use Carp;
use Scalar::Util qw(blessed);

our $VERSION = '1.00';

attr "-kelp_path" => "/";
attr "-autoattach" => 1;
attr "-mounted" => sub { {} };

sub mount
{
	my ($self, $path, $app) = @_;
	my $mounted = $self->mounted;

	carp "Overriding mounting point $path, check config"
		unless !exists $mounted->{$path};
	$mounted->{$path} = $app;
	return scalar keys %{$mounted};
}

sub run_all
{
	my ($self) = @_;
	my $psgi_apps = Plack::App::URLMap->new;

	my $error = "Cannot start the ecosystem:";
	while (my ($path, $app) = each %{$self->mounted}) {
		croak "$error mount point $path is not an object"
			unless blessed $app;
		croak "$error application mounted under $path cannot run()"
			unless $app->can("run");
		$psgi_apps->map($path, $app->run);
	}
	$psgi_apps->map($self->kelp_path, $self->app->run);

	return $psgi_apps->to_app;
}

sub build
{
	my ($self, %args) = @_;
	$self->{kelp_path} = $args{kelp_path} // $self->kelp_path;
	$self->{autoattach} = $args{autoattach} // $self->autoattach;

	$self->register(
		symbiosis => $self,
		mount => sub { shift->symbiosis->mount(@_); },
		run_all => sub { shift->symbiosis->run_all(@_); },
	);

}

1;
__END__

=head1 NAME

Kelp::Module::Symbiosis - manage an entire ecosystem of Plack organisms under Kelp

=head1 SYNOPSIS

	# in configuration file
	modules => [qw/Symbiosis/],
	modules_init => {
		Symbiosis => {
			kelp_path => '/myapp', # url path, defaults to '/'
			autoattach => 1, # boolean, defaults to 1
		},
	},

	# in psgi script
	my $app = MyApp->new();
	$app->run_all; # instead of run

=head1 DESCRIPTION

This module is an attempt to standardize the way many standalone Plack applications should be ran alongside the Kelp framework. The intended use is to introduce new "organisms" into symbiotic interaction by creating Kelp modules that run I<mount> to attach themselves onto Kelp. Then, the I<run_all> should be invoked in place of Kelp's I<run>, which will construct a L<Plack::App::URLMap> and return it as an application.

=head1 METHODS

=head2 mount

	sig: mount($self, $path, $app, $auto = undef)

Adds a new $app to the ecosystem under $path. Automatic attachment is marked with $auto and will be rejected if I<autoattach> is set to false.

=head2 run_all

	sig: run_all($self)

Constructs and returns a new L<Plack::App::URLMap> with all the mounted modules and Kelp itself.

=head2 mounted

	sig: mounted($self)

Returns a hashref containing a list of mounted modules, keyed with their specified mount paths.

=head1 METHODS INTRODUCED TO KELP

=head2 symbiosis

Returns an instance of this class.

=head2 mount

Shortcut method, same as C<< symbiosis->mount() >>.

The main reason to introduce this method is to allow other ecosystem managers to emerge if needed. All symbiotic modules should be compatible with the new manager because they won't be using I<< $kelp->symbiosis >> directly.

=head2 run_all

Shortcut method, same as C<< symbiosis->run_all() >>.

=head1 CONFIGURATION

The module should be inserted into Kelp configuration before any other symbiotic module, which will allow automatic mounting during module building. If inserted at the end, these modules will need to be mounted manually by calling I<mount> method with their paths and instances.

=head2 kelp_path

Mounting point for the base Kelp instance. Defaults to root I<'/'>, which will usually be the case.

=head2 autoattach

Whether to automatically call I<mount> for all the modules which will check for it. All modules extending L<Kelp::Module::Symbiosis::Base> will check for this and mount themselves based on this flag. Defaults to I<1>.

If you set this to I<0> you will have to run something like C<< $kelp->mount($mount_path, $kelp->module); >> in Kelp's I<build> method, for each module you want to be a part of the ecosystem. Modules inheriting from the base symbiosis class introduce a convenience method I<attach>, which allows to write C<< $kelp->module->attach(); >>.

Note that the main Kelp instance is always a part of the ecosystem and therefore will always be run with I<run_all> regardless of this flag's value.

=head1 REQUIREMENTS FOR MODULES

The sole requirement for a module to be mounted into Symbiosis is its ability to I<run()>. A module also needs to be a blessed reference, of course.

The I<run> method should return a psgi application ready to be ran by the Server, wrapped in all the needed middlewares. See L<Kelp::Module::Symbiosis::Base> for a preferred base class for these modules.

=head1 SEE ALSO

=over 2

=item L<Kelp::Module::Symbiosis::Base>, a base for symbiotic modules

=item L<Kelp::Module::Websocket>, a reference symbiotic module

=item L<Plack::App::URLMap>, Plack URL mapper application

=back

=head1 AUTHOR

Bartosz Jarzyna, E<lt>brtastic.dev@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut

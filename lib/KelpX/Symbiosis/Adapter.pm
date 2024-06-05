package KelpX::Symbiosis::Adapter;

use Kelp::Base;
use Plack::App::URLMap;
use Carp;
use Scalar::Util qw(blessed refaddr);
use Plack::Middleware::Conditional;
use Plack::Util;
use KelpX::Symbiosis::_Util;

attr -app => sub { croak 'app is required' };
attr -mounted => sub { {} };
attr -loaded => sub { {} };
attr -middleware => sub { [] };
attr reverse_proxy => 0;

sub mount
{
	my ($self, $path, $app) = @_;
	my $mounted = $self->mounted;

	if (!ref $app && $app) {
		my $loaded = $self->loaded;
		croak "Symbiosis: cannot mount $app, because no such name was loaded"
			unless $loaded->{$app};
		$app = $loaded->{$app};
	}

	carp "Symbiosis: overriding mounting point $path"
		if exists $mounted->{$path};
	$mounted->{$path} = $app;
	return scalar keys %{$mounted};
}

sub _link
{
	my ($self, $name, $app, $mount) = @_;
	my $loaded = $self->loaded;

	warn "Symbiosis: overriding module name $name"
		if exists $loaded->{$name};
	$loaded->{$name} = $app;

	if ($mount) {
		$self->mount($mount, $app);
	}
	return scalar keys %{$loaded};
}

sub run
{
	my $self = shift;
	my $psgi_apps = Plack::App::URLMap->new;
	my %addrs;    # apps keyed by refaddr

	my $error = "Symbiosis: cannot start the ecosystem because";
	while (my ($path, $app) = each %{$self->mounted}) {
		if (blessed $app) {
			my $addr = refaddr $app;

			if ($app->isa('KelpX::Symbiosis')) {
				$addrs{$addr} //= sub { $app->psgi(@_) };
			}
			else {
				croak "$error application mounted under $path cannot run()"
					unless $app->can("run");

				# cache the ran application so that it won't be ran twice
				$addrs{$addr} //= $app->run(@_);
			}

			$psgi_apps->map($path, $addrs{$addr});
		}
		elsif (ref $app eq 'CODE') {
			$psgi_apps->map($path, $app);
		}
		else {
			croak "$error mount point $path is neither an object nor a coderef";
		}
	}

	my $wrapped = KelpX::Symbiosis::_Util::wrap($self, $psgi_apps->to_app);
	return $self->_reverse_proxy_wrap($wrapped);
}

sub _reverse_proxy_wrap
{
	my ($self, $app) = @_;
	return $app unless $self->reverse_proxy;

	my $mw_class = Plack::Util::load_class('ReverseProxy', 'Plack::Middleware');
	return Plack::Middleware::Conditional->wrap(
		$app,
		condition => sub { !$_[0]{REMOTE_ADDR} || $_[0]{REMOTE_ADDR} =~ m{127\.0\.0\.1} },
		builder => sub { $mw_class->wrap($_[0]) },
	);
}

sub build
{
	my ($self, %args) = @_;
	$args{mount} //= '/'
		unless exists $args{mount};

	if ($args{mount}) {
		$self->mount($args{mount}, $self->app);
	}

	if ($args{reverse_proxy}) {
		$self->reverse_proxy(1);
	}

	KelpX::Symbiosis::_Util::load_middleware($self, %args);
}

1;


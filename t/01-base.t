use strict;
use warnings;

use Test::More;
use HTTP::Request::Common;
use Kelp::Test;
use lib 't/lib';

# Kelp module being tested
{

	package Symbiosis::Test;

	use Kelp::Base 'KelpX::Symbiosis';

	sub build
	{
		my $self = shift;
		$self->load_module("+TestSymbiont", middleware => [qw(ContentMD5)]);

		$self->symbiosis->mount("/kelp", $self);
		$self->symbiosis->mount("/test", $self->testmod);

		$self->add_route("/test" => sub {
			"kelp";
		});
	}

	1;
}

my $app = Symbiosis::Test->new(mode => 'no_mount');
can_ok $app, qw(symbiosis run_all testmod);
is $app->symbiosis->reverse_proxy, 0, 'reverse proxy status ok';

my $symbiosis = $app->symbiosis;
can_ok $symbiosis, qw(loaded mounted run mount);

my $mounted = $symbiosis->mounted;
is scalar keys %$mounted, 2, "mounted count ok";
isa_ok $mounted->{"/kelp"}, "Kelp";
isa_ok $mounted->{"/test"}, "TestSymbiont";

my $loaded = $symbiosis->loaded;
is scalar keys %$loaded, 1, "loaded count ok";
isa_ok $loaded->{"symbiont"}, "TestSymbiont";

my $t = Kelp::Test->new(app => $app);

$t->request(GET "/kelp/test")
	->code_is(200)
	->content_is("kelp");

$t->request(GET "/test")
	->code_is(200)
	->header_is("Content-MD5", "81c4e3af4002170ab76fe2e53488b6a4")
	->content_is("mounted");

$t->request(GET "/test/test")
	->code_is(200)
	->header_is("Content-MD5", "81c4e3af4002170ab76fe2e53488b6a4")
	->content_is("mounted");

$t->request(GET "/kelp/kelp")
	->code_is(404);

done_testing;


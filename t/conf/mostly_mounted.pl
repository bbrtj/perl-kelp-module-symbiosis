# Common settings
{
	modules => [qw/+TestSymbiont +AnotherTestSymbiont/],
	modules_init => {
		AnotherTestSymbiont => {
			mount => '/test/test2',
		},
	}
};


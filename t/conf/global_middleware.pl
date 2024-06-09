# Common settings
{
	middleware => [qw(ContentMD5)],

	modules => [qw/+TestSymbiont/],
	modules_init => {
		TestSymbiont => {
			mount => '/test',
			middleware => [qw(ContentLength)]
		},
	}
};


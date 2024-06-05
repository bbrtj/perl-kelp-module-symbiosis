# Common settings
{
	mount => '/kelp',
	middleware => [qw(ContentMD5)],

	modules => [qw/+TestSymbiont/],
	modules_init => {
		TestSymbiont => {
			mount => '/test',
			middleware => [qw(ContentLength)]
		},
	}
};


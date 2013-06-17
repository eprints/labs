# Usage:
#
# Create a file in archives/[archiveid]/var/passwd.
#
# The file should contain user accounts, one per line:
# username:password
#
# password is the perl crypt() of the plain-text.
# If password is omitted the user's login is checked using the default
# check_user_password().

{
my $check_user_password = $c->{check_user_password};
if (!defined $check_user_password)
{
	$check_user_password = sub {
		return shift->{database}->valid_login(@_);
	};
}

$c->{check_user_password} = sub {
	my ($repo, $username, $password) = @_;

	my $login_file = $repo->config('variables_path') . '/passwd';
	if (open(my $fh, "<", $login_file))
	{
		while(<$fh>)
		{
			next if /^#/;
			chomp($_);
			my ($_username, $_password) = split ':', $_;
			if ($username eq $_username)
			{
				if (defined $_password)
				{
					return crypt($password, $_password) eq $_password ? $username : undef;
				}
				else
				{
					return &$check_user_password(@_);
				}
			}
		}
		return undef;
	}

	return &$check_user_password(@_);
};
}

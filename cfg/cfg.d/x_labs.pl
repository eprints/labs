# Usage:
#
# Create a file in archives/[archiveid]/var/passwd.
#
# The file should contain user accounts, one per line:
# username:password:usertype
#
# password is the perl crypt() of the plain-text.
# If password is omitted the user's login is checked using the default
# check_user_password().
#
# usertype is a valid type from the user namedset.
# If usertype is set it will modify the user's account to that type the next
# time the log in.

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

	my $real_username;

	my $login_file = $repo->config('variables_path') . '/passwd';
	if (open(my $fh, "<", $login_file))
	{
		my ($_username, $_password, $_usertype);
		while(<$fh>)
		{
			next if /^#/;
			chomp($_);
			($_username, $_password, $_usertype) = split ':', $_;
			next if $username ne $_username;
			if ($_password)
			{
				$real_username = crypt($password, $_password) eq $_password ? $username : undef;
			}
			else
			{
				$real_username = &$check_user_password(@_);
				# back compat.
				$real_username = $username if $real_username eq "1";
				$real_username = undef if $real_username eq "0";
			}
			last;
		}
		my $user = $repo->user_by_username($real_username);
		if (defined $user)
		{
			if ($_usertype)
			{
				$user->set_value('usertype', $_usertype);
				$user->commit;
			}
		}
		return $real_username;
	}

	return &$check_user_password(@_);
};
}

#!/usr/bin/perl

=head1 NAME

labs_import_eprints

=head1 SYNOPSIS

labs_import_eprints [archiveid]

=head1 OPTIONS

=over 4

=item help

=item verbose

=item quiet

=item limit = 100

Limit the number of imported items.

=item source = http://eprints.soton.ac.uk/

Set the EPrints repository to import from. Must have eprintid in its advanced search configuration.

=item update

Update existing items (based on eprint id) or create eprints with the imported eprint id. Will also import user ids.

=back

=cut

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../../perl_lib";

use EPrints;
use LWP::UserAgent;
use Getopt::Long;
use Pod::Usage;

my %opt = (
	source => 'http://eprints.soton.ac.uk/',
	limit => '100',
	verbose => 1,
	quiet => 0,
);
GetOptions(\%opt,
	'source=s',
	'limit=i',
	'update',
	'verbose+',
	'quiet',
	'help',
) or pod2usage();

pod2usage(1) if $opt{help};

my $noise = $opt{verbose} - $opt{quiet};

my $repo = EPrints->new->repository(shift @ARGV) or pod2usage();

my $dataset = $repo->dataset('eprint');

my $ua = LWP::UserAgent->new;

my $url = URI->new($opt{source});
$url->path($url->path . 'cgi/search/archive/advanced');

my %q = (
	_action_export => 1,
	output => 'XML',
	eprintid => '1..',
	n => ($opt{limit} < 100 ? $opt{limit} : 100),
);

my $handler = EPrints::CLIProcessor->new(
	epdata_to_dataobj => sub {
		my ($epdata, %opts) = @_;

		my $eprint;

		my $eprintid = $epdata->{eprintid};
		if ($opt{update})
		{
			$eprint = $dataset->dataobj($eprintid);
			if (defined $eprint)
			{
				$eprint->update($epdata);
				$eprint->commit;
			}
		}

		if (!defined $eprint)
		{
			$eprint = $dataset->create_dataobj($epdata);
		}
		
		print $eprint->id, "\n" if $noise;
		
		return $eprint;
	},
);


my $offset = 0;
while(1)
{
	$url->query_form(
		%q,
		search_offset => $offset,
	);
	$offset += 100;

	my $tmp = File::Temp->new;

	warn "$url\n" if $noise > 1;
	my $r = $ua->get($url, ':content_file' => "$tmp");
	die $r->status_line if $r->is_error;

	seek($tmp,0,0);

	local $repo->{config}{enable_web_imports} = 1;
	local $repo->{config}{enable_import_fields} = 1;

	my $plugin = $repo->plugin('Import::XML', Handler => $handler);
	my $list = $plugin->input_fh(
		fh => $tmp,
		dataset => $dataset,
	);
	last if $list->count < 100; # partial list
	$opt{limit} -= $list->count;
	last if $opt{limit} <= 0;
}

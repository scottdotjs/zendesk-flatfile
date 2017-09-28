#!perl

use warnings;
use strict;

use Config::Tiny;
use Getopt::Long 'GetOptions';

use lib 'lib';
use Zendesk;

my $dump_file = $ARGV[0];

show_help_and_exit() if !$dump_file;

my ($no_convert, $no_download, $no_index, $no_split, $quiet, $update);

my $config_file = 'zendesk.conf';
my $delay = 5;

GetOptions(
	'no_convert|nc'   => \$no_convert,
	'no_download|nd'  => \$no_download,
	'no_index|ni'     => \$no_index,
	'no_split|ns'     => \$no_split,
	'config|c'        => \$config_file,
	'delay|d=i'       => \$delay,
	'quiet|q'         => \$quiet,
	'update|u'        => \$update,
);

my $config = Config::Tiny->new->read($config_file);

my $custom_fields;

foreach (keys %{$config->{custom_fields}}) {
	$custom_fields->{$_} = $config->{custom_fields}->{$_};
}

my $z = Zendesk->new({
	custom_fields     => $custom_fields,
	delay             => $delay,
	quiet             => $quiet,
	attachments_dir   => $config->{directories}->{attachments},
	indices_dir       => $config->{directories}->{indices},
	resources_dir     => $config->{directories}->{resources},
	tickets_html_dir  => $config->{directories}->{tickets_html},
	tickets_json_dir  => $config->{directories}->{tickets_json},
	update            => $update,
});

$z->status('Quiet mode enabled.') if $quiet;

$no_split    ? $z->skip('dump file splitting')   : $z->split_json($dump_file);
$no_convert  ? $z->skip('JSON->HTML conversion') : $z->json_to_html;
$no_index    ? $z->skip('attachment indexing')   : $z->index_attachments;
$no_download ? $z->skip('attachment download')   : $z->download_attachments;

sub show_help_and_exit {
	print <<"END_HELP";
Usage: $0 [options] tickets_dump_file.json

Options:
 -c, --config         Location of config file (default: ./zendesk.conf)
 -d, --delay          Delay between downloading attachments; default 5 seconds
 -q, --quiet          Don't mention individual items while running
 -u, --update         Overwrite any files already converted/downloaded
-ns, --no_split       Don't split JSON dump file into individual ticket files
-nc, --no_convert     Don't convert JSON ticket files into HTML files
-ni, --no_index       Don't index ticket attachments
-nd, --no_download    Don't download attachments from Zendesk
END_HELP

	exit 1;
}
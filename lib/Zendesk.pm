package Zendesk;

use warnings;
use strict;

use Encode 'encode_utf8';
use File::Slurper 'read_text';
use JSON;
use Sort::Naturally;
use Template;
use WWW::Mechanize;

sub new {
	my $self = bless {}, shift;
	my $args = shift;

	$self->{$_} = $args->{$_} foreach qw(
		attachments custom_fields delay indices_dir quiet
		resources_dir tickets_json_dir tickets_html_dir update
	);

	$self;
}

sub download_attachments {
	my $self = shift;
	my $index_file = $self->{file};
	my $delay      = $self->{delay};

	my $index = read_text $index_file;

	my @items = split "\n", $index;

	my $current_item = 0;
	my $total_items  = $#items;

	my $mech = WWW::Mechanize->new;

	$self->status('Beginning attachment download process.');

	foreach my $item (@items) {
		my ($ticket_id, $file, $url) = $item =~ m((\d+)/(.*?)\t(.*?)$);

		$file = encode_utf8 $file;

		my $dir = $self->{attachments} . "/$ticket_id";

		mkdir $dir unless -d $dir && -w $dir;

		++$current_item;
		my $a_ident = "Attachment [$current_item/$total_items]";
		my $t_ident = "Ticket #$ticket_id - $file";

		if (-f "$dir/$file" && !$self->{update}) {
			$self->status("$a_ident found, skipping: $t_ident.", $self->{quiet});
			next;
		} else {
			$self->status("$a_ident downloading: $t_ident.", $self->{quiet});
		}

		$mech->get($url);

		die "Couldn't get file: HTTP " . $mech->status if !$mech->success;

		open (my $out, '>', "$dir/$file") or die $!;
		binmode $out;
		print $out $mech->content;
		close $out;

		sleep $delay;
	}

	$self->status('Downloads complete.');
}

sub index_attachments {
	my $self = shift;
	my $indices_dir       = $self->{indices_dir};
	my $tickets_json_dir  = $self->{tickets_json_dir};

	$self->status('Beginning attachment indexing process.');

	use open ":encoding(utf8)";
	open (my $index, '>', "$indices_dir/attachments.csv") or die $!;

	foreach (nsort(glob("$tickets_json_dir/*.json"))) {
		my $json = encode_utf8 read_text $_;
		my $ticket = decode_json $json;

		my ($ticket_id) = $_ =~ m($tickets_json_dir/(\d+));

		$self->status("Indexing attachments for ticket #$ticket_id.", $self->{quiet});

		my $comment_number = 0;

		foreach my $comment (@{$ticket->{comments}}) {
			$comment->{comment_number} = ++$comment_number;
		
			foreach my $file (@{$comment->{attachments}}) {
				print $index "$ticket_id/" . $comment->{comment_number} . '_' . $file->{file_name};
				print $index "\t"  . $file->{content_url} . "\n";
			}
		}
	}

	close $index;
	
	$self->status('Indexing complete.');
}

sub json_to_html {
	my $self = shift;
	my $tickets_json_dir = $self->{tickets_json_dir};
	my $tickets_html_dir = $self->{tickets_html_dir};
	my $resources_dir    = $self->{resources_dir};
	my $custom_fields    = $self->{custom_fields};

	$self->status('Beginning conversion process.');

	foreach (nsort(glob("$tickets_json_dir/*.json"))) {
		my ($ticket_id) = $_ =~ m($tickets_json_dir/(\d+));

		if (-f "$tickets_html_dir/$ticket_id.html" && !$self->{update}) {
			$self->status("Convert: found ticket #$ticket_id, skipping.", $self->{quiet});
			next;
		} else {
			$self->status("Convert: converting ticket #$ticket_id.", $self->{quiet});
		}

		my $json   = encode_utf8 read_text $_;
		my $ticket = decode_json $json;

		my $people; # ID => name

		foreach (qw(submitter requester assignee)) {
			if ($ticket->{$_}) {
				$people->{$ticket->{$_}->{id}} = $ticket->{$_}->{name};
			}
		}

		my $comment_number = 0;

		# Additional data that simplifies the template
		foreach (@{$ticket->{comments}}) {
			$_->{comment_number} = ++$comment_number;
			$_->{author}         = $people->{$_->{author_id}};
		}

		Template->new->process(
			"$resources_dir/ticket.tt",
			{
				ticket        => $ticket,
				custom_fields => $custom_fields,
			},
			"$tickets_html_dir/$ticket_id.html",
			{ binmode => ':encoding(UTF-8)' }
		) || die;
	}

	$self->status('Conversion complete.');
}

sub split_json {
	my ($self, $file) = @_;
	my $tickets_json_dir = $self->{tickets_json_dir};

	my $json = read_text $file;

	my @lines = split "\n", $json;

	use open ":encoding(utf8)";

	$self->status('Beginning dump file splitting process.');

	foreach (@lines) {
		my ($id) = $_ =~ /"id":(\d+),/;

		if (-f "$tickets_json_dir/$id.json" && !$self->{update}) {
			$self->status("Split: found ticket #$id, skipping.", $self->{quiet});
		} else {
			$self->status("Split: splitting ticket #$id.", $self->{quiet});
		}

		open (my $out, '>', "$tickets_json_dir/$id.json") or die $!;
		print $out $_;
		close $out;
	}

	$self->status('Split complete.');
}

sub skip {
	my ($self, $process) = @_;
	$self->status("Skipping $process process.");
}

sub status {
	my ($self, $message, $quiet) = @_;
	print "$message\n" unless $quiet;
}

1;
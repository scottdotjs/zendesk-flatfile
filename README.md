# Zendesk export flat file maker

## Description

This is a tool, written in Perl, to convert a Zendesk Support JSON export file
of tickets into individual HTML files and download all ticket attachments. The
output isn't particularly attractive but is honest, containing:

- Ticket number
- Title
- Creation date and time
- Priority
- Assignee
- Status
- Tags
- Custom fields
- Requester
- Description
- Public and private comments (unformatted)

It doesn't currently produce an index of tickets or users. That may change in
a future release. Patches to improve the fidelity of the ticket template, or
for that matter my horrible CSS, are very welcome.

It's intended to work on [complete data dumps](https://support.zendesk.com/hc/en-us/articles/115006773728-What-is-the-recommended-method-to-regularly-export-Zendesk-Support-data-),
not incremental ones. You may have to contact Zendesk's support to request
JSON as an output format.

If requested, attachments are downloaded in the following structure:

`<attachments directory>/<ticket number>/<comment number>_<file name>`

## Setup

This tool has the following non-core prerequisites:
- [File::Slurper](https://metacpan.org/pod/File::Slurper)
- [JSON](https://metacpan.org/pod/JSON)
- [Sort::Naturally](https://metacpan.org/pod/Sort::Naturally)
- [Template::Toolkit](https://metacpan.org/pod/Template::Toolkit)
- [WWW::Mechanize](https://metacpan.org/pod/WWW::Mechanize)
- [Config::Tiny](https://metacpan.org/pod/Config::Tiny)

Once these are installed (you can use the [CPAN](https://metacpan.org/pod/CPAN)
or [CPANPLUS](https://metacpan.org/pod/CPANPLUS) command line tools to do
that), in the root directory of this tool, edit `zendesk.conf`, which is in
INI format.

The `directories` section you probably won't need to change - `tickets_json`
will contain the JSON files for individual tickets, `tickets_html` the output
HTML files, `attachments` the downloaded attachments, `indices` the data
indices produced by the tool while working (currently only for attachments),
and `resources` has the output template file and stylesheet.

In the `custom_fields` section, enter the IDs and names of any [custom ticket
fields](https://support.zendesk.com/hc/en-us/articles/203661496-Adding-custom-fields-to-your-tickets-and-support-request-forms)
that you've set up, in the format `00000000 = Name`.

Once you have confirmed that the desired `directories` config is in place, you'll need to create the target directories before the first run, with something like
`$ mkdir tickets_json tickets_html attachments indices`.

## Usage

`zendesk.pl [options] tickets_dump_file.json`

Running the tool without options will produce HTML files for all tickets in
your JSON dump file and download all attachments, but not overwrite anything
produced in a previous run. You can override that by using the `--update`
flag. Future versions may provide an option to regenerate a particular ticket
(for if you're testing modifications to the ticket template), but that's not
currently available.

Options:
```
 -c, --config         Location of config file (default: ./zendesk.conf)
 -d, --delay          Delay between downloading attachments; default 5 seconds
 -q, --quiet          Don't mention individual items while running
 -u, --update         Overwrite any files already converted/downloaded
-ns, --no_split       Don't split JSON dump file into individual ticket files
-nc, --no_convert     Don't convert JSON ticket files into HTML files
-ni, --no_index       Don't index ticket attachments
-nd, --no_download    Don't download attachments from Zendesk
```

## Note for Perl programmers

If you're using Zendesk data in Perl, you may have seen their help article
[Getting large data sets with the Zendesk API and Perl](https://help.zendesk.com/hc/en-us/articles/229137047-Getting-large-data-sets-with-the-Zendesk-API-and-Perl). It
gives bad advice, suggesting that you suppress character set warnings with
`no warnings 'utf8';`. Don't do that, follow [this advice](https://stackoverflow.com/a/6221297/3358139).

## Author and license

Copyright 2017 [Scott Martin](https://github.com/scottdotjs).

Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use HTTP::Request;
use LWP::UserAgent;
use IO::Socket::SSL;
use Digest::SHA qw(sha1_hex);
use File::Path qw(make_path);
use File::Spec::Functions qw(catfile);
use URI;

# ASCII art
print <<'ASCII';
  _ __ ___     __ _   ___ 
 | '_ ` _ \   / _` | / __|
 | | | | | | | (_| | \__ \
 |_| |_| |_|  \__,_| |___/
 
ASCII

# Command-line options
my $request_body = '';
my $keep_alive = 0;
my $save_responses = 0;
my $delay_ms = 100;
my $method = 'GET';
my $match = '';
my $output_dir = 'out';
my @headers = ();
my @save_status = ();
my $proxy = '';
my $ignore_html_files = 0;
my $ignore_empty = 0;
my $help = 0;

GetOptions(
    'body|b=s'          => \$request_body,
    'keep-alive|k'      => \$keep_alive,
    'save|S'            => \$save_responses,
    'delay|d=i'         => \$delay_ms,
    'method|m=s'        => \$method,
    'match|M=s'         => \$match,
    'output|o=s'        => \$output_dir,
    'header|H=s@'       => \@headers,
    'save-status|s=i@'  => \@save_status,
    'proxy|x=s'         => \$proxy,
    'ignore-html'       => \$ignore_html_files,
    'ignore-empty'      => \$ignore_empty,
    'help|h'            => \$help,
) or pod2usage(2);

pod2usage(1) if $help;

# Regex to detect HTML content
my $is_html = qr/<html/i;

# Create the user agent
my $ua = LWP::UserAgent->new;
$ua->agent("Mozilla/5.0");
$ua->timeout(10);
$ua->ssl_opts(verify_hostname => 0, SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE);
$ua->proxy('http', $proxy) if $proxy;
$ua->conn_cache({total_capacity => 30}) if $keep_alive;

# Process each URL from stdin
while (my $raw_url = <STDIN>) {
    chomp $raw_url;
    sleep($delay_ms / 1000);

    # Create HTTP request
    my $uri = URI->new($raw_url);
    my $req = HTTP::Request->new($method => $uri);
    $req->content($request_body) if $request_body;

    foreach my $header (@headers) {
        my ($key, $value) = split(/:/, $header, 2);
        $req->header($key => $value) if $value;
    }

    # Send request
    my $resp = $ua->request($req);
    my $response_body = $resp->decoded_content;

    my $should_save = $save_responses || scalar(grep { $_ == $resp->code } @save_status);

    # Check HTML and empty response
    if ($ignore_html_files) {
        $should_save = $should_save && $response_body !~ $is_html;
    }
    if ($ignore_empty) {
        $should_save = $should_save && $response_body =~ /\S/;
    }
    if ($match) {
        $should_save = $should_save || $response_body =~ /\Q$match\E/;
    }

    if (!$should_save) {
        print "$raw_url " . $resp->code . "\n";
        next;
    }

    # Create the output file paths
    my $normalized_path = normalize_path($uri->path);
    my $hash = sha1_hex($method . $raw_url . $request_body . join(',', @headers));
    my $body_path = catfile($output_dir, $uri->host, $normalized_path, "$hash.body");
    my $headers_path = catfile($output_dir, $uri->host, $normalized_path, "$hash.headers");

    # Ensure directories exist
    make_path($body_path =~ s|/[^/]+$||r);

    # Write the response body to a file
    open my $body_fh, '>', $body_path or die "Could not open file '$body_path': $!";
    print $body_fh $response_body;
    close $body_fh;

    # Write the response headers to a file
    open my $headers_fh, '>', $headers_path or die "Could not open file '$headers_path': $!";
    print $headers_fh $req->method . " " . $req->uri . "\n\n";
    foreach my $header (@headers) {
        print $headers_fh "> $header\n";
    }
    print $headers_fh "\n";
    print $headers_fh "< " . $resp->protocol . " " . $resp->status_line . "\n";
    foreach my $key ($resp->header_field_names) {
        print $headers_fh "< $key: " . $resp->header($key) . "\n";
    }
    close $headers_fh;

    print "$body_path: $raw_url " . $resp->code . "\n";
}

sub normalize_path {
    my ($path) = @_;
    $path =~ s/[^a-zA-Z0-9\/._-]+/-/g;
    return $path;
}

__END__

=head1 NAME

mas.pl - Request URLs provided on stdin fairly fast

=head1 SYNOPSIS

mas.pl [options]

 Options:
   -b, --body <data>         Request body
   -d, --delay <delay>       Delay between issuing requests (ms)
   -H, --header <header>     Add a header to the request (can be specified multiple times)
       --ignore-html         Don't save HTML files; useful when looking non-HTML files only
       --ignore-empty        Don't save empty files
   -k, --keep-alive          Use HTTP Keep-Alive
   -m, --method              HTTP method to use (default: GET, or POST if body is specified)
   -M, --match <string>      Save responses that include <string> in the body
   -o, --output <dir>        Directory to save responses in (will be created)
   -s, --save-status <code>  Save responses with given status code (can be specified multiple times)
   -S, --save                Save all responses
   -x, --proxy <proxyURL>    Use the provided HTTP proxy
   -h, --help                Show this help message

=head1 OPTIONS

=over 4

=item B<-b, --body> <data>

Request body.

=item B<-d, --delay> <delay>

Delay between issuing requests in milliseconds.

=item B<-H, --header> <header>

Add a header to the request. This option can be specified multiple times.

=item B<--ignore-html>

Don't save HTML files; useful when looking for non-HTML files only.

=item B<--ignore-empty>

Don't save empty files.

=item B<-k, --keep-alive>

Use HTTP Keep-Alive.


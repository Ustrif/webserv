#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use JSON::PP;
use POSIX qw(strftime);

my $cgi = CGI->new;

my $method = $ENV{'REQUEST_METHOD'} || 'UNKNOWN';
my $uri = $ENV{'REQUEST_URI'} || $ENV{'SCRIPT_NAME'} || '/';
my $query_string = $ENV{'QUERY_STRING'} || '';
my $remote_addr = $ENV{'REMOTE_ADDR'} || 'UNKNOWN';
my $user_agent = $ENV{'HTTP_USER_AGENT'} || 'UNKNOWN';
my $protocol = $ENV{'SERVER_PROTOCOL'} || 'UNKNOWN';

my %headers;

foreach my $key (sort keys %ENV) {
    if ($key =~ /^HTTP_/) {
        my $name = $key;
        $name =~ s/^HTTP_//;
        $name =~ s/_/-/g;
        $headers{$name} = $ENV{$key};
    }
}

my %query;
foreach my $key ($cgi->param) {
    my @values = $cgi->multi_param($key);
    $query{$key} = @values > 1 ? \@values : $values[0];
}

my $body = '';
if ($method =~ /^(POST|PUT|PATCH)$/) {
    my $length = $ENV{'CONTENT_LENGTH'} || 0;
    $length = 1024 * 1024 if $length > 1024 * 1024;

    binmode(STDIN);
    read(STDIN, $body, $length) if $length > 0;
}

my $json = JSON::PP->new->pretty->canonical;

sub escape_html {
    my ($value) = @_;
    $value = '' unless defined $value;
    $value =~ s/&/&amp;/g;
    $value =~ s/</&lt;/g;
    $value =~ s/>/&gt;/g;
    $value =~ s/"/&quot;/g;
    $value =~ s/'/&#39;/g;
    return $value;
}

sub json_html {
    my ($value) = @_;
    return escape_html($json->encode($value));
}

print "Content-Type: text/html; charset=utf-8\r\n\r\n";

print <<"HTML";
<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Perl CGI Inspector</title>

<style>
* { box-sizing: border-box; }

body {
    margin: 0;
    padding: 35px;
    background: #0b1020;
    color: #e2e8f0;
    font-family: Arial, sans-serif;
}

main {
    max-width: 1050px;
    margin: auto;
}

h1 { margin-bottom: 8px; }

.subtitle {
    color: #94a3b8;
    margin-bottom: 28px;
}

.badge {
    display: inline-block;
    padding: 9px 14px;
    background: #451a03;
    color: #fb923c;
    border: 1px solid #9a3412;
    border-radius: 7px;
    font-size: 13px;
    font-weight: bold;
}

.card {
    background: #151e30;
    border: 1px solid #29364c;
    padding: 22px;
    border-radius: 12px;
    margin-bottom: 17px;
}

.label {
    color: #94a3b8;
    font-size: 11px;
    text-transform: uppercase;
    margin-bottom: 12px;
}

.method {
    font-size: 26px;
    font-weight: bold;
    color: #4ade80;
}

.url {
    font-size: 17px;
    overflow-wrap: anywhere;
}

.grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 17px;
}

pre {
    background: #090e19;
    color: #a5f3fc;
    padding: 16px;
    border-radius: 8px;
    overflow-x: auto;
    white-space: pre-wrap;
    overflow-wrap: anywhere;
    font-size: 13px;
    line-height: 1.6;
}

.footer {
    color: #64748b;
    text-align: center;
    margin-top: 30px;
    font-size: 12px;
}

\@media(max-width:650px) {
    body { padding: 15px; }
    .grid { grid-template-columns: 1fr; }
}
</style>
</head>

<body>
<main>

<h1>🐪 Perl CGI Inspector</h1>
<div class="subtitle">HTTP Request Information Dashboard</div>

<div class="card">
    <span class="badge">● RUNNING VIA CGI-BIN</span>

    <p class="label" style="margin-top:25px">Request Method</p>
    <div class="method">@{[escape_html($method)]}</div>

    <p class="label" style="margin-top:25px">Request URI</p>
    <div class="url">@{[escape_html($uri)]}</div>
</div>

<div class="grid">

<div class="card">
    <div class="label">Server Information</div>
    <pre>@{[json_html({
        Server => $ENV{'SERVER_NAME'} || 'UNKNOWN',
        Port => $ENV{'SERVER_PORT'} || 'UNKNOWN',
        Protocol => $protocol,
        Gateway => $ENV{'GATEWAY_INTERFACE'} || 'UNKNOWN',
        Script => $ENV{'SCRIPT_NAME'} || 'UNKNOWN',
        CGI => 'Perl CGI',
        Perl_Version => $]
    })]}</pre>
</div>

<div class="card">
    <div class="label">Client Information</div>
    <pre>@{[json_html({
        IP_Address => $remote_addr,
        User_Agent => $user_agent,
        Remote_Host => $ENV{'REMOTE_HOST'} || 'UNKNOWN',
        Time => scalar(localtime())
    })]}</pre>
</div>

</div>

<div class="card">
    <div class="label">Query Parameters</div>
    <pre>@{[json_html(\%query)]}</pre>
</div>

<div class="card">
    <div class="label">Request Headers</div>
    <pre>@{[json_html(\%headers)]}</pre>
</div>

<div class="card">
    <div class="label">Request Body</div>
    <pre>@{[escape_html($body || 'No request body received.')]}</pre>
</div>

<div class="card">
    <div class="label">CGI Environment</div>
    <pre>@{[json_html({
        REQUEST_METHOD => $method,
        REQUEST_URI => $uri,
        QUERY_STRING => $query_string,
        SCRIPT_NAME => $ENV{'SCRIPT_NAME'},
        PATH_INFO => $ENV{'PATH_INFO'},
        CONTENT_TYPE => $ENV{'CONTENT_TYPE'},
        CONTENT_LENGTH => $ENV{'CONTENT_LENGTH'},
        GATEWAY_INTERFACE => $ENV{'GATEWAY_INTERFACE'}
    })]}</pre>
</div>

<div class="footer">
    Perl @{[escape_html($])]} · CGI-BIN Execution · Request Inspector
</div>

</main>
</body>
</html>
HTML

#!/usr/bin/env perl

use Compress::Zlib;
use MIME::Base64 qw( decode_base64url );
use JSON;

my $token = @ARGV[0];

if (not defined $token) {
    die "Usage:\n\t $0 <token>\n\n"; 
}

my @parts = split( /\./, $token);

if (scalar @parts != 3) {
    die "invalid token\n";
}
$payload = @parts[1];

# add correct padding for decode
$l = length($payload);
$pad = $l % 4;
if ($pad != 0) {
    $app = '=' x (4 - $pad);
    $payload = join('', $payload, $app);
}

my $decoded_payload = decode_base64url($payload);

my $inflator = inflateInit() ;
my ($base64_payload, $inf_stat) = $inflator->inflate($decoded_payload);

if ($inf_stat != Z_OK) {
    printf "inflate failed with status : ";
    printf $inf_stat;
    printf "\n";
    die;
}


$data = decode_json($base64_payload);
my $pretty = JSON->new->pretty->encode($data);
print "\n$pretty\n\n\n";

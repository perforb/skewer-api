package Skewer::API;
use strict;
use warnings;
our $VERSION = '0.01';

sub respond {
    my ($self, $req, $status, $ct, $body) = @_;
    my $res = $req->new_response($status);
    $res->content_type($ct);
    $res->body($body);
    return $res;
}

1;

package Skewer::API::Twitter;
use strict;
use warnings;
our $VERSION = '0.01';

sub call {
    my ($self, $req) = @_;

    my $res = $req->new_response(200);
    $res->content_type('text/javascript; charset=utf-8');
    $res->body('dummy');
    return $res;
}

1;

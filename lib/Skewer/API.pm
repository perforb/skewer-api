package Skewer::API;
use strict;
use warnings;
our $VERSION = '0.01';

use Plack::Response;

sub respond {
    my ($self, $status, $content_type, $body) = @_;
    my $res = Plack::Response->new($status);
    $res->content_type($content_type);
    $res->body($body);
    return $res;
}

sub mk_accessors {
    my $package = shift;
    no strict 'refs';
    foreach my $field (@_) {
        *{$package . '::' . $field} = sub {
            return $_[0]->{$field} if scalar(@_) == 1;
            return $_[0]->{$field} = scalar(@_) == 2 ? $_[1] : [ @_[ 1 .. $#_ ] ];
        };
    }
}

1;

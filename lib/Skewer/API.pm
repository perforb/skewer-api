package Skewer::API;
use strict;
use warnings;
our $VERSION = '0.01';

use Plack::Response;

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

sub respond {
    my ($self, $status, $content_type, $body) = @_;
    my $res = Plack::Response->new($status);
    $res->content_type($content_type);
    $res->body($body);
    return $res;
}

sub reduce_query_params {
    my ($self, $params, $allowing_keys, $exclusion_keys) = @_;

    $exclusion_keys ||= [];
    my $new_params = +{};
    for (@{ $allowing_keys }) {
        $new_params->{$_} = $params->{$_}
            if exists $params->{$_};
    }
    for (@{ $exclusion_keys }) {
        delete $new_params->{$_}
            if exists $new_params->{$_};
    }
    return $new_params;
}

sub debug {
    my ($self, $message) = @_;
    $self->logger('debug', $message);
}

sub error {
    my ($self, $message) = @_;
    $self->logger('error', $message);
}

sub logger {
    my ($self, $level, $message) = @_;
    $self->req->logger->({
        level   => $level,
        message => $message,
    });
}

1;

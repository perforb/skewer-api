package Skewer::API::Twitter;
use strict;
use warnings;
our $VERSION = '0.01';

use JSON;
use Redis;
use Carp ();
use Scalar::Util qw(blessed);
use LWP::Protocol::Net::Curl;
use Net::Twitter::Lite;

use Project::Libs;
use parent 'Skewer::API';
use Skewer::Config;

my $twitter_api = +{
    'search.tweets' => +{
        method => \&search_tweets,
        allowing_keys => [qw/
            q
            geocode
            lang
            locale
            result_type
            count
            until
            since_id
            max_id
            include_entities
            callback
        /],
    },
};

__PACKAGE__->mk_accessors(qw/
    req
    content_type
    apiurl
    searchapiurl
/);

sub new {
    my ($class, $args) = @_;
    my $req = delete $args->{req};
    Carp::croak("req is required")
        unless defined $req;

    bless {
        req          => $req,
        content_type => $args->{content_type} || 'application/json',
        apiurl       => $args->{apiurl}       || 'https://api.twitter.com/1.1',
        searchapiurl => $args->{searchapiurl} || 'https://api.twitter.com/1.1',
    }, $class;
}

sub call {
    my ($self) = @_;

    my $res = eval {
        my $method = $self->req->param('method');

        Carp::croak "method is required."
            unless defined $method;
        Carp::croak "method is not found."
            unless defined $twitter_api->{$method}->{method};

        $twitter_api->{$method}->{method}->($self);
    };

    if ($@) {
        my $message;
        if (blessed $@ && $@->isa('Net::Twitter::Lite::Error')) {
            $message = $@->error;
        }
        else {
            $message = $@;
        }
        $self->req->logger->({
            level   => 'error',
            message => "Caught the error: ${message}",
        });
        return $self->respond(500, $self->content_type, encode_json({
            error => 'Internal server error',
        }));
    }

    return $res;
}

sub search_tweets {
    my ($self) = @_;

    my $params = $self->req->query_parameters->as_hashref;
    my $redis  = Redis->new('server' => config->param('redis_dsn'));
    my $q      = $params->{q};
    $q =~ s/\s+/-/g;
    my $key    = join('-', $q, $params->{lang}, $params->{method});
    my $json   = $redis->get($key);

    return $self->respond(200, $self->content_type, $json)
        if defined $json;

    my $nt = Net::Twitter::Lite->new(
        consumer_key     => config->param('twitter_consumer_key'),
        consumer_secret  => config->param('twitter_consumer_secret'),
        apiurl           => $self->apiurl,
        searchapiurl     => $self->searchapiurl,
        legacy_lists_api => 0,
    );
    $nt->access_token(config->param('twitter_access_token'));
    $nt->access_token_secret(config->param('twitter_access_token_secret'));
    $params = reduce_query_params($params, [qw/callback/]);
    my $res = $nt->search($params);
    $json   = encode_json($res);
    $redis->set($key => $json);

    return $self->respond(200, $self->content_type, $json);
}

sub reduce_query_params {
    my ($params, $exclusion_list) = @_;

    $exclusion_list ||= [];
    my $new_params = +{};
    my $method = $params->{method};
    my $allowing_keys = $twitter_api->{$method}->{allowing_keys};
    for (@{ $allowing_keys }) {
        $new_params->{$_} = $params->{$_}
            if defined $params->{$_};
    }
    for (@{ $exclusion_list }) {
        delete $new_params->{$_}
            if defined $new_params->{$_};
    }
    return $new_params;
}

1;

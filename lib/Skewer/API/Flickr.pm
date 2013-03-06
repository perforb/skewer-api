package Skewer::API::Flickr;
use strict;
use warnings;
our $VERSION = '0.01';

use JSON;
use Redis;
use Carp ();
use WebService::Simple;

use Project::Libs;
use parent 'Skewer::API';
use Skewer::Config;

my $flickr_api = +{
    'flickr.photos.getInfo' => +{
        method => \&flickr_photos_getinfo,
        allowing_keys => [qw/
            photo_id
            method
            jsoncallback
        /],
    },
};

__PACKAGE__->mk_accessors(qw/
    req
    content_type
    rest_url
/);

sub new {
    my ($class, $args) = @_;
    my $req = delete $args->{req};
    Carp::croak("req is required")
        unless defined $req;

    bless {
        req          => $req,
        content_type => $args->{content_type} || 'application/json',
        rest_url     => $args->{rest_url}     || 'http://api.flickr.com/services/rest/',
    }, $class;
}

sub call {
    my ($self) = @_;

    my $res = eval {
        my $method = $self->req->param('method');

        Carp::croak "method is required."
            unless defined $method;
        Carp::croak "method is not found."
            unless defined $flickr_api->{$method}->{method};

        $flickr_api->{$method}->{method}->($self);
    };

    if ($@) {
        $self->error("Caught the error: $@");
        return $self->respond(500, $self->content_type, encode_json({
            error => 'Internal server error',
        }));
    }

    return $res;
}

sub flickr_photos_getinfo {
    my ($self) = @_;

    my $params = $self->req->query_parameters->as_hashref;
    my $redis  = Redis->new('server' => config->param('redis_dsn'));
    my $key    = join('-', $params->{photo_id}, $params->{method});
    my $json   = $redis->get($key);
    return $self->respond(200, $self->content_type, $json)
        if defined $json;

    {
        my $method = $params->{method};
        my $allowing_keys = $flickr_api->{$method}->{allowing_keys};
        $params = $self->reduce_query_params($params, $allowing_keys);
    }
    my $flickr = WebService::Simple->new(
        base_url => $self->rest_url,
        param    => $params,
        response_parser => 'JSON',
    );

    my $res = $flickr->get({
        api_key => config->param('flickr_api_key'),
        secret  => config->param('flickr_secret_key'),
        format  => 'json',
    })->parse_response;
    $json = encode_json($res);
    $redis->set($key => $json);

    return $self->respond(200, $self->content_type, $json);
}

1;

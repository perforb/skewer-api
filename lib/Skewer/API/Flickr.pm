package Skewer::API::Flickr;
use strict;
use warnings;
our $VERSION = '0.01';

use JSON;
use Redis;
use Carp ();
use WebService::Simple;
use Plack::Response;

use Project::Libs;
use parent 'Skewer::API';
use Skewer::Config;
use constant {
    CT_JSON       => 'application/json',
    REST_ENDPOINT => 'http://api.flickr.com/services/rest/',
};

my %flickr_api = (
    'flickr.photos.getInfo' => \&flickr_photos_getinfo,
);

sub call {
    my ($self, $req) = @_;

    my $res = eval {
        my $method = $req->param('method');

        Carp::croak "method is required."
            unless defined $method;
        Carp::croak "method is not found."
            unless defined $flickr_api{$method};

        $flickr_api{$method}->($self, $req);
    };

    if ($@) {
        $req->logger->({
            level   => 'error',
            message => "Caught the error: $@",
        });
        return $self->respond($req, 500, CT_JSON, encode_json({
            error => 'Internal server error',
        }));
    }

    return $res;
}

sub flickr_photos_getinfo {
    my ($self, $req) = @_;

    my $photo_id = $req->param('id') || Carp::croak "photo id is required.";
    my $method   = $req->param('method');
    my $callback = $req->param('callback');

    $photo_id =~ m/^\d+$/
        or Carp::croak "photo id is not a number.";
    $callback =~ m/^\w+$/
        or Carp::croak "Invalid format." if defined $callback;

    my $redis = Redis->new('server' => config->param('redis_dsn'));
    my $json = $redis->get($photo_id);
    return $self->respond($req, 200, CT_JSON, $json)
        if $json;

    my $params = +{
        api_key      => config->param('flickr_api_key'),
        secret       => config->param('flickr_secret_key'),
        method       => 'flickr.photos.getInfo',
        format       => 'json',
        photo_id     => $photo_id,
        jsoncallback => $callback,
    };

    delete $params->{jsoncallback}
        unless defined $params->{jsoncallback};

    my $flickr = WebService::Simple->new(
        base_url => REST_ENDPOINT,
        param    => $params,
        response_parser => 'JSON',
    );

    $json = encode_json($flickr->get()->parse_response);
    $redis->set($photo_id => $json);

    return $self->respond($req, 200, CT_JSON, $json);
}

1;

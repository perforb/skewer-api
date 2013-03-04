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

my %flickr_api = (
    'flickr.photos.getInfo' => \&flickr_photos_getinfo,
);

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
            unless defined $flickr_api{$method};

        $flickr_api{$method}->($self);
    };

    if ($@) {
        $self->req->logger->({
            level   => 'error',
            message => "Caught the error: $@",
        });
        return $self->respond(500, $self->content_type, encode_json({
            error => 'Internal server error',
        }));
    }

    return $res;
}

sub flickr_photos_getinfo {
    my ($self) = @_;

    my $photo_id = $self->req->param('id') || Carp::croak "photo id is required.";
    my $callback = $self->req->param('callback');
    my $method   = $self->req->param('method');

    $photo_id =~ m/^\d+$/
        or Carp::croak "photo id is not a number.";
    $callback =~ m/^\w+$/
        or Carp::croak "invalid format." if defined $callback;

    my $redis = Redis->new('server' => config->param('redis_dsn'));
    my $key   = "${photo_id}.${method}";
    my $json  = $redis->get($key);
    return $self->respond(200, $self->content_type, $json)
        if defined $json;

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
        base_url => $self->rest_url,
        param    => $params,
        response_parser => 'JSON',
    );

    $json = encode_json($flickr->get->parse_response);
    $redis->set($key => $json);

    return $self->respond(200, $self->content_type, $json);
}

1;

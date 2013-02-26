package Skewer::Config;
use strict;
use warnings;
our $VERSION = '0.01';

use Config::ENV 'PLACK_ENV', export => 'config';
use Config::Pit;

my $pit = pit_get('api.w-scape.net');

common +{
    twitter_api_key    => $pit->{twitter_api_key},
    twitter_secret_key => $pit->{twitter_secret_key},
    flickr_api_key     => $pit->{flickr_api_key},
    flickr_secret_key  => $pit->{flickr_secret_key},
    redis_dsn          => $pit->{redis_dsn},
};

config development => +{
    dummy => 'dummy',
};

config production => +{
    dummy => 'dummy',
};

1;

package Skewer::Config;
use strict;
use warnings;
our $VERSION = '0.01';

use Config::ENV 'PLACK_ENV', export => 'config';
use Config::Pit;

my $pit = pit_get('api.w-scape.net');

common + {
    flickr_api_key              => $pit->{flickr_api_key},
    flickr_secret_key           => $pit->{flickr_secret_key},
    twitter_consumer_key        => $pit->{twitter_consumer_key},
    twitter_consumer_secret     => $pit->{twitter_consumer_secret},
    twitter_access_token        => $pit->{twitter_access_token},
    twitter_access_token_secret => $pit->{twitter_access_token_secret},
};

config development => +{
    redis_dsn => '127.0.0.1:6379',
};

config production => +{
    redis_dsn => '127.0.0.1:6379',
};

1;

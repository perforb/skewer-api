use strict;
use warnings;

use Plack::Builder;
use Plack::Request;
use File::Spec;
use File::Basename;
use Log::Dispatch::Config;

use Project::Libs;
use Skewer::API::Twitter;
use Skewer::API::Flickr;

configure_log(
    'dispatchers'    => 'file',
    'file.class'     => 'Log::Dispatch::File',
    'file.min_level' => 'debug',
    'file.max_level' => 'emergency',
    'file.filename'  => File::Spec->catdir(dirname(__FILE__), 'log', 'skewer-api.log'),
    'file.mode'      => 'append',
    'file.format'    => '[%d] [%p] %m at %F line %L%n',
);

builder {
    enable 'LogDispatch', logger => Log::Dispatch::Config->instance;

    mount '/twitter' => builder {
        enable 'JSONP', callback_key => 'callback';
        sub {
            my $env = shift;
            my $req = Plack::Request->new($env);
            my $res = Skewer::API::Twitter->new({
                req => $req,
            })->call;
            $res->finalize;
        }
    };

    mount '/flickr' => builder {
        enable 'JSONP', callback_key => 'jsoncallback';
        sub {
            my $env = shift;
            my $req = Plack::Request->new($env);
            my $res = Skewer::API::Flickr->new({
                req => $req,
            })->call;
            $res->finalize;
        }
    };
};

sub configure_log {
    my (%options) = @_;

    my $fname = File::Spec->catdir(dirname(__FILE__), 'config', 'log.conf');
    if (-f $fname) {
        Log::Dispatch::Config->configure($fname);
        return;
    }
    open(my $fh, '>', $fname)
        or die "Cannot create the $fname: $!";
    for (keys %options) {
        print {$fh} "$_=$options{$_}\n"
            or die "Cannot write to $fname: $!";
    }
    close $fh
        or die "Cannot close the $fname: $!";
    Log::Dispatch::Config->configure($fname);
}

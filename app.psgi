use Plack::Builder;
use Plack::Request;
use File::Spec;
use File::Basename;
use Carp ();
use Log::Dispatch::Config;

use Project::Libs;
use Skewer::API::Twitter;
use Skewer::API::Flickr;

configure_log(
    'dispatchers'    => 'file',
    'file.class'     => 'Log::Dispatch::File',
    'file.min_level' => 'debug',
    'file.max_level' => 'emergency',
    'file.filename'  => File::Spec->catdir(dirname(__FILE__), 'log', 'ws-api.log'),
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
            my $res = Skewer::API::Twitter->call($req);
            return $res->finalize;
        }
    };

    mount '/flickr' => builder {
        enable 'JSONP', callback_key => 'callback';
        sub {
            my $env = shift;
            my $req = Plack::Request->new($env);
            my $res = Skewer::API::Flickr->call($req);
            return $res->finalize;
        }
    };
};

sub configure_log {
    my (%options) = @_;

    my $filepath = File::Spec->catdir(dirname(__FILE__), 'config', 'log.conf');

    if (-f $filepath) {
        Log::Dispatch::Config->configure($filepath);
        return;
    }

    open(my $fh, '>', $filepath)
        or Carp::croak "Unable to create $filepath: $!";

    for (keys %options) {
        print {$fh} "$_=$options{$_}\n"
            or Carp::croak "Unable to write to $filepath: $!";
    }

    close $fh
        or Carp::croak "Unable to close $filepath: $!";

    Log::Dispatch::Config->configure($filepath);
}

package CovidQR;

use 5.022;
use utf8;

use Plack::Builder;
use Plack::App::File;
use Plack::Request;


sub run_psgi {
    my $self = shift;

    my $api_app = sub {
        my $env = shift;

        my $req = Plack::Request->new($env);
        warn $req->content;

        return [ 200, [], ['ok'] ];
    };

    my $static_app = Plack::App::File->new( root => './dist' )->to_app;

    return builder {
        enable 'CrossOrigin' => (
            origins => '*',
            headers => [
                qw(Cache-Control Depth If-Modified-Since User-Agent X-File-Name X-File-Size X-Requested-With X-Prototype-Version Cookie Content-Type Accept)
            ]
        );
        return builder {
            mount '/'           => $static_app;
            mount '/api'        => $api_app;
            mount '/api/static' => $static_app;
        };
    };
}
1;

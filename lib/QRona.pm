package QRona;

use 5.034;
use Plack::Builder;
use Plack::App::File;
use Plack::Request;
use CheckCovidCert;
use Cpanel::JSON::XS qw(decode_json encode_json);

sub run_psgi {
    my $self = shift;

    my $api_app = sub {
        my $env = shift;

        my $req = Plack::Request->new($env);
        if (my $raw = $req->content) {
            my $payload = decode_json($raw);
            my $c3 = CheckCovidCert->new(cert => $payload->{qr}, ignore_expired => $payload->{ignore_expired});
            my $res = $c3->decode;
            return [200, ['Content-Type'=>'application/json'],[ encode_json($res) ]];
        }
        else {
            return [ 400, [], ['bad request'] ];
        }
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
        };
    };
}
1;

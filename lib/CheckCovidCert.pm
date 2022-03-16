
use 5.034;
use Object::Pad;

class CheckCovidCert {

use QRCode::Base45 qw(decode_base45);
use Compress::Zlib qw(uncompress);
use CBOR::XS ();
use MIME::Base64 qw(encode_base64);
use Cpanel::JSON::XS qw(decode_json encode_json);
use Path::Tiny qw(path);
use List::Util qw(first);
use FindBin qw($Bin);
use DateTime;
use Crypt::PK::ECC;
use Crypt::PK::RSA;

has $cert :param :reader;

# One day
has $DAY = 24*60*60;

# signing and digest algorithm
has %ALG = (
    '-7'  => { class => 'Crypt::PK::ECC', digest => 'SHA256' },
    '-35' => { class => 'Crypt::PK::ECC', digest => 'SHA384' },
    '-36' => { class => 'Crypt::PK::ECC', digest => 'SHA512' },
    '-37' => { class => 'Crypt::PK::RSA', digest => 'SHA256' },
    '-38' => { class => 'Crypt::PK::RSA', digest => 'SHA384' },
    '-39' => { class => 'Crypt::PK::RSA', digest => 'SHA512' },
);

method foo {
    use Data::Dumper; $Data::Dumper::Maxdepth=3;$Data::Dumper::Sortkeys=1;warn Data::Dumper::Dumper $ALG{-7};
}

method decode {
    my $cbor = CBOR::XS->new;

    # Remove QR-code format prefix + nl if still there
    $cert =~ s/^HC1://;
    chomp($cert);

    # Base45 -> ZLIB (optional) -> CBOR
    $cert = decode_base45($cert);
    $cert = uncompress($cert)
        if ord(bytes::substr $cert,0,1) == 120;
    my $decoded = $cbor->decode($cert);

    die('Not a Sign1 CWT document')
        unless $decoded->tag == 18 # Sign1 tag
        && ref $decoded->value eq 'ARRAY'
        && scalar $decoded->value->@* == 4; # need four elements

    # Get CWT parts
    my ($pheader_cbor, $uheader, $payload_cbor, $signature) = $decoded->value->@*;
    my $pheader = $cbor->decode($pheader_cbor);
    my $payload = $cbor->decode($payload_cbor);
    my $data    = $payload->{-260}{1};
    # see https://github.com/ehn-dcc-development/ehn-dcc-schema/tree/release/1.3.0/valuesets
    my ($valid_days,$valid_from);
    foreach my $type (qw(v r t)) { # vaccinated recovered tested
        next
            unless defined $data->{$type};
        # tg: Disease or agent targeted: COVID-19
        my $detail = first { $_->{tg} eq '840539006' }
            $data->{$type}->@*;

        if (defined $detail) {
            if ($type eq 't') {
                # tt: The type of test
                # nm: Test name (PCR only)
                # ma: Test device identifier (Antigen only)
                # tc: Name of the actor that conducted the test
                # sc: The date and time when the test sample was collected
                $valid_from = parse_date($detail->{sc});
                # Must be "Not detected"
                if ($detail->{tr} ne '260415000') {
                    fail('Positive test certificate! Go home!');
                # PCR
                } elsif ($detail->{tt} eq 'LP6464-4') {
                    $valid_days = 2;
                # Antigen (not valid after 15.11 ?)
                } elsif ($detail->{tt} eq 'LP217198-3') {
                    $valid_days = 1;
                }
            } elsif ($type eq 'v') {
                # vp = Type of the vaccine or prophylaxis used.
                # mp = Medicinal product used for this specific dose of vaccination.
                # v = Marketing authorisation holder or manufacturer
                # dn = Sequence number of the dose given during this vaccination event.
                # sd = The overall number of doses in the series
                # dt = Date of vaccination
                $valid_days = $detail->{dn} >= 3 ? 270:180;
                $valid_from = parse_date($detail->{dt});

                # Jansen
                if ($detail->{mp} eq 'EU/1/20/1525') {
                    $valid_from = $valid_from->add( days => 22 );
                }

                # Skip invalid - single Jansen jab isn't valid anymore
                if ($detail->{dn} != $detail->{sd} || $detail->{dn} == 1) {
                    $valid_from = undef;
                }
            } elsif ($type eq 'r') {
                # fr: The date when a sample for the NAAT test producing a positive result was collected
                # df: The first date on which the certificate is considered to be valid
                # du: The last date on which the certificate is considered to be valid, assigned by the certificate issuer.
                $valid_from = parse_date($detail->{df});
                $valid_days = 180;
            }
        }
    }

    # Check expiry
    fail('Certificate is not yet valid')
        if ! $valid_from || $valid_from->epoch > time;

    fail('Not a valid COVID-19 certificate')
        if !$valid_days;

        #fail('Certificate is expired')
        #    if $valid_from->add( days => $valid_days )->epoch < time;

    # Get key-id
    fail('Cannot find key id')
        unless defined $pheader->{4};
    my $key_id = encode_base64($pheader->{4});
    chomp($key_id);

    # Get signing algorithm
    fail('Can only handle ECC and RSA cryptography')
        unless defined $pheader->{1}
        && exists $ALG{$pheader->{1}};
    my $alg = $ALG{$pheader->{1}};
# Get key from trusted list
# Obtain files via
# curl https://dgcg.covidbevis.se/tp/cert -o covid_signer.crt
# curl https://dgcg.covidbevis.se/tp/trust-list | perl -MCrypt::JWT=decode_jwt -MCpanel::JSON::XS -n -E 'say encode_json(decode_jwt( token => $_, key => Crypt::PK::ECC->new("signer.crt")))' > covid_trust_list.json
my $trust_list = path('covid_trust_list.json');
fail('Trust list not found. Download first')
    unless -e $trust_list;

my $certs = decode_json($trust_list->slurp);
my $signing_cert = first { $_->{kid} eq $key_id }
    $certs->{dsc_trust_list}{$payload->{1}}{keys}->@*;
fail('Signed with an untrusted certificate')
    unless $signing_cert;
  # TODO check eku
  # $certs->{dsc_trust_list}{$payload->{1}}{eku}{$key_id}
  # OID 1.3.6.1.4.1.0.1847.2021.1.1 -- valid for test
  # OID 1.3.6.1.4.1.0.1847.2021.1.2 -- valid for vaccinations
  # OID 1.3.6.1.4.1.0.1847.2021.1.3 -- valid for recovery

# Build certificate
my $x509cert = $signing_cert->{x5c}[0];
my $public_key = $alg->{class}->new(\qq[-----BEGIN CERTIFICATE-----
${x509cert}
-----END CERTIFICATE-----]);

# Build COSE signature
my $to_be_signed = $cbor->encode([
    # context
    CBOR::XS::as_text('Signature1'),
    # protected header
    $pheader_cbor,
    # external aad
    CBOR::XS::as_bytes(''),
    # cbor payload
    $payload_cbor,
]);

# Check signature
fail('Could not verify signature')
    unless $public_key->verify_message_rfc7518($signature,$to_be_signed,$alg->{digest});

# Success
my $name = $payload->{-260}{1}{nam};

#use Data::Dumper; $Data::Dumper::Maxdepth=5;$Data::Dumper::Sortkeys=1;warn Data::Dumper::Dumper $payload;

    return {
        type => 'success',
        given_name => $name->{gn},
        fist_name => $name->{fn},
    }
}

sub fail {
    die(@_);
}

sub parse_date {
    my $date = shift;
    if ($date =~ m/^
        (?<year>20\d\d)
        -
        (?<month>\d\d)
        -
        (?<day>\d\d)
        (?:
            T
            (?<hour>\d\d)
            :
            (?<minute>\d\d)
            :
            (?<second>\d\d)
            (?<tz>
                Z
                |
                [+-]
                \d\d
                (?:
                    :?
                    \d\d
                )?
            )
        )?
        $/x) {
        my $tz = $+{tz} // 'local';
        $tz = 'UTC'
            if $tz eq 'Z';
        return DateTime->new(
            (map { $_ => $+{$_} // 0 } qw(year month day hour minute second)),
            time_zone => $tz,
        )
    }
    fail('Could not parse date: '.$date)
}

}

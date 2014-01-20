package App::WebSNMP::Client;

use Mojo::Base 'Mojo::EventEmitter';
use Mojo::JSON 'j';
use Mojo::Util qw/slurp spurt/;

# Try to avoid using 3rd-party modules
#use AnyEvent::DNS; # Rewrite the srv code with Mojo::IOLoop::Client?
use Sys::Hostname::FQDN qw/short fqdn/; # Build this in
my ($domainname) = fqdn() =~ /${\(short())}\.(.*)/;
#my $cv = AnyEvent->condvar;

our $VERSION = "0.01";

use File::Spec::Functions 'catfile';
use Time::HiRes 'time';
use Math::Prime::Util;

use constant {
  FATAL => 1000,
};

my $retry = 0;
my $counter = 0;

has 'test';

has version => sub { $VERSION };
has protocol => sub { int $_[1] || $VERSION };

has 'tid';
has 'ua';
has 'tx';

has 'public_uuid' => sub { shift->_uuid('state', 'registration.pub') };
has 'private_uuid' => sub { shift->_uuid('state', 'registration') }; # Meant to be sent manually by CLI
has log => sub { Mojo::Log->new };
has app => sub { shift->{app} };
has config => sub { shift->app->config->{client} };
has confdir => sub { my $self = shift; $self->{confdir} || $self->app->config->{confdir} || $self->app->home };

sub new {
  my $self = shift->SUPER::new(@_);
  $self->tid(Mojo::IOLoop->recurring(1 => sub {
warn "Trying....\n";
    $self->ping and return;
    return if $self->_wait_prime;
    $self->_advance_prime;
    $self->ua(Mojo::UserAgent->new);
    my $websnmp_url;
    unless ( $websnmp_url ) { # Expire this value sometimes to check DNS again.
      #AnyEvent::DNS::srv ($self->{srv}->{service}||"websnmp"), ($self->{srv}->{proto}||"tcp"), ($self->{srv}->{domain}||$domainname||'local'), $cv;
      $websnmp_url = '';#join(':', @{$cv->recv}[3,2]);
      $websnmp_url ||= 'localhost:3000';
      $self->app->log->debug("Master URL: $websnmp_url");
    }
    $self->ua->websocket("ws://$websnmp_url/server" => sub {
      my ($ua, $tx) = @_;
      $self->log->error(sprintf "I am an Agent (%s), Websocket handshake failed: %s", $self->public_uuid, $tx->error) and return unless $tx->is_websocket;
      $retry = 0;
      $self->tx($tx);
      $self->log->debug(sprintf 'I am an Agent, my New TX: %s', $self->tx);
      $self->tx->on(error => sub { $self->log->error(sprintf 'I am an Agent, TX error: %s', $_[1]) });
      $self->tx->on(finish => sub {
        my ($ws, $code, $reason) = @_;
        $self->log->debug(sprintf 'I am an Agent (%s), TX finish: %s - %s', $self->public_uuid, $code, $reason);
        $self->tx(undef); # This is necessary
        $retry = 10 if $code == FATAL;
      });
      #$self->tx->on(frame => sub {
      #  my ($ws, $frame) = @_;
      #  $self->app->log->debug(sprintf 'I am an Agent (%s), my MANAGER responded: %s', $self->public_uuid, $frame->[5]);
      #});
      $self->tx->on(json => sub {
        my ($ws, $json) = @_;
        $ws->emit($json->{_} => $json);
      });
    }) unless $self->tx && $self->tx->is_websocket;
  })) unless $self->tid;
  $self;
}

sub probe {
  my $self = shift;
  Mojo::IOLoop->recurring(4 => sub {
    say "PROBING";
  });
}

sub upload {
  Mojo::IOLoop->recurring(4 => sub {
    say "UPLOADING";
  });
}

sub ping {
  my $self = shift;
  return undef unless $self->tx && $self->tx->is_websocket;
  $self->tx->send([1, 0, 0, 0, 9, join ':', $self->version, time, $self->public_uuid]);
}

sub _wait_prime {
  my $self = shift;
  $self->log->info(sprintf "I am an Agent, attempting to connect to MANAGER (%s) in %s seconds...", $self, $retry) if $retry && !$counter;
  $counter++;
  $counter < $retry;
}
sub _advance_prime {
  my ($self, $next) = @_;
  $counter = 0;
  $retry = 60*5 if $retry > 60*15;
  $retry = Math::Prime::Util::next_prime($retry);
}

sub _uuid {
  my $self = shift;
  my $file = pop @_;
  my $dir = catfile $self->confdir, @_;
  $file = catfile $dir, $file;
  my $uuid = join "-", map { unpack "H*", $_ } map { substr pack("I", (((int(rand(65536)) % 65536) << 16) | (int(rand(65536)) % 65536))), 0, $_, "" } ( 4, 2, 2, 2, 6 );
  if ( -e $file ) {
    return slurp $file;
  } else {
    mkdir $dir;
    chmod 0700, $dir;
    return spurt $uuid, $file;
  }
}

1;

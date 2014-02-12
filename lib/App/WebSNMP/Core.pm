package App::WebSNMP::Core;

use Mojo::Base -base;
use Mojo::Util qw/slurp spurt/;
use Mojo::Log;

# Try to avoid using non-standard 3rd-party modules
use File::Spec::Functions 'catfile';
use AnyEvent::DNS; # Rewrite the srv code with Mojo::IOLoop::Client?
use Sys::Hostname::FQDN qw/short fqdn/; # Build this in

our $VERSION = "0.01";

# TLS support requires IO::Socket::SSL
use constant IPV6 => 1;
use constant TLS => $ENV{MOJO_NO_TLS} ? 0
  : eval(IPV6 ? 'use IO::Socket::SSL 1.75 (); 1'
  : 'use IO::Socket::SSL 1.75 "inet4"; 1');

has log => sub { Mojo::Log->new };
has config => sub { shift->{config} };
has version => sub { $VERSION };
has protocol => sub { int $_[1] || $VERSION };
has 'public_uuid' => sub { shift->_uuid('state', 'registration.pub') };
has 'private_uuid' => sub { shift->_uuid('state', 'registration') }; # Meant to be sent manually by CLI
has confdir => sub { my $self = shift; $self->app->config->{confdir} || $self->app->home };

sub srv { # Cache this
  my $self = shift;
  my $cv = AnyEvent->condvar;
  my ($domainname) = fqdn() =~ /${\(short())}\.(.*)/;
  #AnyEvent::DNS::srv ($self->config->{service}||"websnmp"), ($self->config->{proto}||"tcp"), ($self->config->{domain}||$domainname||'local'), $cv;
  my $url = $cv->recv ? join(':', @{$cv->recv}[3,2]) : 'localhost';
  $url = TLS ? "wss://$url/server" : "ws://$url/server";
  $self->log->debug("Server URL: $url");
  $url;
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

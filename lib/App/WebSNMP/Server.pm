package App::WebSNMP::Server;

use Mojo::Base -base;
use Mojo::JSON 'j';

use Time::HiRes 'time';

use constant {
  FATAL => 1000,
  FATAL_PROTOCOL => 'Version protocol mismatch',
  FATAL_TIME => 'Time off by more than %s seconds',
};

has 'test';
has app => sub { shift->{app} };

sub new {
  my $self = shift->SUPER::new(@_);
  my $r = $self->app->routes;
  $r->get('/SERVER')->to(cb => sub { shift->render(text => "SERVER\n") });
  $self;
}

sub websocket {
  my $self = shift;
  $self->app->log->debug(sprintf 'I am a Manager, my New TX: %s %s', $self->tx, $self);
  Mojo::IOLoop->stream($self->tx->connection)->timeout(15);
  $self->on(error => sub { $self->app->log->error("I am a Manager, TX error: $_[1]") });
  $self->on(frame => sub {
    my ($ws, $frame) = @_;
    my ($version, $time, $uuid) = split /:/, $frame->[5];
    $self->app->log->debug(sprintf 'I am a Manager (%s), an AGENT (%s) said: %s:%s', $ws->tx, $uuid, $version, $time);
    #$version='1.01';
    $self->tx->finish(1000 => FATAL_PROTOCOL) and return $self->app->log->fatal(FATAL_PROTOCOL) unless $self->app->protocol($self->app->version) == $self->app->protocol($version);
    #$time = time + 3600;
    $self->tx->finish(1000 => sprintf FATAL_TIME, 120) and return $self->app->log->fatal(sprintf FATAL_TIME, 120) unless abs($time-time()) <= 120;
  });
  $self->tx->on(json => sub {
    my ($ws, $json) = @_;
    $ws->emit($json->[0] => $json->[1]);
  });
}

1;

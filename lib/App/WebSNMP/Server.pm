package App::WebSNMP::Server;

use Mojo::Base -base;

has 'test';
has app => sub { shift->{app} };

sub new {
  my $self = shift->SUPER::new(@_);
  my $r = $self->app->routes;
  $r->get('/SERVER')->to(cb => sub { shift->render(text => "SERVER\n") });
#  $r->get('/snmpwalk/*oid')->to(cb => sub {
#    my $c = shift;
#    $self->app->log->debug(sprintf "%s", $c->param('oid')||'1.3.6.1.2.1.1');
#    $c->render(text => dumper $self->app->websnmp->snmpwalk($c->param('oid')||'1.3.6.1.2.1.1'));
#  });
  $self;
}

1;

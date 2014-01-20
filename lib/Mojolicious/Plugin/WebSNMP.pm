package Mojolicious::Plugin::WebSNMP;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Util 'dumper';

our $VERSION = '0.01';

has 'app';
has 'conf';
has client => sub { use App::WebSNMP::Client; App::WebSNMP::Client->new({app=>shift->app}) };
has server => sub { use App::WebSNMP::Server; App::WebSNMP::Server->new({app=>$_[0]->app, conf=>$_[0]->conf}) };

sub register {
  my ($self, $app, $conf) = @_;

  $self->app($app);
  $self->conf($conf);
  $app->plugin('NetSNMP');
  $app->helper(client => sub { $self->client });
  $app->helper(server => sub { $self->server });

  $self->server->test('123');
  warn $self->server->test;

  my $r = $app->routes;
  $r->get('/Server')->to(cb => sub { shift->render(text => "Server\n") });
  $r->get('/snmpwalk/*oid')->to(cb => sub {
    my $c = shift;
    $app->log->debug(sprintf "%s", $c->param('oid')||'1.3.6.1.2.1.1');
    $c->render(text => dumper $app->snmpwalk($c->param('oid')||'1.3.6.1.2.1.1'));
  });
  $r->websocket('/server')->to('server#websocket');
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::WebSNMP - Mojolicious Plugin

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('WebSNMP');

  # Mojolicious::Lite
  plugin 'WebSNMP';

=head1 DESCRIPTION

L<Mojolicious::Plugin::WebSNMP> is a L<Mojolicious> plugin.

=head1 METHODS

L<Mojolicious::Plugin::WebSNMP> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut

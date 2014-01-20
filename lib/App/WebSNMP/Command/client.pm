package App::WebSNMP::Command::client;

use Mojo::Base 'Mojolicious::Command';

has description => "Start WebSNMP client.\n";
has usage => <<"EOF";
usage: $0 client
EOF

has config => sub { shift->app->config->{client} };

#has client => sub { use App::WebSNMP::Client; App::WebSNMP::Client->new({app=>shift->app}) };

sub run {
  my($self, @args) = @_;

  my $loop = Mojo::IOLoop->singleton;
  $SIG{QUIT} = sub { $loop->max_connnections(0) };

  #$self->app->client->test('abc'); # if $self->config;
  warn $self->app->client->test, "\n";

  Mojo::IOLoop->recurring(1 => sub { warn sprintf "%s\n", scalar localtime });
  $loop->start;
  return 0;
}

1;

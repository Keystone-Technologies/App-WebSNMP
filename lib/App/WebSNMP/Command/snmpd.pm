package App::WebSNMP::Command::snmpd;

use Mojo::Base 'Mojolicious::Command';

has description => "Start Net-SNMP daemon with AgentX support.\n";
has usage => <<"EOF";
usage: $0 snmpd

  Requires root priviledges
EOF

has config => sub { shift->app->config->{client} };

sub run {
  my($self, @args) = @_;

  die $self->help unless $self->_user_is_root;

  system("snmpd", "-f", "-Lo", "-C", "--rwcommunity=public", "--master=agentx");
}

sub _user_is_root { $> == 0 || $< == 0 }

1;

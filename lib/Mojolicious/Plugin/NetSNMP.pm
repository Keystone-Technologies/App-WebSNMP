package Mojolicious::Plugin::NetSNMP;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.01';

use Net::SNMP;
use SNMP;

has 'snmp';

sub register {
  my ($self, $app, $conf) = @_;

  $conf->{netsnmp}->{'-hostname'} ||= 'localhost';
  $conf->{netsnmp}->{'-community'} ||= 'public';

  my ($session, $error) = Net::SNMP->session(%{$conf->{netsnmp}});
  unless ( defined $session ) {
    $app->log->error(sprintf "Net-SNMP ERROR: %s", $error);
    return undef;
  }

  $SNMP::use_long_names = $conf->{snmp}->{use_long_names} || 0;

  $self->snmp($session);
  $app->helper(snmp => sub { $self->snmp });
  $app->helper(snmpwalk => sub {
    my $c = shift;
    my $snmp = $self->snmp->get_table(-baseoid => shift);
    $conf->{translate} ? $c->snmptranslate($snmp) : $snmp;
  });
  $app->helper(snmptranslate => sub { shift; my $snmp = shift; return { map { SNMP::translateObj($_) => $snmp->{$_} } keys %$snmp } });
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::NetSNMP - Mojolicious Plugin

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('NetSNMP');

  # Mojolicious::Lite
  plugin 'NetSNMP';

=head1 DESCRIPTION

L<Mojolicious::Plugin::NetSNMP> is a L<Mojolicious> plugin.

=head1 METHODS

L<Mojolicious::Plugin::NetSNMP> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut

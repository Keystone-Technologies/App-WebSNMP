package App::WebSNMP::Command::snmp_agent;

use Mojo::Base 'Mojolicious::Command';

has description => "Start SNMP AgentX agent.\n";
has usage => <<"EOF";
usage: $0 snmp_agent

  Requires root priveleges to connect to the SNMP Master
EOF

use NetSNMP::agent (':all');
use NetSNMP::ASN qw(ASN_OCTET_STR);

chomp(my $value = qx{hostname -d});
my $value2 = "Hello, World!";

my $agent = new NetSNMP::agent(
  # makes the agent read a my_agent_name.conf file
  'Name' => "my_agent_name",
  'AgentX' => 1
);
$agent->register("my_agent_name", ".1.3.6.1.4.1.8072.9999.9999.7375", sub {
  my ($handler, $registration_info, $request_info, $requests) = @_;
  my $request;

  for($request = $requests; $request; $request = $request->next()) {
    my $oid = $request->getOID();
    if ($request_info->getMode() == MODE_GET) {
      # ... generally, you would calculate value from oid
      if ($oid == new NetSNMP::OID(".1.3.6.1.4.1.8072.9999.9999.7375.1.0")) {
        $request->setValue(ASN_OCTET_STR, $value);
      } elsif ($oid == new NetSNMP::OID(".1.3.6.1.4.1.8072.9999.9999.7375.2.0")) {
        $request->setValue(ASN_OCTET_STR, $value2);
      }
    } elsif ($request_info->getMode() == MODE_GETNEXT) {
      # ... generally, you would calculate value from oid
      if ($oid < new NetSNMP::OID(".1.3.6.1.4.1.8072.9999.9999.7375.1.0")) {
        $request->setOID(".1.3.6.1.4.1.8072.9999.9999.7375.1.0");
        $request->setValue(ASN_OCTET_STR, $value);
      } elsif ($oid < new NetSNMP::OID(".1.3.6.1.4.1.8072.9999.9999.7375.2.0")) {
        $request->setOID(".1.3.6.1.4.1.8072.9999.9999.7375.2.0");
        $request->setValue(ASN_OCTET_STR, $value2);
      }
    } elsif ($request_info->getMode() == MODE_SET_RESERVE1) {
      if ($oid != new NetSNMP::OID(".1.3.6.1.4.1.8072.9999.9999.7375.1.0")) {  # do error checking here
        $request->setError($request_info, SNMP_ERR_NOSUCHNAME);
      } elsif ($oid != new NetSNMP::OID(".1.3.6.1.4.1.8072.9999.9999.7375.2.0")) {  # do error checking here
        $request->setError($request_info, SNMP_ERR_NOSUCHNAME);
      }
    } elsif ($request_info->getMode() == MODE_SET_ACTION) {
      # ... (or use the value)
      $value = $request->getValue();
    }
  }
});

sub run {
  my($self, @args) = @_;

  die $self->help unless $self->_user_is_root;

  my $loop = Mojo::IOLoop->singleton;
  $SIG{QUIT} = sub { $loop->max_connnections(0) };

  Mojo::IOLoop->recurring(0 => sub {
    #warn sprintf "%s\n", scalar localtime;
    $agent->agent_check_and_process(0);
  });
  $loop->start;
  $agent->shutdown();
  return 0;
}

sub _user_is_root { $> == 0 || $< == 0 }

1;

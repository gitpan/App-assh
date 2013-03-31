package App::assh;
BEGIN {
  $App::assh::AUTHORITY = 'cpan:DBR';
}
{
  $App::assh::VERSION = '0.1.0';
}

#  PODNAME: App::assh
# ABSTRACT: A wrapper around autossh.

use Moo;
use true;
use 5.010;
use strict;
use warnings;
use methods-invoker;
use MooX::Options skip_options => [qw<os cores>];
use MooX::Types::MooseLike::Base qw(:all);

has hosts => (
    is => 'lazy',
    isa => HashRef,
);

has ports => (
    is => 'lazy',
    isa => HashRef,
);

has ssh_config_file => (
    is => 'ro',
    isa => Str,
    default => sub {
        "$ENV{HOME}/.ssh/config"
    },
);

has ports_config_file => (
    is => 'ro',
    isa => Str,
    default => sub {
        "$ENV{HOME}/.autossh_rc"
    },
);

method _build_hosts {
    $_ = do { local(@ARGV, $/) = $->ssh_config_file; <>; };
    s/\s+/ /g;

    my $ret = {};
    while (m<Host\s(.+?)\sHostName\s(.+?)\sUser\s(.+?)\s>xg) {
        $ret->{$1} = { NAME => $2, USER => $3 }
    }

    return $ret;
}

method _build_ports {
    open my $portsfile, "<", $->ports_config_file or die $!;
    my $h = {};
    while(<$portsfile>) {
        chomp;
        my ($host, $port) = split;
        $h->{$host} = $port;
    }
    return $h
}

method run {
    my $host = shift;

    not defined $host and do {
        say for keys %{$->hosts};
    };

    defined $->hosts->{$host} and do {
        $->autossh_exec($host);
    };
}

method autossh_exec {
    my $host = shift;
    exec 'AUTOPOLL=5 autossh -M ' . $->ports->{$host} . ' ' . $->hosts->{$host}{USER} . '@' . $->hosts->{$host}{NAME}
}

no Moo;



__END__
=pod

=encoding utf-8

=head1 NAME

App::assh - A wrapper around autossh.

=head1 VERSION

version 0.1.0

=head1 SYNOPSIS

A wrapper around autossh.

=for Pod::Coverage ports_config_file  ssh_config_file

=head1 USAGE

     assh
 
     assh HOSTNAME

=head1 ATTRIBUTES

=over

=item *

hosts: HashRef holding the values HOSTNAME =E<gt> AUTOSSH_PORT

=back

=over

=item *

ports: HashRef holding the values HOSTNAME =E<gt> C<<< USER => USERNAME, HOST => HOSTNAME >>>

=back

=over

=item *

ssh_config_file: The path to the ssh config file. Default: `~E<sol>.sshE<sol>config`

=back

=over

=item *

ports_config_file: The path to the ports config (this is what I have chosen): `~E<sol>.autossh_rc`

=back

=head1 AUTHOR

DBR <dbr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by DBR.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


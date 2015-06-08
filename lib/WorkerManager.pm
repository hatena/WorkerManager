package WorkerManager;
use strict;
use warnings;

use Carp;
use Parallel::ForkManager;
use UNIVERSAL::require;
use Time::Piece;
use IO::Handle;
use IO::File;
our $LOGGER;

our $VERSION = '0.001';

sub new {
    my $class = shift;
    my %args = @_;
    if (@_ % 2) {
        Carp::croak("Odd number of elements: " . __PACKAGE__ . "::new");
    }

    my $self = bless {
        max_processes => 4,
        works_per_child => 100,
        @_,
        pids => {},
    };

    $self->init;
    $self;
}

BEGIN {
    $LOGGER = sub {
        my ($class, $msg) = @_;
        print localtime->datetime, " $class\[$$\]: $msg\n";
    };
}

my $fh;
sub open_logs {
    my $self = shift;

    if ($self->{log_file}) {
        $fh = IO::File->new(">>" . $self->{log_file});
        $fh->autoflush(1);
        $LOGGER = sub {
            my ($class, $msg) = @_;
            $msg =~ s/\s+$//;
            $fh ||= IO::File->new(">>" . $self->{log_file});
            $fh->print(localtime->datetime. " $class\[$$\]: $msg\n");
        };
    }

    if ($self->{error_log_file}) {
#        close STDOUT;
#        close STDERR;

        open(STDOUT, ">>" . $self->{error_log_file})
            or die "Failed to re-open STDOUT to ". $self->{error_log_file};
        open STDERR, ">>&STDOUT"     or die "Can't dup STDOUT: $!";
        STDOUT->autoflush(1);
        STDERR->autoflush(1);
    }
}

sub init {
    my $self = shift;

    for my $key (keys %{$self->{env}}) {
        $ENV{$key} = $self->{env}{$key} if !defined $ENV{$key};
    }

    my $worker_client_class = "WorkerManager::" . $self->{type};
    $worker_client_class->use or die $@;

    $self->{pm} = Parallel::ForkManager->new($self->{max_processes})
        or die("Unable to create ForkManager object: $!\n");

    $self->{pm}->run_on_finish(
        sub { my ($pid, $exit_code, $ident) = @_;
              $LOGGER->('WorkerManager', "Child $ident exited with PID $pid and exit code: $exit_code");
              delete $self->{pids}->{$pid};
          }
    );

    $self->{pm}->run_on_start(
        sub { my ($pid,$ident)=@_;
              $LOGGER->('WorkerManager', "$ident started with PID $pid");
              $self->{pids}->{$pid} = $ident;
              #print join(',', map {"$_($self->{pids}->{$_})"} keys %{$self->{pids}});
              #print "\n";
          }
    );
    $self->{pm}->run_on_wait(
        sub {
            if ($self->{terminating}) {
                $self->{pm}->run_on_wait(undef, undef);
                die 'TERMINATING';
            }
        },
        1
    );

    $self->{count} = 0;
    $self->{terminating} = undef;

    $self->open_logs;
    $self->set_signal_handlers;
}

sub set_signal_handlers {
    my $self = shift;

    setpgrp;
    $SIG{QUIT} = $SIG{TERM} = sub {
        my $sig = shift;
        $LOGGER->('WorkerManager', "Received $sig. trying to terminate children gracefully");
        $self->{terminating} = 1;
        $self->{client}->terminate if $self->{client};
    };

    $SIG{INT} = sub {
        my $sig = shift;

        unless ($self->{terminating}) {
            $LOGGER->('WorkerManager', "Received $sig. trying to terminate children gracefully");
            $self->{terminating} = 1;
            $self->{client}->terminate if $self->{client};
        } else {
            $LOGGER->('WorkerManager', "Received $sig. killing all children");
            $self->killall_children unless $self->{pm}->{in_child};
        }
    };

    $SIG{HUP} = sub {
        my $sig = shift;
        $self->open_logs;
        $self->signal_all_children('HUP');
    };
}

sub set_signal_handlers_for_child {
    my $self = shift;

    setpgrp;
    $SIG{QUIT} = $SIG{TERM} = sub {
        my $sig = shift;
        $LOGGER->('WorkerManager', "Child received $sig");
        $self->{client}->terminate;
    };

    $SIG{INT} = sub {
        my $sig = shift;
        $LOGGER->('WorkerManager', "Child received $sig");
        $self->{pm}->finish;
    };

    $SIG{HUP} = sub {
        my $sig = shift;
        $self->open_logs;
    };
}

sub signal_all_children {
    my $self = shift;
    my $sig = shift;
    return unless scalar(keys %{$self->{pids}});
    $LOGGER->('WorkerManager', "sending $sig to children: " . join(',', keys %{$self->{pids}}));
    kill $sig, $_ for keys %{$self->{pids}};
}

sub terminate_all_children {
    my $self = shift;
    $self->signal_all_children('TERM');
}

sub killall_children {
    my $self = shift;
    $self->signal_all_children('INT');
}

sub reopen_children {
    my $self = shift;
    $self->signal_all_children('TERM');
}

sub main {
    my $self = shift;
    eval {
        # startループから抜けるためのeval
        while (!$self->{terminating}) {
            my $pid = $self->{pm}->start(++$self->{count}) and next;
            last unless $self->{pm}->{in_child};
            $self->set_signal_handlers_for_child;
            $0 .= " [child process $self->{count}]";
            my $worker_client_class = "WorkerManager::" . $self->{type};
            $self->{client} = $worker_client_class->new($self->{worker}, $self->{worker_options}) or die;
            $self->{client}->work($self->{works_per_child});
            $self->{pm}->finish;
        }
    };
    if ($@) {
        die $@ if $self->{pm}->{in_child};
    }
    $self->terminate_all_children;
    local $SIG{ALRM} = sub {
        $LOGGER->('WorkerManager', "Timeout to terminate children");
        $self->killall_children;
    };
    alarm($self->{wait_terminating} || 10);
    $self->{pm}->wait_all_children;
    alarm 0;

}

1;

__END__

=encoding utf-8

=head1 NAME

WorkerManager - A framework for dealing with workers of TheSchwartz

=head1 SYNOPSIS

    use WorkerManager;

=head1 DESCRIPTION

...

=head1 LICENSE

Copyright (C) Hatena Co., Ltd..

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

aereal E<lt>aereal@aereal.orgE<gt>

Original implementation written by stanaka.

=cut


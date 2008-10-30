package WorkerManager;
use strict;
use warnings;

use Parallel::ForkManager;
use UNIVERSAL::require;
use Time::Piece;

our $LOG;
our $LOGFILE;
our $LOGGER = sub {
    my $class = shift;
    my $msg = shift;
    $msg =~ s/\s+$//;
    if(!$LOG && $LOGFILE) {
        open($LOG, ">>".$LOGFILE)
            or die "Failed to open ".$LOGFILE;
    }
    if($LOG && $LOGFILE){
        print $LOG localtime->datetime. " $class $msg\n";
        close($LOG);
        undef $LOG;
    } else {
        print localtime->datetime. " $class $msg\n";
    }
};

sub new {
    my $class = shift;
    my %args = @_;
    $args{pids} = {};
    $args{max_processes} ||= 4;
    $args{works_per_child} ||= 100;
    my $self = bless \%args, $class;
    $self->init;
    $self;
}

sub init {
    my $self = shift;


    my $worker_client_class = "WorkerManager::" . $self->{type};
    $worker_client_class->use or die $@;
    $self->{client} = $worker_client_class->new($self->{worker}, $self->{worker_options}) or die;

    $self->{pm} = Parallel::ForkManager->new($self->{max_processes})
        or die("Unable to create ForkManager object: $!\n");

    $self->{pm}->run_on_finish(
        sub { my ($pid, $exit_code, $ident) = @_;
              $LOGGER->('WorkerManager', "$ident exited with PID $pid and exit code: $exit_code");
              delete $self->{pids};
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

    $self->{count} = 0;
    $self->{interruptted} = undef;
    $self->{terminating} = undef;

    $self->set_signal_handlers;
}


sub set_signal_handlers {
    my $self = shift;

    setpgrp;
    my $interrupt_handle = sub {
        my $sig = shift;

        $self->{interruptted} = 1;
        if ($self->{pm}->{in_child}) {
            $self->{client}->terminate;
        } else {
            $self->killall_children;
            $self->{pm}->wait_all_children;
        }
        die "killed by $sig. ($$)";
        exit(0);
    };

    $SIG{INT} = $interrupt_handle;
    $SIG{HUP} = $interrupt_handle;
    $SIG{QUIT} = $interrupt_handle;

    my $terminate_handle = sub {
        my $sig = shift;
        return if $self->{terminating};
        $self->{terminating} = 1;
        $SIG{$sig} = 'IGNORE';
        if ($self->{pm}->{in_child}) {
            $self->{client}->terminate;
        } else {
            $self->terminateall_children;
        }
        return;
    };

    $SIG{TERM} = $terminate_handle;
}

sub killall_children {
    my $self = shift;
    warn "killing. children: " . join(",", keys %{$self->{pids}});
    kill "INT", $_ for keys %{$self->{pids}};
}

sub terminateall_children {
    my $self = shift;
    warn "terminating. children: " . join(",", keys %{$self->{pids}});
    kill "TERM", $_ for keys %{$self->{pids}};
}

sub main {
    my $self = shift;
    while (!$self->{interruptted} || !$self->{terminating}) {
        my $pid = $self->{pm}->start($self->{count}++) and next;
        $self->{client}->work($self->{works_per_child});
        $self->{pm}->finish;
    }
    $self->{pm}->wait_all_children;
}

1;

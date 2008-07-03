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
    if($LOG){
        print $LOG localtime->datetime. " $class $msg\n";
        close($LOG);
        undef $LOG;
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

    "WorkerManager::$self->{type}"->use or die $@;
    $self->{client} =  "WorkerManager::$self->{type}"->new($self->{worker});

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
}

sub main {
    my $self = shift;
    my $count = 1;
    while (1) {
        my $pid = $self->{pm}->start($count++) and next;

        $self->{client}->work($self->{works_per_child});
        $self->{pm}->finish;
    }
    $self->{pm}->wait_all_children;
}

sub killall {
    my $self = shift;
    foreach (keys %{$self->{pids}}){
        kill("TERM", $_);
    }
}

1;


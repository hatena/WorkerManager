package WorkerManager;
use strict;
use warnings;

use Parallel::ForkManager;
use UNIVERSAL::require;

sub new {
    my $class = shift;
    my %args = @_;
    $args{pids} = {};
    $args{max_processes} ||= 4;
    my $self = bless \%args, $class;
    $self->init;
    $self;
}

sub init {
    my $self = shift;

    ($self->{type})->require or die $@;
    ($self->{type})->new($self->{worker});

    $self->{pm} = Parallel::ForkManager->new($self->{max_processes})
        or die("Unable to create ForkManager object: $!\n");

    $self->{pm}->run_on_finish(
        sub { my ($pid, $exit_code, $ident) = @_;
              print "** $ident just got out of the pool ".
                  "with PID $pid and exit code: $exit_code\n";
              delete $self->{pids};
          }
    );

    $self->{pm}->run_on_start(
        sub { my ($pid,$ident)=@_;
              print "** $ident started, pid: $pid\n";
              $self->{pids}->{$pid} = $ident;
              print join(',', map {"$_($self->{pids}->{$_})"} keys %{$self->{pids}});
              print "\n";
          }
    );
}

sub main {
    my $self = shift;
    my $count = 1;
    while (1) {

        my $pid = $self->{pm}->start($count++) and next;

        #$worker->work while 1;
        sleep 10;
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


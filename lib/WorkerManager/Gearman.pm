package WorkerManager::Gearman;
use strict;
use warnings;

use Gearman::Worker;

sub new {
    my $class = shift;
    bless {
        worker => Gearman::Worker->new,
    },$class;
}

sub init {
    my $self = shift;
    $self->{worker}->job_servers('localhost');
    $self->{worker}->register_function(
        sum => sub {
            my $job = shift;
            my @args = @{thaw($job->arg)};
            
            return sum @args;
        }
            # ........
    );
}

sub work {
    my $self = shift;

    $self->{worker}->work;
}

1;

package WorkerManager::Client::TheSchwartz;
use strict;
use warnings;

use TheSchwartz;

sub new {
    my $class = shift;
    my $client = TheSchwartz->new( databases =>
                                       [+{ dsn => 'dbi:mysql:dbname=theschwartz;host=192.168.3.54', user => 'nobody', pass => 'nobody' }] );
    my $self = bless {
        client => $client,
    },$class;
    $self;
}

sub insert {
    my $self = shift;
    my $funcname = shift;
    my $arg = shift;
    my $options = shift;

    my $job = TheSchwartz::Job->new(funcname => $funcname,
                                    arg => $arg,
                                    run_after => $options->{run_after} ||= time,
                                    grabbed_until => $options->{grabbed_until} || 0);
    $self->{client}->insert($job);
}

1;

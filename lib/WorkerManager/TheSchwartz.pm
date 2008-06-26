package WorkerManager::TheSchwartz;
use strict;
use warnings;

use TheSchwartz;

sub new {
    my $class = shift;
    my $client = TheSchwartz->new( databases =>
                                       [+{ dsn => 'dbi:mysql:dbname=theschwartz;host=192.168.3.54', user => 'nobody', pass => 'nobody' }] );
    my $ability = shift;
    bless {
        client => $client,
        worker => $ability;
    },$class;
}

sub init {
    my $self = shift;
    $self->{client}->can_do($self->{worker});
}

sub work {
    my $self = shift;
    my $max = shift || 5;
    my $delay = shift || 5;
    my $count = 0;
    while ($count++ < $max) {
        sleep $delay unless $self->{client}->work_once;
    }
}

1;

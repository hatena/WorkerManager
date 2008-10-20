package WorkerManager::Client::TheSchwartz;
use strict;
use warnings;

use DBI;
use TheSchwartz::Simple;

sub new {
    my $class = shift;

    my $dbh = DBI->connect('dbi:mysql:dbname=theschwartz;host=192.168.3.54', 'nobody', 'nobody');
    my $client = TheSchwartz::Simple->new([$dbh]);
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

    my $job = TheSchwartz::Simple::Job->new;
    $job->funcname($funcname);
    $job->arg($arg);
    $job->run_after($options->{run_after} || time);
    $job->grabbed_until($options->{grabbed_until} || 0);
    $job->uniqkey($options->{uniqkey} || undef);

    $self->{client}->insert($job);
}

1;

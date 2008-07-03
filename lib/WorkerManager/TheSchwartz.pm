package WorkerManager::TheSchwartz;
use strict;
use warnings;

use TheSchwartz;
use Time::Piece;
use UNIVERSAL::require;

sub new {
    my $class = shift;
    my $client = TheSchwartz->new( databases =>
                                       [+{ dsn => 'dbi:mysql:dbname=theschwartz;host=192.168.3.54', user => 'nobody', pass => 'nobody' }] );
    my $ability = shift;
    my $self = bless {
        client => $client,
        worker => $ability,
    },$class;
    $self->init;
    $self;
}

sub init {
    my $self = shift;
    $self->{client}->set_verbose(
        sub {
            my $msg = shift;
            $WorkerManager::LOGGER->('TheSchwartz', $msg) if($msg =~ /Working/);
        });
    if(UNIVERSAL::isa($self->{worker}, 'ARRAY')){
        for (@{$self->{worker}}){
            "$_"->use or die $@;
            $self->{client}->can_do($_);
        }
    } else {
        "$self->{worker}"->use or die $@;
        $self->{client}->can_do($self->{worker});
    }
}

sub work {
    my $self = shift;
    my $max = shift || 100;
    my $delay = shift || 5;
    my $count = 0;
    while ($count < $max) {
        if($self->{client}->work_once){
            $count++;
        } else {
            sleep $delay;
        }
    }
}

1;

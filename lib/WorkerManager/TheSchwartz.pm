package WorkerManager::TheSchwartz;
use strict;
use warnings;

use TheSchwartz;
#use Hatena::Star::Worker::UpdateFavorites;
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
    "$self->{worker}"->use or die $@;
    $self->{client}->can_do($self->{worker});
}

sub work {
    my $self = shift;
    my $max = shift || 5;
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

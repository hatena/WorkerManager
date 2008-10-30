package WorkerManager::TheSchwartz;
use strict;
use warnings;

use TheSchwartz;
use Time::Piece;
use UNIVERSAL::require;
use POSIX qw(getppid);

sub new {
    my ($class, $worker, $options) = @_;
    $options ||= {};

    my $databases;
    if ($databases = delete $options->{databases}) {
        $databases = [$databases] unless UNIVERSAL::isa($databases, 'ARRAY');
    } else {
        $databases =  [+{ dsn => 'dbi:mysql:dbname=theschwartz;host=192.168.3.54', user => 'nobody', pass => 'nobody' }];
    }

    use Data::Dumper;
    warn Dumper($databases);

    my $client = TheSchwartz->new( databases => $databases, %$options);

    my $self = bless {
        client => $client,
        worker => $worker,
        terminate => undef,
    }, $class;
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
    if (UNIVERSAL::isa($self->{worker}, 'ARRAY')){
        for (@{$self->{worker}}){
            "$_"->use or warn $@;
#            "$_"->use;
            $self->{client}->can_do($_);
        }
    } else {
        "$self->{worker}"->use or warn $@;
        $self->{client}->can_do($self->{worker});
    }
}

sub work {
    my $self = shift;
    my $max = shift || 100;
    my $delay = shift || 5;
    my $count = 0;
    while ($count < $max && ! $self->{terminate}) {
        if (getppid == 1) {
            die "my dad may be killed.";
            exit(1);
        }
        if($self->{client}->work_once){
            $count++;
        } else {
            sleep $delay;
        }
    }
}

sub terminate {
    my $self = shift;
    $self->{terminate} = 1;
}

1;

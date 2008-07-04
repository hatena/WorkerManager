#! /usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');
use lib File::Spec->catdir($FindBin::Bin, '..', '..', 'lib');

use WorkerManager::Client::TheSchwartz;
use Time::Piece;

my $client = WorkerManager::Client::TheSchwartz->new();
$client->insert('Sandbox::Worker::A' => +{foo => localtime->epoch});
#$client->insert('Sandbox::Worker::B' => +{foo => "bar2"});

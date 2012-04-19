use inc::Module::Install;

name 'WorkerManager';

requires 'Danga::Socket';
requires 'File::Pid';
requires 'Gearman::Client';
requires 'Gearman::Client::Async';
requires 'Parallel::ForkManager';
requires 'Proc::Daemon';
requires 'TheSchwartz';
requires 'TheSchwartz::Simple';
requires 'Time::Piece::MySQL';
requires 'UNIVERSAL::require';

WriteAll;

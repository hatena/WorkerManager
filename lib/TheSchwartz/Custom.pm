
package TheSchwartz::Custom;
use strict;
use warnings;
use base 'TheSchwartz';

sub start_scoreboard {
    my TheSchwartz $client = shift;

    # Don't do anything if we're not configured to write to the scoreboard
    my $scoreboard = $client->scoreboard;
    return unless $scoreboard;

    # Don't do anything of (for some reason) we don't have a current job
    my $job = $client->current_job;
    return unless $job;

    my $class = $job->funcname;

    open(SB, '>', $scoreboard)
      or $job->debug("Could not write scoreboard '$scoreboard': $!");
    print SB join("\n", ("pid=$$",
                         'funcname='.($class||''),
                         'jobid='.$job->jobid,
                         'dsn='.$job->handle->dsn_hashed,
                         'started='.($job->grabbed_until-($class->grab_for||1)),
                         'arg='._serialize_args($job->arg),
                        )
                 ), "\n";
    close(SB);

    return;
}

1;

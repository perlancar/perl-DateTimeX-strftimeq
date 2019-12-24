## no critic: Modules::ProhibitAutomaticExportation

package DateTimeX::strftimeq;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;

use Date::strftimeq ();
use POSIX ();
use Scalar::Util 'blessed';

use Exporter 'import';
our @EXPORT = qw(strftimeq);

sub strftimeq {
    my ($format, @time) = @_;

    my ($caller_pkg) = caller();
    my ($dt, %compiled_code);

    if (@time == 1 && blessed $time[0] && $time[0]->isa('DateTime')) {
        $dt = $time[0];
        @time = (
            $dt->second,
            $dt->minute,
            $dt->hour,
            $dt->day,
            $dt->month-1,
            $dt->year-1900,
        );
    }

    $format =~ s{$Date::strftimeq::regex}{
        # for faster acccess
        my %m = %+;

        #use DD; dd \%m; # DEBUG

        if (exists $m{code}) {
            require DateTime;
            $dt //= DateTime->new(
                second => $time[0],
                minute => $time[1],
                hour   => $time[2],
                day    => $time[3],
                month  => $time[4]+1,
                year   => $time[5]+1900,
            );
            unless (defined $compiled_code{$m{code}}) {
                #say "D: compiling $m{code}"; # DEBUG
                $compiled_code{$m{code}} = eval "package $caller_pkg; no strict; no warnings; sub { $m{code} }";
                die "Can't compile code in $m{all}: $@" if $@;
            }
            local $_ = $dt;
            my $code_res = $compiled_code{$m{code}}->(
                time => \@time,
                dt   => $dt,
            );
            $code_res //= "";
            $code_res =~ s/%/%%/g;
            $code_res;
        } else {
            $m{all};
        }
    }xego;

    POSIX::strftime($format, @time);
}

1;
# ABSTRACT: POSIX::strftime() with support for embedded perl code in %(...)q

=head1 SYNOPSIS

 use DateTimeX::strftimeq; # by default exports strftimeq()

 my @time = localtime();
 print strftimeq '<%-6Y-%m-%d>', @time; # <  2019-11-19>
 print strftimeq '<%-6Y-%m-%d%( $_->day_of_week eq 7 ? "sun" : "" )q>', @time; # <  2019-11-19>
 print strftimeq '<%-6Y-%m-%d%( $_->day_of_week eq 2 ? "tue" : "" )q>', @time; # <  2019-11-19tue>

You can also pass DateTime object instead of ($second, $minute, $hour, $day,
$month, $year):

 print strftimeq '<%-6Y-%m-%d>', $dt; # <  2019-11-19>


=head1 DESCRIPTION

This module provides C<strftimeq()> which extends L<POSIX>'s C<strftime()> with
a conversion: C<%(...)q>. Inside the parenthesis, you can specify Perl code.

The Perl code will receive a hash argument (C<%args>) with the following keys:
C<time> (arrayref, the arguments passed to strftimeq() except for the first),
C<dt> (L<DateTime> object). For convenience, C<$_> will also be locally set to
the DateTime object. The Perl code will be eval-ed in the caller's package,
without L<strict> and without L<warnings>.


=head1 FUNCTIONS

=head2 strftimeq

Usage:

 $str = strftimeq $fmt, $sec, $min, $hour, $mday, $mon, $year;
 $str = strftimeq $fmt, $dt;


=head1 SEE ALSO

L<Date::strftimeq> is exactly the same except it is DateTime-free.

L<POSIX>'s C<strftime()>

L<DateTime>

=cut

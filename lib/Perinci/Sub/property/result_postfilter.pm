package Perinci::Sub::Wrapper::property::result_postfilter;

use 5.010;
use strict;
use warnings;

use Perinci::Util qw(declare_property);

our $VERSION = '0.01'; # VERSION

declare_property(
    name => 'result_postfilter',
    type => 'function',
    schema => ['hash'],
    wrapper => {
        meta => {
            # very low, we want to be the last to process result before
            # returning it
            prio    => 100,
            convert => 1,
        },
        handler => sub {
            my ($self, %args) = @_;

            my $v    = $args{new} // $args{value};
            return unless $v && keys(%$v);

            $self->select_section('after_call');
            $self->push_lines('', '# postfilter result');

            my $term = $self->{_meta}{result_naked} ? '$res' : '$res->[2]';

            my $errp = "result_postfilter: Unknown filter";
            my $gen_process_item = sub {
                my $t = shift;
                my $code = '';
                while (my ($a, $b) = each %$v) {
                    if ($a eq 're') {
                        $code .= ($code ? "elsif":"if").
                            "(ref($t) eq 'Regexp'){";
                        if ($b eq 'str') {
                            $code .= "$t = \"$t\"";
                        } else {
                            die "$errp for $a: $b";
                        }
                        $code.="}";
                    } elsif ($a eq 'date') {
                        $code .= ($code ? "elsif":"if").
                            "(ref($t) eq 'DateTime'){";
                        if ($b eq 'epoch') {
                            $code .= "$t = $t->epoch";
                        } else {
                            die "$errp for $a: $b";
                        }
                        $code.="}";
                    } elsif ($a eq 'code') {
                        $code .= ($code ? "elsif":"if").
                            "(ref($t) eq 'CODE'){";
                        if ($b eq 'str') {
                            $code .= "$t = 'CODE'";
                        } else {
                            die "$errp for $a: $b";
                        }
                        $code.="}";
                    } else {
                        die "$errp $a";
                    }
                }
                $code .= "elsif(ref($t) eq 'ARRAY') { \$resf_ary->($t) }";
                $code .= "elsif(ref($t) eq 'HASH') { \$resf_hash->($t) }";
                $code;
            };

            #    'state $ary_rpf = sub { ;');
            #$self->indent;

            $self->push_lines(
                'state $resf_ary; state $resf_hash;');
            $self->push_lines(
                'if (!$resf_ary ) { $resf_ary  = sub { '.
                    'for my $el (@{$_[0]}) { '.
                        $gen_process_item->('$el') . ' } } }'
            );
            $self->push_lines(
                'if (!$resf_hash) { $resf_hash = sub { '.
                    'my $h=shift; for my $k (keys %$h) { '.
                        $gen_process_item->('$h->{$k}') . ' } } }'
            );
            $self->push_lines(
                "for ($term) { " . $gen_process_item->('$_') . " }",
            );
        },
    },
);

1;
# ABSTRACT: Postfilter function result


__END__
=pod

=head1 NAME

Perinci::Sub::Wrapper::property::result_postfilter - Postfilter function result

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 # in function metadata
 result_postfilter => {
     re   => 'str',    # convert regex object to string
     date => 'epoch',  # convert date object to an integer Unix time
     code => 'str',    # convert subroutine to string literal 'CODE'
 }

=head1 DESCRIPTION

This property specifies postfilters for function result. Currently the focus of
this property is converting values that are unsafe when exporting to JSON/YAML.

Value: a hash containing instruction of how to filter. Known keys:

=over 4

=item * C<re> (filter regex object)

With filter values: C<str> (stringify it).

=item * C<date> (date object, such as DateTime in Perl)

With filter values: C<epoch> (convert to Unix epoch time).

=item * C<code> (subroutine)

With filter values: C<str> (convert to string literal C<CODE>).

=back

More sophisticated filtering rules might be specified in the future.

Filtering using generated code can be faster since the code will use for() loop
and inline conversion instead of callback for each data item (higher subroutine
call overhead).

=head1 SEE ALSO

L<Perinci>

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

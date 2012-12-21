package Perinci::Sub::Property::result_postfilter;

use 5.010;
use strict;
use warnings;

use Perinci::Util qw(declare_property);

# VERSION

sub filter_using_for {
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
}

our $_implementation = 'for';

declare_property(
    name => 'result_postfilter',
    type => 'function',
    schema => ['hash'],
    wrapper => {
        meta => {
            v       => 2,
            # very low, we want to be the last to process result before
            # returning it
            prio    => 100,
            convert => 1,
        },
        handler => sub {
            if ($_implementation eq 'for') {
                filter_using_for(@_);
            } else {
                die "Unknown implementation '$_implementation'";
            }
        },
    },
);

1;
# ABSTRACT: (DEPRECATED) Postfilter function result

=for Pod::Coverage ^filter_using_.+

=head1 SYNOPSIS

 # in function metadata
 result_postfilter => {
     re   => 'str',    # convert regex object to string
     date => 'epoch',  # convert date object to an integer Unix time
     code => 'str',    # convert subroutine to string literal 'CODE'
 }


=head1 DESCRIPTION

B<NOTE:> The use of this property is now deprecated. Generating filtering code
for each function is quite wasteful when there are hundreds or more functions
that are wrapped. Instead, see L<Data::Clean::JSON>.

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


=head1 NOTES

Another alternative is using the encoder's facility, for example the L<JSON>
module can convert blessed object:

 use JSON 2;
 my $encoder = JSON->new->convert_blessed;
 {
     local *DateTime::TO_JSON = sub { $_[0]->ymd };
     print $encoder->encode($doc);
 }

But this currently can't convert coderefs. JSON also can't handle circular
references, which neither this wrapper property nor the above way can work
around.


=head1 SEE ALSO

L<Perinci>

=cut

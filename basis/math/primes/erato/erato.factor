! Copyright (C) 2009 Samuel Tardieu.
! See http://factorcode.org/license.txt for BSD license.
USING: kernel kernel.private locals math math.bitwise
math.functions math.order math.private math.ranges sequences
sequences.private ;
IN: math.primes.erato

<PRIVATE

CONSTANT: masks
{ f 128 f f f f f 64 f f f 32 f 16 f f f 8 f 4 f f f 2 f f f f f 1 }

: bit-pos ( n -- byte mask/f )
    { fixnum } declare
    30 /mod masks nth-unsafe
    { maybe{ fixnum } } declare ; inline

:: marked-unsafe? ( n sieve -- ? )
    n bit-pos [
        [ sieve nth-unsafe ] [ mask zero? not ] bi*
    ] [ drop f ] if* ; inline

:: unmark ( n sieve -- )
    n bit-pos [
        swap sieve [ swap unmask ] change-nth-unsafe
    ] [ drop ] if* ; inline

: upper-bound ( sieve -- n ) length 30 * 1 - ; inline

:: unmark-multiples ( i upper sieve -- )
    i sieve marked-unsafe? [
        i 2 fixnum*fast :> step
        i i fixnum*fast
        [ dup upper <= ] [
            [ sieve unmark ] [ step fixnum+fast ] bi
        ] while drop
    ] when ; inline

: init-sieve ( n -- sieve )
    30 /i 1 + [ 255 ] B{ } replicate-as ; inline

PRIVATE>

:: sieve ( n -- sieve )
    n integer>fixnum-strict init-sieve :> sieve
    sieve upper-bound >fixnum :> upper
    3 upper sqrt 2 <range>
    [ upper sieve unmark-multiples ] each
    sieve ;

: marked-prime? ( n sieve -- ? )
    [ integer>fixnum-strict ] dip
    2dup upper-bound 2 swap between? [ bounds-error ] unless
    over { 2 3 5 } member? [ 2drop t ] [ marked-unsafe?  ] if ;

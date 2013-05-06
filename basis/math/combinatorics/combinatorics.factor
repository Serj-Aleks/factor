! Copyright (c) 2007-2010 Slava Pestov, Doug Coleman, Aaron Schaefer, John Benediktsson.
! See http://factorcode.org/license.txt for BSD license.

USING: accessors arrays assocs binary-search classes.tuple fry
hints kernel locals math math.order math.ranges memoize
namespaces sequences sequences.private sorting ;
FROM: sequences => change-nth ;
IN: math.combinatorics

<PRIVATE

: possible? ( n m -- ? )
    0 rot between? ; inline

: twiddle ( n k -- n k )
    2dup - dupd > [ dupd - ] when ; inline

PRIVATE>

<PRIVATE

: (binary-reduce2) ( ... seq start quot: ( ... elt1 elt2 -- ... newelt ) from length -- ... value )
    #! We can't use case here since combinators depends on
    #! sequences
    dup 4 < [
        integer>fixnum {
            [ 2drop nip ]
            [ 2nip swap nth-unsafe ]
            [ -rot [ drop swap nth2-unsafe ] dip call ]
            [ -rot [ drop swap nth3-unsafe ] dip bi@ ]
        } dispatch
    ] [
        [ 2/ ] [ over - ] bi [ 2dup + ] dip
        [ (binary-reduce) ] [ 2curry ] curry 2bi@
        pick [
            [ 3curry ] bi-curry@ 3bi
            [ call ] dip swap [ call ] dip
        ] dip call
    ] if ; inline recursive

PRIVATE>

: binary-reduce2 ( ... seq start quot: ( ... elt1 elt2 -- ... newelt ) -- ... value )
    pick length 0 max 0 swap (binary-reduce2) ; inline

GENERIC: sum2 ( seq -- n )
M: object sum2 0 [ + ] binary-reduce2 ;

GENERIC: sum3 ( seq -- n )
M: object sum3 0 [ + ] binary-reduce ;

: product2 ( seq -- n )
    0 swap 1 [
        dup even? [ 2/ * [ 1 + ] dip ] [ * ] if
    ] binary-reduce2 swap shift ;

TUPLE: factorials n length ;
: <factorials> ( n -- factorials )
    dup dup odd? [ 1 + ] when 2/ factorials boa ; inline
M: factorials length length>> ; inline
M: factorials nth-unsafe
    n>> swap [ - ] keep 1 + 2dup = [ drop ] [ * ] if ; inline
INSTANCE: factorials sequence

: factorial-product ( n -- n! )
    dup 1 > [ [1,b] product2 ] [ drop 1 ] if ;

: factorial1 ( n -- n! )
    dup 1 > [
        [ 0 1 ] dip [ dup 1 > ] [
            [ dup even? [ 2/ [ 1 + ] 2dip ] when * ]
            [ 1 - ] bi
        ] while drop swap shift
    ] [ drop 1 ] if ;

: factorial0 ( n -- n! )
    dup 1 > [ [1,b] product ] [ drop 1 ] if ;

:: factorial2 ( n -- n! )
    n n n [ 2 - dup 1 > ] [
        [ + [ * ] keep ] keep
    ] while nip 1 = [ n 1 + 2/ * ] when ;

! http://www.luschny.de/math/factorial/scala/FactorialScalaCsharp.htm

MEMO: factorial ( n -- n! )
    dup 1 > [ [1,b] product ] [ drop 1 ] if ;

: nPk ( n k -- nPk )
    2dup possible? [ dupd - [a,b) product ] [ 2drop 0 ] if ;

: nCk ( n k -- nCk )
    twiddle [ nPk ] keep factorial /i ;


! Factoradic-based permutation methodology

<PRIVATE

: factoradic ( n -- factoradic )
    0 [ over 0 > ] [ 1 + [ /mod ] keep swap ] produce reverse! 2nip ;

: bump-indices ( seq n -- )
    '[ dup _ >= [ 1 + ] when ] map! drop ; inline

: (>permutation) ( seq n index -- seq )
    swap [ dupd head-slice ] dip bump-indices ;

: >permutation ( factoradic -- permutation )
    reverse! dup [ (>permutation) ] each-index reverse! ;

: permutation-indices ( n seq -- permutation )
    length [ factoradic ] dip 0 pad-head >permutation ;

: permutation-iota ( seq -- iota )
    length factorial iota ; inline

PRIVATE>

: permutation ( n seq -- seq' )
    [ permutation-indices ] keep nths-unsafe ;

TUPLE: permutations length seq ;

: <permutations> ( seq -- permutations )
    [ length factorial ] keep permutations boa ;

M: permutations length length>> ; inline
M: permutations nth-unsafe seq>> permutation ;
M: permutations hashcode* tuple-hashcode ;

INSTANCE: permutations immutable-sequence

DEFER: next-permutation

<PRIVATE

: permutations-quot ( seq quot -- seq quot' )
    [ [ permutation-iota ] [ length iota >array ] [ ] tri ] dip
    '[ drop _ [ _ nths-unsafe @ ] keep next-permutation drop ] ; inline

PRIVATE>

: each-permutation ( ... seq quot: ( ... elt -- ... ) -- ... )
    permutations-quot each ; inline

: map-permutations ( ... seq quot: ( ... elt -- ... newelt ) -- ... newseq )
    permutations-quot map ; inline

: filter-permutations ( ... seq quot: ( ... elt -- ... ? ) -- ... newseq )
    selector [ each-permutation ] dip ; inline

: all-permutations ( seq -- seq' )
    [ ] map-permutations ;

: find-permutation ( ... seq quot: ( ... elt -- ... ? ) -- ... elt/f )
    [ permutations-quot find drop ]
    [ drop over [ permutation ] [ 2drop f ] if ] 2bi ; inline

: reduce-permutations ( ... seq identity quot: ( ... prev elt -- ... next ) -- ... result )
    swapd each-permutation ; inline

: inverse-permutation ( seq -- permutation )
    <enum> sort-values keys ;

<PRIVATE

: cut-point ( seq -- n )
    [ last ] keep [ [ > ] keep swap ] find-last drop nip ; inline

: greater-from-last ( n seq -- i )
    [ nip ] [ nth ] 2bi [ > ] curry find-last drop ; inline

: reverse-tail! ( n seq -- seq )
    [ swap 1 + tail-slice reverse! drop ] keep ; inline

: (next-permutation) ( seq -- seq )
    dup cut-point [
        swap [ greater-from-last ] 2keep
        [ exchange ] [ reverse-tail! nip ] 3bi
    ] [ reverse! ] if* ;

HINTS: (next-permutation) array ;

PRIVATE>

: next-permutation ( seq -- seq )
    dup [ ] [ drop (next-permutation) ] if-empty ;


! Combinadic-based combination methodology

<PRIVATE

! "Algorithm 515: Generation of a Vector from the Lexicographical Index"
! Buckles, B. P., and Lybanon, M. ACM
! Transactions on Mathematical Software, Vol. 3, No. 2, June 1977.

:: combination-indices ( x! p n -- seq )
    x 1 + x!
    p 0 <array> :> c 0 :> k! 0 :> r!
    p 1 - [| i |
        i [ 0 ] [ 1 - c nth ] if-zero i c set-nth
        [ k x < ] [
            i c [ 1 + ] change-nth
            n i c nth - p i 1 + - nCk r!
            k r + k!
        ] do while k r - k!
    ] each-integer
    p 2 < [ 0 ] [ p 2 - c nth ] if
    p 1 < [ drop ] [ x + k - p 1 - c set-nth ] if
    c [ 1 - ] map! ;

PRIVATE>

: combination ( m seq k -- seq' )
    swap [ length combination-indices ] [ nths-unsafe ] bi ;

TUPLE: combinations seq k length ;

: <combinations> ( seq k -- combinations )
    2dup [ length ] [ nCk ] bi* combinations boa ;

M: combinations length length>> ; inline
M: combinations nth-unsafe [ seq>> ] [ k>> ] bi combination ;
M: combinations hashcode* tuple-hashcode ;

INSTANCE: combinations immutable-sequence

<PRIVATE

: find-max-index ( seq n -- i )
    over length - '[ _ + >= ] find-index drop ; inline

: increment-rest ( i seq -- )
    [ nth ] [ swap tail-slice ] 2bi
    [ drop 1 + dup ] map! 2drop ; inline

: increment-last ( seq -- )
    [ [ length 1 - ] keep [ 1 + ] change-nth ] unless-empty ; inline

:: next-combination ( seq n -- seq )
    seq n find-max-index [
        1 [-] seq increment-rest
    ] [
        seq increment-last
    ] if* seq ;

HINTS: next-combination array fixnum ;

:: combinations-quot ( seq k quot -- seq quot' )
    seq length :> n
    n k nCk iota k iota >array seq quot n
    '[ drop _ [ _ nths-unsafe @ ] keep _ next-combination drop ] ; inline

PRIVATE>

: each-combination ( ... seq k quot: ( ... elt -- ... ) -- ... )
    combinations-quot each ; inline

: map-combinations ( ... seq k quot: ( ... elt -- ... newelt ) -- ... newseq )
    combinations-quot map ; inline

: filter-combinations ( ... seq k quot: ( ... elt -- ... ? ) -- ... newseq )
    selector [ each-combination ] dip ; inline

: map>assoc-combinations ( ... seq k quot: ( ... elt -- ... key value ) exemplar -- ... assoc )
    [ combinations-quot ] dip map>assoc ; inline

: all-combinations ( seq k -- seq' )
    [ ] map-combinations ;

: find-combination ( ... seq k quot: ( ... elt -- ... ? ) -- ... elt/f )
    [ combinations-quot find drop ]
    [ drop pick [ combination ] [ 3drop f ] if ] 3bi ; inline

: reduce-combinations ( ... seq k identity quot: ( ... prev elt -- ... next ) -- ... result )
    [ -rot ] dip each-combination ; inline

: all-subsets ( seq -- subsets )
    dup length [0,b] [ all-combinations ] with map concat ;

<PRIVATE

: (selections) ( seq n -- selections )
    [ dup [ 1sequence ] curry { } map-as dup ] [ 1 - ] bi* [
        cartesian-product concat [ concat ] map
    ] with times ;

PRIVATE>

: selections ( seq n -- selections )
    dup 0 > [ (selections) ] [ 2drop { } ] if ;


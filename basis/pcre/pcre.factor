USING:
    accessors
    alien.c-types alien.data alien.enums alien.strings
    arrays
    assocs
    io.encodings.utf8 io.encodings.string
    kernel
    math
    mirrors
    pcre.ffi pcre.info pcre.utils
    sequences sequences.generalizations
    strings ;
IN: pcre

ERROR: malformed-regexp expr error ;
ERROR: pcre-error value ;

TUPLE: compiled-pcre pcre extra nametable ;

: default-opts ( -- opts )
    PCRE_UTF8 PCRE_UCP bitor ;

: (pcre) ( expr -- pcre err-message err-offset )
    default-opts { c-string int } [ f pcre_compile ] with-out-parameters ;

: <pcre> ( expr -- pcre )
    dup (pcre) 2array swap [ 2nip ] [ malformed-regexp ] if* ;

: exec ( pcre extra subject ofs opts -- count match-data )
    [ dup length ] 2dip 30 int <c-array> 30 [ pcre_exec ] 2keep drop ;

: <pcre-extra> ( pcre -- pcre-extra )
    0 { c-string } [ pcre_study ] with-out-parameters drop ;

: config ( what -- alien )
    { int } [ pcre_config ] with-out-parameters ;

! Finding stuff
TUPLE: matcher pcre extra subject ofs exec-opts match ;

: <matcher> ( subject compiled-pcre -- matcher )
    [ utf8 encode ] dip [ pcre>> ] [ extra>> ] bi rot 0 0 f matcher boa ;

! This handling of zero-length matches is taken from pcredemo.c
: empty-match-opts ( -- opts )
    PCRE_NOTEMPTY_ATSTART PCRE_ANCHORED bitor ;

: findnext ( matcher -- matcher'/f )
    clone dup <mirror> values 6 firstn drop exec
    over dup -1 < [ PCRE_ERRORS number>enum pcre-error ] when
    -1 =
    [
        2drop dup exec-opts>> 0 =
        [ drop f ]
        [
            dup [ subject>> ] [ ofs>> ] bi next-utf8-char
            [ >>ofs 0 >>exec-opts findnext ] [ drop f ] if*
        ] if
    ]
    [
        [ 2array >>match ]
        [
            nip
            [ first2 = [ empty-match-opts ] [ 0 ] if >>exec-opts ]
            [ second >>ofs ] bi
        ] 2bi
    ] if ;

! Result parsing
: substring-list ( subject match-array count -- alien )
    { void* } [ pcre_get_substring_list drop ] with-out-parameters ;

: parse-match ( subject nametable match-data -- match )
    swapd first2 swap [ substring-list ] keep void* <c-direct-array>
    [ utf8 alien>string ] { } map-as [ of swap 2array ] with map-index ;

! High-level
: <compiled-pcre> ( expr -- compiled-pcre )
    <pcre> dup <pcre-extra> 2dup name-table-entries compiled-pcre boa ;

: has-option? ( compiled-pcre option -- ? )
    [ pcre>> options ] dip bitand 0 > ;

GENERIC: findall ( subject obj -- matches )

M: compiled-pcre findall
    [ <matcher> [ findnext ] follow [ match>> ] map harvest ]
    [ nametable>> rot [ parse-match ] 2with map ] 2bi >array ;

M: string findall
    <compiled-pcre> findall ;

: matches? ( subject obj -- ? )
    dupd findall [ nip length 1 = ] [ ?first ?first ?last = ] 2bi and ;

: split ( subject obj -- strings )
    dupd findall [ first second ] map split-subseqs ;

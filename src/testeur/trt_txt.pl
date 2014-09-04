#!/usr/bin/perl

##  a enregistrer en utf8
our $dbhlog;
require "alto2_fonctions.pl";
use Config;
use POSIX qw/ceil/;
use DBI;
use Tk;
use Tk::ProgressBar;
use Tk::Pane;
use Tk::Dialog;
use Cwd;
use Env;
use strict;
use utf8;
no utf8;
use File::Basename;
use File::Copy;
use File::Path;
use Encode;

our $OS = $Config{osname};
our $Archi = $Config{archname};
our $dbconnect;
our $baseconnue = 0;
my $REQ;
our $nom_societe = $ARGV[8];
our $ctl         = $ARGV[9];
my $crlf;

# TODO : remplacer or die ... finko
our $vers_java;
my $dbname;
our $file       = $ARGV[0];
my $sep        = $ARGV[1];
our $separateur = $sep;
our @champs;
my @champs_1;
our @champs_base;
my $i = 0;
our $dbh;
our $table;
my $sth;
my $j      = 0;
my $k      = 0;
my $trouve = 0;
our %champs_arrete;
our %mapping;
my @val_ecr;
my $line;
my @Coche;
my @chk;
my @ZoneRep;
our %r_mapping   = ();            # Table de hash multidim
our $ref_mapping = \%r_mapping;
our $alpage      = $ARGV[3];
our $siren   = $ARGV[2];
our $erreurs = 0;
our $CREATE;
our $datecloture = $ARGV[4];
my ($codepage) = ( `chcp` =~ m/: +(\d+)/ );
my $l          = 0;
my $lig1       = 0;
my @list_5lig;
our $majdrop        = 'drop';
our $pcg           = $ARGV[6];
our $cat_revenus   = $ARGV[7];
our $conn_base      = $ARGV[11];
our $id_util        = $ARGV[12];
my $nligne         = 0;
my $auto           = 0;
my $auto_pos       = 0;
my $auto_num_enr   = 0;
my $old_date_cpt   = "";
my $old_code_jrnal = "";
my $old_num_piece  = "";
our $clause_tva     = "";
our %somme;    # d/c ecriture d/c cumul
my $entetefile = $file;
my $erreur_pg;
our $log_seq = $ARGV[10];
my $encodage = ChercheEncodage();
our $nblines     = 0;
our %r_bilanctl  = ();             # Table de hash multidim _ trié : our !
our $rr_bilanctl = \%r_bilanctl;
our $nb_bilanctl = 0;
our $nb_errs     = 0;

# exp reg formatage date
our $dt_sep = '[\/\-\.]*';
our $dt_a1  = '(?<a>20[0-9]{2})';
our $dt_a2  = '(?<a>19[0-9]{2})';
our $dt_a3  = '(?<a>[0-9]{4})';
our $dt_m   = '(?<m>[0-1][0-9])';
our $dt_j   = '(?<j>[0-3][0-9])';
our $dt_h   = '[T ][0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2}';

#var traitement
our $doublon                 = 0;
    our $nb_ligne_base         ;
    our @liste_precedents_champs = "";
    our $lu = 0;
    our $percent_done = 0;
    our $percent_sav  = 0;
    our $Ligne_Tete;
    our $fentop;
    our $fen;
    our $fen2;
    our $Ligne_vide;
    our $progress;
    our $Alert_Texte;
    our $Ligne_Alert;
    our $nb_l        = 0;
    our $rang_d      = 0;
    our $rang_c      = 0;
    our $type_champs = "Text";
    
#our $conn_local ;
#our $conn_distant;
#our $ldap_distant;

#RG:T:vérification présence module perl Postgres:E

# ancienne gestion des logs

$dbhlog = &connexion_log( "altoweb2", $dbh );

#RG:T:vérification connection postgres:I
# récupération paramètre version dans le nom du dossier java

$entetefile =~ s/$/.entete/;

open( F, ${entetefile} ) or die "Impossible de trouver ${entetefile}";
if ( $sep eq "T" )  { $separateur = '\t'; }
if ( $sep eq "P" )  { $separateur = '\|'; }
if ( $sep eq "V" )  { $separateur = ','; }
if ( $sep eq "PV" ) { $separateur = ';'; }
while ( $line = <F> ) {

    $line =~ s/ +$//;
    $line =~ s/\r\n|\r$//;
    #$line =~ s/\x0D\x0A$//;
    chomp $line;
    @champs_1 = split $separateur, $line;
    foreach $l (@champs_1) {
        $champs[ ++$#champs ] = uc($l);
    }
    $list_5lig[0] = $line;
}
close(F);

# parsing xml config
#($conn_local, $conn_distant , $ldap_distant)=&parse_xml("alto2.xml");

#&erreur("E","$conn_local, $conn_distant, $ldap_distant");

#open( F, "<   :encoding(latin9) ", ${file} )   or die "Impossible de trouver $file ";
open( my $hf, "<","$file");
$crlf = &detecte_macfile($hf);
close $hf;

open( F, "< ", ${file} ) or die "Impossible de trouver $file ";
binmode F, ":raw";
local $/ = $crlf;

while ( $line = <F> ) {
    $line =~ s/ +$//;
    $line =~ s/\r\n|\r$//;
    #$line =~ s/\x0D\x0A$//;
    chomp $line;

    if ( $lig1 == 0 ) {
        $lig1++;
        next;
    }

    $list_5lig[ $lig1++ ] = $line;

    last if ( $lig1 > 5 );
}
close(F);
local $/ = "\n";

#RG:F:récupérer les noms de l'arrêté  pour afficher les champs absents :I
open( STRUC, "< fmt_arrete" )
  or ( &erreur( "E", "Impossible de trouver fmt_arrete" ) && &finko );
my $bil_rang = 0;



#RG:T:Lire en log entete si fichier initial D/C ou M/S:I
$REQ =
"SELECT distinct(texte_log) from log_alim  where id_trait = '$log_seq' and type_log='D' ";
$dbh = $dbhlog;
my @res_lotseq = &sql_1col($REQ);
$dbh = undef;
local $/ = "\n";
# print STDOUT $res_lotseq[0] . "\n";
while ( $line = <STRUC> ) {
    $line =~ s/\x0D\x0A$//;
    chomp $line;
    my ( $plat, $base, $libl_arrete ) = split /;/, $line;
    $plat = uc($plat);

    unless (
        (
            $res_lotseq[0] =~ /Sens/
            && ( uc($plat) eq 'DEBIT' || uc($plat) eq 'CREDIT' )
        )
        || ( $res_lotseq[0] !~ /Sens/
            && ( uc($plat) eq 'MONTANT' || uc($plat) eq 'SENS' ) )
      )
    {
        $champs_arrete{ uc($base) } = uc($plat);
        $bil_rang = $libl_arrete;
        $bil_rang =~ s/\..*$//;
        $r_bilanctl{$plat}{'rang'}   = $bil_rang;
        $r_bilanctl{$plat}{'lib'}    = conv_to_iso($libl_arrete);
        $r_bilanctl{$plat}{'nomFEC'} = '';

    }

}
close(STRUC);

#fin structure

open( SQL, "< SQL/FEC${cat_revenus}.sql" )
  or die "Impossible de trouver SQL/FEC${cat_revenus}.sql";

#  20130821 : SQL est parcouru pour chercher les champs des lignes contenant ',' ne contenant pas ';' ni serial
local $/="\n";
while ( $line = <SQL> ) {
    $trouve = 0;

    $line =~ s/\x0D\x0A$//;

    $line =~ s/\-\-.*$//;
    chomp $line;
    if ( $line =~ m/CONSTRAINT/i ) {
        last;
    }
    if (   $line !~ m/Serial/i
        && $line =~ /,/
        && $line !~ /;/
        && $line !~ m/alto2_/i )
    {
        $line =~ /^\s*([a-zA-Z0-9_-]+)\s*([a-zA-Z]+).*,/;
        my $champs_test = uc($1);
        my $format_test = $2;

        $champs_base[$i] = $champs_test;
        for ( $k = 0 ; $k <= $#champs ; $k++ ) {
            if ( $champs_test eq uc( $champs[$k] ) ) {
                $r_mapping{ uc( $champs[$k] ) }{'champs_base'} = $champs_test;
                $r_mapping{ uc( $champs[$k] ) }{'champs_arrete'} =
                  $champs_arrete{$champs_test};
                $r_mapping{ uc( $champs[$k] ) }{'rang_fichier'} = $k;
                $r_mapping{ uc( $champs[$k] ) }{'rang_base'}    = $i;
                $r_mapping{ uc( $champs[$k] ) }{'type'}         = $format_test;
                $r_mapping{ uc( $champs[$k] ) }{'champs_oblig'} = 0;
                $r_mapping{ uc( $champs[$k] ) }{'champs_oblig'} = 1
                  if ( $line =~ m/NOT NULL/i );
                $trouve = 1;

                &erreur( "I",
                        "mappé :"
                      . $champs_test
                      . ": format  :"
                      . $format_test
                      . ":" );
                $r_bilanctl{ $champs_arrete{$champs_test} }{'nomFEC'} =
                  $champs_arrete{$champs_test};
                last;
            }

        }

        if ( $trouve eq 0 ) {
            if (   $line =~ m/NOT NULL/i
                && $line !~ m/DEFAULT/i
                && $line !~ m/alto2_/i )
            {

           #RG:F:vérification que tous les champs obligatoires sont présents:E

                my $text_tempo =
                  &enc_utf8(
                    $r_bilanctl{ $champs_arrete{$champs_test} }{'lib'} );
                $text_tempo =~ s/^[0-9]+\. //;
                $text_tempo =~ s/^ *le /au /;
                $text_tempo =~ s/^ *l/à l/;

                #print STDOUT  $text_tempo."\n";
                $text_tempo =
                    "Le champ  «"
                  . $champs_arrete{$champs_test}
                  . "»  n'est pas présent dans le fichier, l'information relative "
                  . $text_tempo
                  . " n'a pas été trouvée dans la ligne d'entête ;";

                #print STDOUT  $text_tempo."\n";
                &erreur( "O", $text_tempo );
                $nb_errs++;

                # &finko("paschargé");
            }
            else {
                $r_mapping{ uc($champs_test) }{'champs_base'}  = $champs_test;
                $r_mapping{ uc($champs_test) }{'rang_fichier'} = -1;
                $r_mapping{ uc($champs_test) }{'rang_base'}    = $i;
                $r_mapping{ uc($champs_test) }{'type'}         = $format_test;

            }
        }

        $i++;
    }
}
close(SQL);

#RG:T: fmt_arrete dispose de plus de lignes que fec...sql , purge fonction type compta les lignes en trop:I
$nb_bilanctl = $i - 1;
foreach my $col_bilan ( keys %r_bilanctl ) {
    delete( $r_bilanctl{$col_bilan} )
      if ( $r_bilanctl{$col_bilan}{'rang'} > $nb_bilanctl );

# delete($r_bilanctl{ $col_bilan}  ) if (! defined $r_bilanctl{ $col_bilan}{'lib'}) ;
}

# contrôles métiers
#RG:F:Détection des champs supplémentaires présents:I

# ajouter champs manquants :
$trouve = -1;
for ( $k = 0 ; $k <= $#champs ; $k++ ) {

    if ( !exists $r_mapping{ uc( $champs[$k] ) } ) {
        if ( uc( $champs[$k] ) eq "ZFICTIFZ" ) { next; }
        $r_mapping{ uc( $champs[$k] ) }{'champs_base'}  = "0";
        $r_mapping{ uc( $champs[$k] ) }{'rang_fichier'} = $k;
        $r_mapping{ uc( $champs[$k] ) }{'rang_base'}    = "NULL";
        $r_mapping{ uc( $champs[$k] ) }{'type'}         = "VIDE";
        $trouve                                         = $k;
        &erreur( "S", $champs[$k] );
    }
}

# if ($nb_errs>0) {    &finko("paschargé");    }

$fentop = MainWindow->new;

$fentop->geometry("640x480");

$fen = $fentop->Scrolled(
    'Pane',
    -height     => 1,
    -width      => 1,
    -scrollbars => 'e'
)->pack( -expand => 1, -fill => 'both' );
my $Ligne_Alert;
my $fenliste = $fen->Frame;

#RG:F:mapping des champs inconnus en surnombre:I
&erreur( "I", "mapping manuel du fichier" );
my $params1 = $fen->Frame;
my $params2;
if ( $trouve > -1 ) {
    my @frames;

    $fentop->title(
        "Correspondance des champs du fichier avec la table journal");
    my $Ligne_Tete = $fen->Label(
        -text => " Dossier : $alpage, fichier : " . basename($file),
        -font => '{Sansserif} 14'
    )->pack();
    $Ligne_Tete = $fen->Label(
        -text => " Renommage des champs inconnus  ...",
        -font => '{Sansserif} 14'
    )->pack();
    $Ligne_Alert =
      $fen->Label( -text =>
          &utf8toutf8("Choisir le nom du champs à creer dans la base ") )
      ->pack();

    for ( $k = 0 ; $k <= $trouve ; $k++ ) {
        if ( $r_mapping{ $champs[$k] }{'champs_base'} eq "0" ) {
            $frames[$k] = $params1->Frame;
            $chk[$k] =
              $frames[$k]->Checkbutton( -text => "", -variable => \$Coche[$k] )
              ->pack( -side => 'left' );
            $chk[$k]->select();
            $ZoneRep[$k] = $frames[$k]->Entry(
                -textvariable => \$champs[$k],
                -background   => 'cyan'
            )->pack( -side => 'right' );
            $frames[$k]->pack();
        }
    }

    my $Button1 =
      $params1->Button( -text => 'Valider', -command => \&traitement )
      ->pack(qw / -pady 25 /);
    $params1->pack();
    $params2 = $fenliste->Scrolled(
        'Pane',
        -height     => 100,
        -width      => 600,
        -scrollbars => 's'
    )->pack( -expand => 1, -fill => 'both' );
    my @temp_list;
    my @listsbox;
    my $taille = 0;
    for ( $k = 0 ; $k <= $#champs ; $k++ ) {
        $taille = 0;
        for ( $i = 0 ; $i <= $#list_5lig ; $i++ ) {
            my @list_ligne = split $separateur, &utf8toutf8( $list_5lig[$i] );
            $temp_list[$i] = $list_ligne[$k];
            $taille = length( $list_ligne[$k] )
              if ( length( $list_ligne[$k] ) > $taille );
        }
        $taille = 30 if ( $taille > 30 );
        $listsbox[$k] =
          $params2->Listbox( -width => $taille )->pack( -side => 'left' );
        $listsbox[$k]->insert( 'end', @temp_list );
    }
    $fenliste->pack();
}
else {
    &traitement;
}

sub traitement() {
    
    
    
    &controle();
    
    if ( ( &aorte() eq "a" ) and  ( uc($ctl) ne "CTL" ) ) {
        my $MODULE ="alto2_alim.pl";
        do $MODULE ;
        &alimentation( ) ;
    }
}

sub controle() {

    # $params1->destroy();
     $nb_ligne_base   = $#champs_base + 1;
    for ( $i = 0 ; $i <= $#champs ; $i++ ) {
        if ( $Coche[$i] eq "1" ) {
            $champs[$i] = &supprime_accent( $champs[$i] );
            for ( $j = 0 ; $j <= $#champs_base + 1 ; $j++ ) {
                if ( uc( $champs[$i] ) eq $champs_base[$j] ) {
                    $doublon = 1;
                    $ZoneRep[$i]->configure( -background => 'red' );
                    $Ligne_Alert->configure(
                        -text => "Le champs existe en base, renommez-le svp",
                        -background => 'red'
                    );
                    $fentop->update;
                }
            }
            for ( $j = 0 ; $j <= $#champs ; $j++ ) {
                if ( $i != $j && ( uc( $champs[$i] ) eq $champs[$j] ) ) {
                    $doublon = 1;
                    $ZoneRep[$i]->configure( -background => 'red' );
                    $Ligne_Alert->configure(
                        -text => "Le champs existe en base, renommez-le svp",
                        -background => 'red'
                    );
                    $fentop->update;
                }
            }
            if ( $doublon == 0 ) {
                $r_mapping{ uc( $champs[$i] ) }{'champs_base'} =
                  uc( $champs[$i] );
                $r_mapping{ uc( $champs[$i] ) }{'rang_base'} = $nb_ligne_base++;
                $r_mapping{ uc( $champs[$i] ) }{'rang_fichier'} = $i;
                $r_mapping{ uc( $champs[$i] ) }{'type'}         = "VIDE";
            }
        }
        else {
            push @liste_precedents_champs, uc( $champs[$i] );
        }
    }

    if ( $doublon > 0 ) { return; }

    for ( $k = 0 ; $k <= $#champs ; $k++ ) {

        if ( !exists $r_mapping{ uc( $champs[$k] ) } ) {
            if ( uc( $champs[$k] ) eq "ZFICTIFZ" ) { next; }
            $r_mapping{ uc( $champs[$k] ) }{'champs_base'}  = "0";
            $r_mapping{ uc( $champs[$k] ) }{'rang_fichier'} = $k;
            $r_mapping{ uc( $champs[$k] ) }{'rang_base'}    = "NULL";
            $r_mapping{ uc( $champs[$k] ) }{'type'}         = "VIDE";
            $trouve                                         = $k;
            &erreur( "S", $champs[$k] );
        }
    }

    #$Ligne_Alert->configure( -text=> "", -background => 'grey');
    $Ligne_Alert->destroy() if defined $Ligne_Alert;
    $params1->destroy();
    $fenliste->destroy();
    $lu = 0;

    &erreur( "I", "Contrôle du fichier" );
    $Ligne_Tete = $fen->Label(
        -text => " Controle du fichier en cours ...",
        -font => '{Sansserif} 14'
    )->pack();
    $fen2 = $fen->Frame;
    $Ligne_vide =
      $fen2->Label( -text => "" )->grid( -row => 0, -column => 0 );    #pack( );
    $progress = $fen2->ProgressBar(
        -borderwidth => 3,
        -relief      => 'ridge',
        -width       => 30,
        -from        => 0,
        -to          => 100,
        -blocks      => 10,
        -gap         => 1,
        -colors      => [ 0, 'green' ],
        -variable    => \$percent_done
    )->grid( -row => 0, -column => 0 );    #pack(-fill => 'x');
    $Alert_Texte = int($percent_done) . " %";
    $Ligne_Alert = $fen2->Label(
        -textvariable => \$Alert_Texte,
        -foreground   => 'black',
        -background   => 'green'
    )->grid( -row => 0, -column => 0 );    #pack( );
    $fen2->pack();
    
    open( my $hf, "<","$file");
    $crlf = &detecte_macfile($hf);
    close $hf;
    
    open( F, "<   ", "$file" ) or die "Impossible de trouver $file";
    binmode F, ":raw" ;
    local $/ = $crlf;
    while (<F>) { $nblines++; }
    close(F);
    
    

    #RG:F:comptage du nombre de ligne du fichier:I
    &erreur( "I", "Nb lignes fichiers : " . $nblines . " : " );
    if ( $nblines <= 1 ) {
        &erreur( "E", "Le fichier ne contient pas de ligne : fichier vide" );
        &finko;
    }

    $fentop->update;
    open( F, "< ", "$file" );
    binmode F, ":raw" ;
    local $/ = $crlf;
        
    while ( $line = <F> ) {
        $line =~ s/\r\n|\r$//;
        $line =~ s/\c@//g;
        $line =~ s/ *(${separateur}) */$1/g;
        $line =~ s/ +$//;
        chomp $line;
        $nb_l++;

        if ( $nb_l == 1 ) { next; }

        $percent_sav = int($percent_done);
        $percent_done = int( ( $nb_l * 100 ) / $nblines );
        if ( $percent_done > $percent_sav ) {
            $Alert_Texte = $percent_done . " %";
            $fen2->update;
        }
        my @valeurs = split $separateur, $line . "²";

    # 20140214 suppression du ² ajouté en fin de ligne.... ne change rien ....

        chomp $valeurs[$#valeurs];
        $valeurs[$#valeurs] =~ s/\²$//;

        # voir 821 si ligne vide dans le fichier devient non bloquant
        if ( $#valeurs == 0 ) {
            &erreur( "E",
"la structure du fichier est incorrecte, une ligne :$nb_l:  est vide ;"
            );

            # &&  &finko("paschargé");
            #$nb_errs++;
            next;
        }
        if ( $#valeurs != $#champs ) {

#RG:F:vérification que les champs de l'entête  sont tous  présents sur chaque ligne du fichier :E
#RG:F:vérification que seuls le nombre de champs de l'entête  sont  présents sur chaque ligne du fichier:E
#RG:T:vérification du format des champs supplémentaires à partir des 300 premières lignes du fichier:E
#RG:T:vérification du format des champs supplémentaires à partir des 300 premières lignes du fichier:E
#RG:T:vérification du format des champs supplémentaires détection numérique sur les 300lignes > numérique, date sur les 300 lignes > date, sinon text:E
            &erreur( "E",
"La structure du fichier est incorrecte : en ligne $nb_l : il y a $#valeurs  champs   au lieu des $#champs  champs  attendus ;"
            );
            $nb_errs++;    #&finko("paschargé");
        }

   # débit credit
   #RG:F:Tous les champs numériques contenant des , sont remplacés par des .:I
   #RG:F:Si débit présent, et crédit absent crédit=0:I
   #RG:F:Si crédit présent, et débit absent débit=0:I

        for ( $i = 0 ; $i <= $#champs ; $i++ ) {
            my $champs_log = $r_mapping{ uc( $champs[$i] ) }{'champs_arrete'};

            if ( ( $r_mapping{ uc( $champs[$i] ) }{'rang_base'} eq "NULL" ) ) {
                next;
            }

            if ( $r_mapping{ uc( $champs[$i] ) }{'type'} eq "VIDE" ) {
                if ( $valeurs[$i] =~ /^ *$/ ) {
                    next;
                }
                if ( exists $r_mapping{ uc($champs[$i]) }{'type_prov'} ) {
                    if ( $r_mapping{ uc($champs[$i]) }{'type_prov'} eq "Text" ) {
                        next;
                    }
                }

                if (   $valeurs[$i] =~ m/^[0-9 ]+$/
                    && $valeurs[$i] =~ m/[0-9]{1,}/ )
                {

                    $type_champs = "bigint";
                }

                elsif ($valeurs[$i] =~ m/^[0-9]+,[0-9]*$/
                    || $valeurs[$i] =~ m/^[0-9]+\.[0-9]*$/ )
                {
                    $type_champs = "Numeric";    # (19,6)";
                }

          #elsif ( $valeurs[$i] =~ m/^[0-9]+$/ ) { $type_champs="Numeric(19)"; }
                elsif ( $valeurs[$i] =~
                    m/^20[0-9]{2}[\/\-\.]*[0-1][0-9][\/\-\.]*[0-3][0-9]$/
                    || $valeurs[$i] =~
                    m/^[0-3][0-9][\/\-\.]*[0-1][0-9][\/\-\.]*20[0-9]{2}$/ )
                {
                    $type_champs = "date";
                }
                else { $type_champs = "Text"; }

                if ( not exists $r_mapping{ uc($champs[$i]) }{'type_prov'} ) {
                    # $r_mapping{ uc($champs[$i]) }{'type_prov'} = $type_champs;

                }
                else {
                    if ( $r_mapping { uc( $champs[$i] ) }{'type_prov'} ne
                        $type_champs )
                    {
                        $type_champs = "Text";

                    }
                }
                $r_mapping{ uc($champs[$i]) }{'type_prov'} = $type_champs;

            }
            elsif ( ( $r_mapping{ uc($champs[$i]) }{'champs_oblig'} == 1 )
                && ( $valeurs[$i] =~ /^ *$/ )
                && ( lc( $r_mapping{ uc($champs[$i]) }{'type'} ) ne "numeric" ) )

            {
                &erreur( "E",
                        "Le champ "
                      . $champs_log
                      . " n'est pas au bon format, il ne contient aucune valeur  : en ligne $nb_l :  "
                );

                $nb_errs++;
            }
            else {

                if ( $champs[$i] =~ m/num_cpte_gen/i ) {
                    if ( $valeurs[$i] !~ m/^[0-9]{3}.*$/ ) {
                        &erreur( "A",
                                "Le champ "
                              . $champs_log
                              . " est incorrect , le numéro de compte doit commencer par trois chiffres ; : "
                              . $valeurs[$i]
                              . " :   : ligne  $nb_l : \n" );

                    }
                }
                elsif ( lc( $r_mapping{ uc($champs[$i]) }{'type'} ) eq "numeric" ) {

                    if ( $valeurs[$i] eq "" ) {
                        $valeurs[$i] = 0;
                    }
                    if ( !( $valeurs[$i] =~ /\./ ) ) {
                        $valeurs[$i] =~ s/,/./;
                    }
                    if ( $valeurs[$i] =~ m/^ *[0-9]+ [0-9]+/ ) {
                        &erreur( "E",
                                "Le champ "
                              . $champs_log
                              . " n'est pas au bon format, : ligne $nb_l : un format numérique sans séparateur de milliers est attendu  : "
                              . $valeurs[$i]
                              . " : ;" );
                        $nb_errs++;
                    }
                    elsif (
                        !(  (
                                $valeurs[$i] =~ m/^ *[+-]*[0-9\.,]{1,} *[+-]* *$/
                                &&  $valeurs[$i] !~ m/^.*[-]{1}.*[-]{1}.*$/ 
                            )
                            ||  $valeurs[$i] =~ m/^ *[+-]*[0-9\.,]{1,}[Ee]{1}[0-9\+-]{1,} *$/
                             
                        )
                      )
                    {
                        &erreur( "E",
                                "Le champ "
                              . $champs_log
                              . " n'est pas au bon format, : ligne $nb_l : un format numérique est attendu ; :"
                              . $valeurs[$i]
                              . " : " );

                        $nb_errs++;
                    }
                    if ( $champs[$i] =~ m/MTN_DEBIT/i ) {
                        $rang_d = $i;
                        $valeurs[$i] = 0 if ( !defined $valeurs[$i] );
                        if ( !( $valeurs[$i] =~ /\./ ) ) {
                            $valeurs[$i] =~ s/,/./;
                        }
                        if ( $valeurs[$i] =~ m/^ *([0-9\.,]{1,}) *([+-]) *$/ ) {
                            $valeurs[$i] = $2 . $1;

                        }

                        $somme{'DCC'} += $valeurs[$i];

                    }
                    elsif ( $champs[$i] =~ m/MTN_CREDIT/i ) {
                        $rang_c = $i;
                        $valeurs[$i] = 0 if ( !defined $valeurs[$i] );
                        if ( !( $valeurs[$i] =~ /\./ ) ) {
                            $valeurs[$i] =~ s/,/./;
                        }
                        if ( $valeurs[$i] =~ m/^ *([0-9\.,]{1,}) *([+-]) *$/ ) {
                            $valeurs[$i] = $2 . $1;

                        }

                        $somme{'CCC'} += $valeurs[$i];
                    }

                    elsif ( $champs[$i] =~ m/MTN_DEVISE/i ) {

                        $valeurs[$i] = 0 if ( !defined $valeurs[$i] );
                        if ( !( $valeurs[$i] =~ /\./ ) ) {
                            $valeurs[$i] =~ s/,/./;
                        }
                        if ( $valeurs[$i] =~ m/^ *([0-9\.,]{1,}) *([+-]) *$/ ) {
                            $valeurs[$i] = $2 . $1;

                        }
                    }

                }
                elsif ( lc( $r_mapping{ uc($champs[$i]) }{'type'} ) eq "date" ) {

           #RG:F: champs null autorisé et considéré vide au sens date 0... :I
                    if (
                               $valeurs[$i] =~ m/^[0\-\/\.]{1,}$|^ *$/
                      )
                    {
                        if ( $r_mapping{ uc($champs[$i]) }{'champs_oblig'} == 0 )
                        {
                            next;
                        }
                        else {
                            &erreur( "E",
                                    "Le champ obligatoire "
                                  . $champs_log
                                  . " n'est pas au bon format, : ligne $nb_l : un format date est attendu ; :"
                                  . $valeurs[$i]
                                  . " : " );

                            $nb_errs++;
                            next;
                        }
                    }
                    # RG:T:?<a>?<m>?<j>  notés dans les init en debut de source:I
                    my $date_heure=$valeurs[$i];
                    $date_heure=~ s/\:/ /g;
                    if ( $valeurs[$i] =~  m/^${dt_a1}${dt_sep}${dt_m}${dt_sep}${dt_j}$/ ||
                         $valeurs[$i] =~  m/^${dt_a2}${dt_sep}${dt_m}${dt_sep}${dt_j}$/ ||
                         $valeurs[$i] =~  m/^${dt_a1}${dt_sep}${dt_m}${dt_sep}${dt_j}${dt_h}$/ ||
                         $valeurs[$i] =~  m/^${dt_a2}${dt_sep}${dt_m}${dt_sep}${dt_j}${dt_h}$/ )
                    {
                        #RG:F:Date valide a m j   avec separateur / - . :I
                        #RG:F:Date valide  j m a avec separateur / - . :I
                        if ( ( $+{m} > 12 ) || ( $+{j} > 31 ) ) {
                            &erreur( "E",
                                    "Des dates ("
                                  . $champs_log
                                  . ") ne correspondant pas à des dates calendaires sont présentes dans le fichier,   : ligne $nb_l :  :"
                                  . $date_heure
                                  . " : " );

                            $nb_errs++;

                        }
                    }
                    elsif ( $valeurs[$i] =~ m/^${dt_j}${dt_sep}${dt_m}${dt_sep}${dt_a1}${dt_h}$/ ||
                            $valeurs[$i] =~ m/^${dt_j}${dt_sep}${dt_m}${dt_sep}${dt_a2}${dt_h}$/ ||
                            $valeurs[$i] =~ m/^${dt_j}${dt_sep}${dt_m}${dt_sep}${dt_a1}$/ ||
                            $valeurs[$i] =~ m/^${dt_j}${dt_sep}${dt_m}${dt_sep}${dt_a2}$/ )
                    {
                    #RG:F:Date valide a m j   avec separateur / - .  et Theure:I
                    #RG:F:Date valide   j m a avec separateur / - .  et Theure:I
                        if ( ( $+{m} > 12 ) || ( $+{j} > 31 ) ) {
                            &erreur( "E",
                                    "Des dates ("
                                  . $champs_log
                                  . ") ne correspondant pas à des dates calendaires sont présentes dans le fichier,   : ligne $nb_l :  :"
                                  . $date_heure
                                  . " : " );

                            $nb_errs++;

                        }
                    }
                    elsif ( $valeurs[$i] =~ m/^${dt_a3}${dt_sep}${dt_m}${dt_sep}${dt_j}$/||
                            $valeurs[$i] =~ m/^${dt_j}${dt_sep}${dt_m}${dt_sep}${dt_a3}$/||
                            $valeurs[$i] =~ m/^${dt_a3}${dt_sep}${dt_m}${dt_sep}${dt_j}${dt_h}$/||
                            $valeurs[$i] =~ m/^${dt_j}${dt_sep}${dt_m}${dt_sep}${dt_a3}${dt_h}$/ )
                    {
                        #RG:F:Année incorrecte <1900 ou >2099 :I
                        &erreur( "A",
                                "Le champ "
                              . $champs_log
                              . " contient une date en dehors de la période, : ligne $nb_l : ; :"
                              . $date_heure
                              . " : " );

                    }
                    else {
                         &erreur( "E",
                                "Le champ "
                              . $champs_log
                              . " n'est pas au bon format, : ligne $nb_l : un format date est incorrect ; :"
                              . $date_heure
                              . " : " );

                        $nb_errs++;

                    }
                }
            }
        }    # next for
        unless (
            ( $valeurs[$rang_d] == 0 && $valeurs[$rang_c] != 0 )
            || (   $valeurs[$rang_d] != 0
                && $valeurs[$rang_c] == 0 )
          )
        {

#RG:F:vérification que tous les lignes d'écritures n'ont pas un débit et un crédit servis:A
# 11/02/2014 : Mise en alerte, evolution fonctionnelle
            &erreur( "A",
                    "Structure fichier incorrecte, débit/crédit :"
                  . $valeurs[$rang_d] . " / "
                  . $valeurs[$rang_c]
                  . ": renseignés sur une même ligne :$nb_l:  , ou débit=crédit=0 "
            );    #&& &finko ;
        }

    }    # fin parcours fichier wend

    close(F);
    local $/ = "\n";

    $somme{'DCC'} = int( $somme{'DCC'} * 100 + 0.500001 ) / 100;
    $somme{'CCC'} = int( $somme{'CCC'} * 100 + 0.500001 ) / 100;
    &erreur( "I", "Cumul Débit =" . $somme{'DCC'} . " " );
    &erreur( "I", "Cumul Crédit =" . $somme{'CCC'} . " " );

    # 11/02/2014 : Mise en alerte, evolution fonctionnelle
    # 02/09/2014 fiche 20 : désactivation alerte debit <>credit

#    if ( $somme{'DCC'} - $somme{'CCC'} != 0 ) {
#        &erreur( "A",
#"Erreur sur la somme des écritures fournies par l'entreprise \n cumul débit : "
#              . $somme{'DCC'}
#              . " : cumul crédit : "
#              . $somme{'CCC'}
#              . " : " );
#
#        #$nb_errs++;
#    }
    $vers_java = &verif_version_java;
    $vers_java =~ s/version //;

    # --> fin controle
    &erreur( "I", "Fin de Contrôle" );
    &maj_log($dbhlog);    # mise en persistance table hash

    if ( uc($ctl) eq "CTL" or &aorte() eq "t" ) {
        &faire_pdf();
        exit 0;
    }

    if ( ( $nb_errs > 0 ) && ( uc($ctl) ne "CTL" ) ) {
        &faire_pdf();
        &finko("paschargé");
    }
    
}



sub req () {
    ($REQ) = shift;
    my @result =
      $dbh->selectrow_array( "SELECT COUNT(*) from (" . $REQ . ") as D" )
      or die $DBI::errstr;
    if ( $result[0] > 0 ) {
        &erreur( "E",
            " $REQ \n retourne  " . $result[0] . "  écriture(s) ! \n" );
        &erreur( "I",
            " $REQ \n retourne  " . $result[0] . "  écriture(s) ! \n" );

        #my $ref_dump = $dbh->selectall_arrayref( "SELECT * from $table where num_ecr in (" . $REQ . ") limit 10 " )  or die $DBI::errstr;
        #foreach my $id_ecr (@$ref_dump) {
        #    @val_ecr = @$id_ecr;
        #    print STDERR join( "\t", @val_ecr ) . "\n";
        #}
    }
    else {
        &erreur( "I", "$REQ \n ne retourne aucune ligne" );
    }
}

# sub sql => alto2_fonctions.pl

sub voir_logs () {
    &finko;
}

#sub sanspoint() {
#    my ($v) = @_;
#    if ( $v =~ m/(\d*)\.(\d*)\.(\d*)/ ) {
#        $v = sprintf( "%02d%03d%03d", $1, $2, $3 );
#        return $v;
#    }
#}

sub fin () {
    &maj_log($dbhlog);
    &deconnexion($dbhlog);

    my $rc = &create_log($file);
    exit 0;
}

sub finko () {
    my ($fin) = @_;
    if ( defined($fin) ) {
        &erreur( "E",
"La comptabilité n'a pas pu être chargée, vérifier les logs et le fichier en entree"
        );
        &erreur( "I",
"La comptabilité n'a pas pu être chargée, vérifier les logs et le fichier en entree"
        );
    }
    &maj_log($dbhlog);
    &deconnexion($dbhlog);
    my $rc = &create_log($file);
    if ( -f $rc ) {
        if ( ${OS} =~ m/linux/i ) {
            exec("gedit $rc ");
        }
        else {
            exec("start wordpad $rc ");
        }
    }
    exit 1;
}





sub faire_pdf() {

    require "alto2_pdf.pl";

    use utf8;
    my $text_to_place ;
    if ( &aorte() ne "t" ) {
	
	$text_to_place = "  ANNEXE\n";
    }
    $text_to_place .= " CONTROLE DE LA STRUCTURE DU FEC

(Conformément aux dispositions prévues à l'article A.47 A-1\n du livre des procédures fiscales)";

    our $font_size = 13;
    our $align     = "center";
    my @result;
    chomp $vers_java;
    my $rResult = \@result;

    &ombre( $text_to_place, 185, 80 );
    $align     = "center";
    $font_size = 11;
    $dbh       = $dbhlog;
    $text_to_place =
"Concerne le SIREN : $siren ,  Exercice clos le : $datecloture, Version : $vers_java ";
    &ombre( $text_to_place, 190, 50 );
    $align = "left";

    # table bilan
    #&ajoute_table_r(@$some_data);
    my $pas_complet=0;
    foreach my $col_bilan (
        sort { $rr_bilanctl->{$a}{'lib'} <=> $rr_bilanctl->{$b}{'lib'} }
        keys %r_bilanctl
      )
    {
        if ($r_bilanctl{$col_bilan}{'nomFEC'} eq '' ) { $pas_complet=1; last ;} 
          
    }
    
    $REQ =
"SELECT count(*) from log_alim  where id_trait = '$log_seq' and type_log in ('E','O') ";
    @result = &sql_1col($REQ);

    # Champs oblig manquant
    
    if ( $result[0] == 0 ) {
        if ($pas_complet == 1 && ( substr($datecloture,0,4) >= 2013 ) )  {
            $text_to_place =
"La structure du fichier des écritures comptables ne peut être considérée comme conforme aux dispositions de l'article A.47 A-1 du livre des procédures fiscales car des champs obligatoires n'ont pas été détectés, cf. dernière colonne du tableau de synthèse en page 2.";
        }
        else {
# &ombre("Les champs obligatoires prévus par l'arrêté sont présents ",190,50);
           $text_to_place =
"La structure du fichier des écritures comptables remis apparaît conforme aux dispositions de l’article A.47 A-1 du Livre des Procédures Fiscales.";
        }
        &ajoute_paragraphe( $text_to_place, 180, 75 );
    }
    else {
        if ($pas_complet == 1 && ( substr($datecloture,0,4) >= 2013 ) )  {
            $text_to_place =
"La structure du fichier des écritures comptables ne peut être considérée comme conforme aux dispositions de l'article A.47 A-1 du livre des procédures fiscales car des champs obligatoires n'ont pas été détectés, cf. dernière colonne du tableau de synthèse en page 2.

Par ailleurs, le fichier des écritures comptables n'est pas conforme en raison des anomalies listées ci-dessous : ";
        }
        else {
            $text_to_place =
" La structure du fichier des écritures comptables remis ne peut être considérée comme conforme aux dispositions de l’article A.47 A-1 du Livre des Procédures Fiscales pour les raisons ci-dessous :";
        }
        &ajoute_paragraphe( $text_to_place, 180, 75 );
        undef @result;

        #push @result,"";
        $REQ =
"SELECT  replace(replace (t.fixe_log,'#1',l.val1),'#2',l.val2) from log_alim l,log_type t where id_trait = '$log_seq' and type_log ='O' and t.id_type=l.texte_log";
        push @result, &sql_1col($REQ);
        $REQ =
"select distinct(replace(replace (t.fixe_log,'#1','...'),'#2','...')) || '\n [' || count (*)  || '] fois dans le fichier' from log_alim l, log_type t where id_trait = '$log_seq' and type_log='E' and t.id_type=l.texte_log group by l.texte_log having count (distinct l.id_ligne) >1";

        push @result, &sql_1col($REQ);
        $REQ =
"select distinct(replace(replace (t.fixe_log,'#1',l.val1),'#2',l.val2)) from log_alim l, log_type t where id_trait = '$log_seq' and type_log='E' and t.id_type=l.texte_log group by l.texte_log having count (distinct l.id_ligne)=1";
        push @result, &sql_1col($REQ);

        &ajoute_liste( \@result, 180, 0 );

        &ajoute_paragraphe(
"Vérifiez que le nom des champs est correctement libellé, que le nombre de séparateurs de champs est correct sur l’ensemble du fichier.",
            180, 50
        );

    }
    
    &ajoute_paragraphe("La conformité structurelle du FEC ne présage pas de la régularité de la comptabilité, \nni de sa valeur probante.",
        180, 50    );
    
    if ( &aorte() eq "t" ) {
    
        &ajoute_paragraphe("Ce test a été effectué avec l'application Test Compta Démat version $vers_java. La synthèse des résultats ne constitue pas une attestation de conformité, elle ne saurait engager l'administration.",180,50);
    }
    
    

    # tableau synthèse page (2+)
    &new_page;

    $text_to_place =
      " Tableau de synthèse des $nb_bilanctl  premiers champs du FEC";
    &ajoute_paragraphe( $text_to_place, 190, 50 );

    @result = [
        "Information demandée",
        "Nom du champ défini à l’art. A47 A-1 du LPF",
        "Nom du champ détecté dans le FEC"
    ];
    foreach my $col_bilan (
        sort { $rr_bilanctl->{$a}{'lib'} <=> $rr_bilanctl->{$b}{'lib'} }
        keys %r_bilanctl
      )
    {
        push @result,
          [
            $r_bilanctl{$col_bilan}{'lib'}, $col_bilan,
            $r_bilanctl{$col_bilan}{'nomFEC'}
          ];
    }

    &ajoute_table( \@result, 180, 3 );

    # page 3 : simple info
    &new_page;

    &ombre( "Observations complémentaires :", 190, 50 );

    # champs supplémentaires :
    $REQ =
"SELECT count(*) from log_alim  where id_trait = '$log_seq' and type_log='S' ";

    @result = &sql_1col($REQ);

    if ( $result[0] == 0 ) {
        &ombre( "Aucun champs supplémentaires n'est présent ", 190, 50 );
    }
    else {
        undef @result;
        &ajoute_paragraphe(
            "Les champs supplémentaires suivants figurent dans le fichier :",
            190, 50 );

#$REQ = "SELECT  texte_log from log_alim  where id_trait = '$log_seq' and type_log='S' ";
        $REQ =
"SELECT distinct replace(replace (t.fixe_log,'#1',l.val1),'#2',l.val2) from log_alim l,log_type t where id_trait = '$log_seq' and type_log ='S' and t.id_type=l.texte_log";

        push @result, &sql_1col($REQ);
        &ajoute_liste( \@result, 150, 0 );
    }

    # 11/02/2014 : Evolution ajout des Alertes en pages 3
    $REQ =
"SELECT count(*) from log_alim  where id_trait = '$log_seq' and type_log='A' ";
    @result = &sql_1col($REQ);

    if ( $result[0] == 0 ) {

        # &ombre("Aucun champs supplémentaires n'est présent ",190,50);
    }
    else {
        undef @result;
        &ajoute_paragraphe(
            "Les anomalies suivantes figurent dans le fichier ",
            190, 50
        );
        $REQ =
"select distinct(replace(replace (t.fixe_log,'#1','...'),'#2','...')) || '\n [' || count (*)  || '] fois dans le fichier' from log_alim l, log_type t where id_trait = '$log_seq' and type_log='A' and t.id_type=l.texte_log group by l.texte_log having count ( distinct l.id_ligne) >1";

        push @result, &sql_1col($REQ);
        $REQ =
"select distinct(replace(replace (t.fixe_log,'#1',l.val1),'#2',l.val2)) from log_alim l, log_type t where id_trait = '$log_seq' and type_log='A' and t.id_type=l.texte_log group by l.texte_log having count (distinct l.id_ligne)=1";
        push @result, &sql_1col($REQ);

        &ajoute_liste( \@result, 180, 0 );
    }
    if ( &aorte() ne "t" ) {
    $text_to_place =
      " le total des montants figurant au débit et au crédit est :";
    &ajoute_paragraphe( $text_to_place, 190, 50 );
    my $some_data =
      [ [ "Cumul Debit", "Cumul Credit", ], [ $somme{'DCC'}, $somme{'CCC'} ] ];
    &ajoute_table( $some_data, 120, 2 );
    }
    my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime(time);
    my $nouv_pdf =
      '../rapports/rapport_' . basename($file) . "_$hour$min$sec" . '.pdf';

    &sauve_pdf($nouv_pdf);

    # Save the PDF

    if ( ${OS} =~ m/linux/i ) {
        system("evince $nouv_pdf");
    }
    else {
        system("start $nouv_pdf");

    }

    if ( $nb_errs > 0 ) {
        &finko("paschargé");
    }

}


sub Tk::Error {
    my ( $Widget, $Error, @Locations ) = @_;
    &erreur( "E", "Erreur system : contacter l' AT : " . $Error );
    &finko;
}

# dernière ligne !!!!

MainLoop;

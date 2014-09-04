#!/usr/bin/perl

use Cwd;
use Env;
use Config;
use Getopt::Std;
use File::Copy;
use utf8;
no utf8;

# Extraction des paramètres
our %opts;
our $enc_open = "";    # encodage du fichier de travail

sub sub_entete() {
    ( $opts{o}, $opts{f}, $opts{s}, $opts{n} ) = @_;

    # logs en base pg
    our $dbhlog;
    our $dbh;
    our $log_seq = 0;
    $dbhlog = &connexion_log( "altoweb2", $dbh );

    # Vérification des paramètres
    &verif_param;

    my $file  = $opts{f};
    my $ofile = $opts{o};
    my $sep   = $opts{s};
    $log_seq  = $opts{n};
    my @champs;
    my @champs_entete;
    my $separateur;
    my $trouve;
    # rustine mac fin chariot
    open( my $hf, "$file");
    
    my $crlf = &detecte_macfile($hf);
    
    close $hf;
    
    open( F, "$file" )
        or ( &erreur( "E", "Impossible de trouver $file" ) && return 1 );
    local $/ = $crlf;
    binmode F, ":raw" ;

    if ( $sep eq "T" )  { $separateur = '\t'; }
    if ( $sep eq "P" )  { $separateur = '\|'; }
    if ( $sep eq "V" )  { $separateur = ','; }
    if ( $sep eq "PV" ) { $separateur = ';'; }

    # 12092013 : correction bug : espace suivant champs a neutraliser
    # 19122013 : suppression du bom dans le cas utf8
    my $k=0;
    while ( $line = <F> ) {
        $line =~ s/\r\n|\r$//;
        #$line =~ s/\x0D\x0A$//;
        $line =~ s/\c@//g;
        chomp $line;
        $line =~ s/^\xEF\xBB\xBF//;
        
        @champs = split ' *' . $separateur . ' *', $line;

        if ( $line =~ /${separateur} *$/ ) {
            push @champs, "ZFICTIFZ";
            &erreur( "I",
                "Le fichier contient un séparateur de plus  en fin de ligne "
            );
        }
        last;
    }
    close(F);
    undef $/;
    for ( $i = 0; $i <= $#champs; $i++ ) {
        $champs[$i] = &isotoutf8($champs[$i]);
        $champs[$i] =~ s/é/e/gi;
        $champs[$i] =~ s/è/e/gi;
        $champs[$i] =~ s/ +$//;
        $champs[$i] =~ s/[^A-Za-z0-9]/_/g;
        $champs_entete[$i] = $champs[$i];
    }

 #RG:T: mapping des entetes fournies dans le fichier avec le format arrêté:I
    open( STRUC, "< fmt_arrete" )
        or ( &erreur( "E", "Impossible de trouver fmt_arrete" ) && return 1 );
    local $/ = "\n";

    my $entete;
    while ( $line = <STRUC> ) {

        $line =~ s/\x0D\x0A$//;
        chomp $line;
        my ( $plat, $base ) = split /;/, $line;

        # $trouve=$plat;
        for ( $i = 0; $i <= $#champs; $i++ ) {
            if ( uc($plat) eq uc( $champs[$i] ) ) {
                $champs_entete[$i] = uc($base);
                last;
            }
        }

        #$entete.=$trouve.$separateur;
    }

    close(STRUC);
    my $i      = -1;
    my $rang_d = 0;
    my $rang_c = 0;

 #RG:F: retraitement debit / credit du fichier en présence de Montant/sens :I
 #RG:F: retraitement debit / credit  du fichier , sens hors plage D C +1 -1 :E
    foreach $l (@champs) {
        $i++;
        if ( uc($l) eq "MONTANT" ) {
            $rang_d = $i;
            &erreur( "D", "Sens " );
        }
        if ( uc($l) eq "SENS" ) {
            $rang_c = $i;
            &erreur( "D", "Sens " );
        }
    }

    open( F, "> $ofile" )
        or ( &erreur( "E", "Impossible d'ouvrir $ofile en ecriture" )
        && return 1 );

    my $separateur_esc = $separateur;
    $separateur_esc =~ s/\\\|/|/;
    $separateur_esc =~ s/\\t/\t/;

    print F join( $separateur_esc, @champs_entete );
    my $nb_attendu = $#champs_entete;
    close F;
    my @valeurs;

    if ( $rang_c > 0 && $rang_d > 0 ) {
        $i = 0;
        move( $opts{f}, $opts{f} . "_ori2" );
        
    
    
        open( I, $opts{f} . '_ori2' )
            or ( &erreur( "E", "Impossible de trouver {$file}_ori2 " )
            && return 1 );
        local $/ = $crlf;
        binmode I, ":raw" ;
        open( O, "> $file" )
            or ( &erreur( "E", "Impossible d'ouvrir $file en ecriture" )
            && return 1 );
        
        binmode O, ":raw" ;

        while ( $line = <I> ) {
            $line =~ s/\r\n|\r$//;
            chomp $line;
            if ( $i == 0 ) { print O $line . "\n"; }
            else {
                @valeurs = split $separateur, $line;

                if ( uc( $valeurs[$rang_c] ) eq "D"
                    || $valeurs[$rang_c] =~ /^\s*\+1\s*$/ )
                {
                    $valeurs[$rang_c] = 0;
                }
                elsif ( uc( $valeurs[$rang_c] ) eq "C"
                    || $valeurs[$rang_c] =~ /^\s*\-1\s*$/ )
                {
                    $valeurs[$rang_c] = $valeurs[$rang_d];
                    $valeurs[$rang_d] = 0;
                }
                else {
                    &erreur( "E",
                        "Code D/C mal renseigné : ligne $i  : "
                            . ( uc( $valeurs[$rang_c] ) ) );
                    return 1;
                }
                my $nb_reel = $#valeurs;

# 23072013 : correction bug dans le cas cegid dernière colonne : num_ecr=1 , remplacé par ""
                for ( my $compl = $nb_reel; $compl <= $nb_attendu; $compl++ )
                {
                    if ( !defined( $valeurs[$compl] ) ) {
                        $valeurs[$compl] = "";
                    }
                }
                print O join( $separateur_esc, @valeurs ) . "\n";
            }
            $i++;

        }
        close I;
        close O;
    }

    return 0;
}
1;


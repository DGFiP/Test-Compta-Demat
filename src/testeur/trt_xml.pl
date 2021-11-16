#!/usr/bin/perl

#Copyright (C) 2014 Direction Generale des Finances Publiques
#
#This software is governed by the CeCILL license under French law and
#abiding by the rules of distribution of free software.  You can  use,
#modify and/ or redistribute the software under the terms of the CeCILL
#license as circulated by CEA, CNRS and INRIA at the following URL
#"http://www.cecill.info".
#
#As a counterpart to the access to the source code and  rights to copy,
#modify and redistribute granted by the license, users are provided only
#with a limited warranty  and the software's author,  the holder of the
#economic rights,  and the successive licensors  have only  limited
#liability.
#
#In this respect, the user's attention is drawn to the risks associated
#with loading,  using,  modifying and/or developing or reproducing the
#software by the user in light of its specific status of free software,
#that may mean  that it is complicated to manipulate,  and  that  also
#therefore means  that it is reserved for developers  and  experienced
#professionals having in-depth computer knowledge. Users are therefore
#encouraged to load and test the software's suitability as regards their
#requirements in conditions enabling the security of their systems and/or
#data to be ensured and,  more generally, to use and operate it in the
#same conditions as regards security.
#
#The fact that you are presently reading this means that you have had
#knowledge of the CeCILL license and that you accept its terms.
#
#!/usr/bin/perl

####################################################################################
#                                                                                  /!\ Fichier a enregistrer en utf-8                                                                                       #
####################################################################################

# Modules utilisés
use strict;
use XML::Parser;
use Getopt::Std;
use File::Copy;
use utf8;
no utf8;
use File::Basename;
use File::Copy;
use File::Path;
use Env;
use Cwd qw ( abs_path );

my $currdir   = dirname( abs_path($0) );
require "$currdir/environnement_alto2.pl";
&Env_Path;
our $ProgramFiles = "$ENV{ProgramFiles}";
our $ProgramData = "$ENV{ProgramData}";

# Extraction des paramètres
our %opts;

require "$currdir/alto2_fonctions.pl";

our $Rep_Alim_ou_Testeur = "alimentation";
our $Aorte = &aorte();
if ( $Aorte eq "t" ) {
    $Rep_Alim_ou_Testeur = "testeur";
}

our $Rep_Alim_ou_Testeur = "alimentation";
our $Aorte = &aorte();
if ( $Aorte eq "t" ) {
    $Rep_Alim_ou_Testeur = "testeur";
}

# logs en base pg
our $dbhlog;
my $dbh;
our $REQ;
our $log_seq;

# fin logs

getopts( 'hf:T:t:s:a:o:e:n:d', \%opts );

#logs
$dbhlog = &connexion_log( "altoweb2", $dbh );
$log_seq = $opts{n};

#fin logs

# Vérification des paramètres
&verif_param;

# Initialisation des variables globales et tableaux
my $ifile  = $opts{f};      # fichier XML à traiter
my $handle = *FICXML;       # handle du fichier XML
my $debut  = $opts{'t'};    # marqueur de début d'enregistrement
my $sep    = $opts{s};      # séparateur de champs à utiliser
my $flux
    = $opts{'t'};    # balise d'entete d'un enregistrement pour le fichier xml
my $flux1     = $opts{'T'};  # balise d'entete du fichier xml
my $finsstruc = 0;           # fin sous-structure etat-civil (0 =faux, 1=vrai)
my $new_row = 2;     # nouvel enregistrement (0 =faux, 1=vrai, 2 = init)
my $tag     = 0;     # nouvelle balise ouvrante (0 =faux, 1=vrai)
my $elem    = '';    # élément lu en cours
my $svelem  = '';    # sauvegarde de l'élément en cours
my $i       = 0;     # indice des champs dans l'enregistrement complet
my $j       = 0;     # indice des champs dans l'enregistremnt lu
my $l       = 0;     # ligne en cours de lecture dans le fichier input
my $k       = 0;     # gestion des champs absents
my $p       = '';    # pointeur de l'objet XML en cours de traitement
my $data    = '';    # données en cours de traitement par le parser
my $pfx     = '';    # préfixe représentatif des sous-structures xml
my $line    = '';    # ligne du fichier en cours de traitement
my $ancetre = '';    # debut xml
my $arbre   = '';    # arbre xml
my %Hattr   = ();    # table de hash des attributs d'une ligne xml
my $lock = 0;  # on n'exploite en détail que les enregistrements pas l'entete
my $bug  = 0;  # pour debuger mettre bug=1 sinon bug=0
my %Hf1_fmt   = ();           # Table de hash structure xml
my $rHf1_fmt  = \%Hf1_fmt;    # Référence sur la table de hash structure xml
my $nbfusions = 0;            # Nb de cas spéciaux fusion
my $nb_fields = keys %Hf1_fmt;    # nombre de champs du tableau
my $field     = '';               # champ à rechercher dans le tableau
my $defautlocal
    = '';    # traite le cas d'une balise vide avec seult un attribut xml
my $pfx_naisdec
    = '';    # prefixe naissance ou deces pour les attributs de balises vides
my $rHattr_enr = \%Hattr;    # référence sur la hash table
my @f1_data;
my @entete;                  # liste des champs "fixes"
my @plat;                    # tableau du fichier plat
my @plat_code;               # tableau du fichier plat
my %attr;                    # table de hash des attributs d'un champs
my @ch_plus
    ; # tableau de tableaux  pour les champs en plus sur  ""ligne" " dans le fichier xml
my $ch_plus_ligne = 1;  # rang  de la ligne dans le tableau des champs en plus
my $ch_plus_col   = 0;

our $enc_open = "";     # encodage du fichier de travail
my $est_utf8 = 0;

# Test si fichier XML compressé
my $FIFO = undef;
&test_compress;

# Ajout MC le 20/03/2017 On tente de déterminer le type de compta (fichier xsd)
#                        pour forcer le nombre de colonnes obligatoires en fonction de ce type de compta.
my $read_buffer = "";
open( FT, "+< :raw", $ifile ) or die "impossible";

my $read_nb = 0;
$read_nb = sysread FT, $read_buffer, 300;
close FT;
my $xsdfile = "";
if ( $read_buffer =~ m/noNamespaceSchemaLocation(.*)=(.*)"(.*).xsd"(.*)/i ) {
	$xsdfile = $3;
	$xsdfile =~ s/file://;
}
my $pos_montant = 19;
my $pos_sens = 20;




my $handle   = *FICXML;             # handle du fichier XML
my $encodage = ChercheEncodage();

&alimTables;                        # chargement du mapping plat <=> xml

$bug = 1 if ( defined $opts{'d'} );

# recherche des champs noms dans la liste pour
# Création d'une instance de parser
# (demande d'affichage des erreurs avec 2 lignes avant et aprés)

my $parser = new XML::Parser( ErrorContext => 2 );

# Association méthode/fonction
$parser->setHandlers(
    Start => \&balise_debut,
    Char  => \&balise_texte,
    End   => \&balise_fin
);

#RG:T: Parsing du fichier  xml passé en paramètre:E
$parser->parse($handle);

close FICXML;
close OFILE;

#RG:T: Ajout des col en plus présente dans le xml -> plat :I

move( $opts{o}, $opts{o} . "_wks" );

# ici ok §§§

open( FIN, "< $enc_open", $opts{o} . "_wks" )
    or die "Impossible de lire le fichier  " . $opts{o} . "_wks";
open( FOUT, "> ", $opts{o} )
    or die "Impossible de lire le fichier  " . $opts{o};
binmode( FOUT, " :encoding(iso-8859-15)" );
select FOUT;

my $uentete           = "";
my $old_champs_entete = 0;

foreach my $ui (
    sort { $rHf1_fmt->{$a}{'plat'} <=> $rHf1_fmt->{$b}{'plat'} }
    keys %Hf1_fmt
    )
{
    if ( ($old_champs_entete) == ( $ui - 1 ) ) {
        if ( $uentete ne "" ) { $uentete .= "|"; }
        $uentete .= $rHf1_fmt->{$ui}{'noeud_plat'};
        &trace( $ui . ": $uentete " );
        $old_champs_entete = $ui;
    }
}

for ( my $u = 1; $u <= $ch_plus_col; $u++ ) {
    $uentete .= "|" . $ch_plus[$u][0];
    &trace( $u . ": $uentete " );
}

print $uentete . "\n";
my $ul      = 0;
my $pourlog = "";
while ( my $u_ligne = <FIN> ) {
    $u_ligne =~ s/\x0D\x0A$//;
    chomp $u_ligne;
    $ul++;

    for ( my $u = 1; $u <= $ch_plus_col; $u++ ) {
        $u_ligne .= "|" . $ch_plus[$u][$ul];

    }

    $u_ligne = &conv_to_iso($u_ligne);
    print "$u_ligne \n";

    &trace($u_ligne);
}
close FOUT;
close FIN;
unlink "$opts{o}\_wks" or &trace("Nettoyage fichier de travail");
open( F, ">  :encoding(latin9)", "${opts{o}}.entete" )
    or die "Impossible d'ouvrir   " . ${ opts {o} } . ".entete en ecriture";
print F $uentete . "\n";
close F;

&maj_log($dbhlog) ;
&deconnexion($dbhlog);

#
# Sous-programmes
#

sub alimTables {

# tables au format    cf doc opencalc pour générer les lignes en cas de maj
# pères_clés_xml:fils;rang_plat;rang_xml;règle_métier_à_appliquer;CHAMPS_BASE_POSTGRES
#  champs 4 et 19 <=>>
	my @f1_fmt;
    
	if ( $xsdfile eq "" || $xsdfile =~ /VII-1/i || $xsdfile =~ /VIII-3/i ) {
		@f1_fmt = qw(
			journal§JournalCode;1;1;;code_jrnal
			journal§JournalLib;2;2;;lib_jrnal
			journal_ecriture§EcritureNum;3;3;;num_ecr
			journal_ecriture§EcritureDate;4;4;DS;date_cpt
			journal_ecriture_ligne§CompteNum;5;5;NC;num_cpte_gen
			journal_ecriture_ligne§CompteLib;6;6;;lib_cpte_gen
			journal_ecriture_ligne§CompteAuxNum;7;7;;num_cpt_aux
			journal_ecriture_ligne§CompteAuxLib;8;8;;lib_cpt_aux
			journal_ecriture_ligne§Debit;9;9;NU;mtn_debit
			journal_ecriture_ligne§Credit;10;10;NU;mtn_credit
			journal_ecriture§EcritureLib;11;11;;lib_ecriture
			journal_ecriture§PieceRef;12;12;;num_piece
			journal_ecriture§PieceDate;13;13;DS;date_piece
			journal_ecriture§EcritureLet;14;14;;code_lettrage
			journal_ecriture§DateLet;15;15;DS;date_lettrage
			journal_ecriture§ValidDate;16;16;DS;valid_date
			journal_ecriture_ligne§Montantdevise;17;17;NU;mtn_devise
			journal_ecriture_ligne§Idevise;18;18;;idevise
			journal_ecriture_ligne§Montant;0;19;NU;mtn_debit
			journal_ecriture_ligne§Sens;0;20;;mtn_credit
		);
		$pos_montant = 19;
		$pos_sens = 20;
	} else {
		if ( $xsdfile eq "" or $xsdfile =~ /VIII-5/i ) {
			@f1_fmt = qw(
				journal§JournalCode;1;1;;code_jrnal
				journal§JournalLib;2;2;;lib_jrnal
				journal_ecriture§EcritureNum;3;3;;num_ecr
				journal_ecriture§EcritureDate;4;4;DS;date_cpt
				journal_ecriture_ligne§CompteNum;5;5;NC;num_cpte_gen
				journal_ecriture_ligne§CompteLib;6;6;;lib_cpte_gen
				journal_ecriture_ligne§CompteAuxNum;7;7;;num_cpt_aux
				journal_ecriture_ligne§CompteAuxLib;8;8;;lib_cpt_aux
				journal_ecriture_ligne§Debit;9;9;NU;mtn_debit
				journal_ecriture_ligne§Credit;10;10;NU;mtn_credit
				journal_ecriture§EcritureLib;11;11;;lib_ecriture
				journal_ecriture§PieceRef;12;12;;num_piece
				journal_ecriture§PieceDate;13;13;DS;date_piece
				journal_ecriture§EcritureLet;14;14;;code_lettrage
				journal_ecriture§DateLet;15;15;DS;date_lettrage
				journal_ecriture§ValidDate;16;16;DS;valid_date
				journal_ecriture_ligne§Montantdevise;17;17;NU;mtn_devise
				journal_ecriture_ligne§Idevise;18;18;;idevise
				journal_ecriture§DateRglt;19;19;DS;paiement_date
				journal_ecriture§ModeRglt;20;20;DS;paiement_mode
				journal_ecriture§NatOp;21;21;;prestation
				journal_ecriture_ligne§Montant;0;22;NU;mtn_debit
				journal_ecriture_ligne§Sens;0;23;;mtn_credit
			);
			$pos_montant = 22;
			$pos_sens = 23;
		} else {
			if ( $xsdfile eq "" or $xsdfile =~ /VIII-7/i ) {
				@f1_fmt = qw(
					journal§JournalCode;1;1;;code_jrnal
					journal§JournalLib;2;2;;lib_jrnal
					journal_ecriture§EcritureNum;3;3;;num_ecr
					journal_ecriture§EcritureDate;4;4;DS;date_cpt
					journal_ecriture_ligne§CompteNum;5;5;NC;num_cpte_gen
					journal_ecriture_ligne§CompteLib;6;6;;lib_cpte_gen
					journal_ecriture_ligne§CompteAuxNum;7;7;;num_cpt_aux
					journal_ecriture_ligne§CompteAuxLib;8;8;;lib_cpt_aux
					journal_ecriture_ligne§Debit;9;9;NU;mtn_debit
					journal_ecriture_ligne§Credit;10;10;NU;mtn_credit
					journal_ecriture§EcritureLib;11;11;;lib_ecriture
					journal_ecriture§PieceRef;12;12;;num_piece
					journal_ecriture§PieceDate;13;13;DS;date_piece
					journal_ecriture§EcritureLet;14;14;;code_lettrage
					journal_ecriture§DateLet;15;15;DS;date_lettrage
					journal_ecriture§ValidDate;16;16;DS;valid_date
					journal_ecriture_ligne§Montantdevise;17;17;NU;mtn_devise
					journal_ecriture_ligne§Idevise;18;18;;idevise
					journal_ecriture§DateRglt;19;19;DS;paiement_date
					journal_ecriture§ModeRglt;20;20;DS;paiement_mode
					journal_ecriture§NatOp;21;21;;prestation
					journal_ecriture§IdClient;22;22;;client
					journal_ecriture_ligne§Montant;0;23;NU;mtn_debit
					journal_ecriture_ligne§Sens;0;24;;mtn_credit
				);
#					journal_ecriture§Resultat;23;23;;ecr_type
				$pos_montant = 23;
				$pos_sens = 24;
			}
		}
	}
	
# Ajout MC le 27/05/2015 DATERGLT, NATOP et IDCLIENT car sont détectés comme champs supplémentaires.
#        journal_ecriture_ligne§Idevise;19;19;;idevise
#        journal_ecriture_ligne§Montant;0;20;NU;mtn_debit
#        journal_ecriture_ligne§Sens;0;21;;mtn_credit

#         journal_ecriture§DateRglt;20;20;DS;paiement_date
#         journal_ecriture§NatOp;21;21;;prestation
#         journal_ecriture§IdClient;22;22;;client
#         journal_ecriture_ligne§Montant;0;23;NU;mtn_debit
#         journal_ecriture_ligne§Sens;0;24;;mtn_credit
        

	foreach my $i (@f1_fmt) {
		my @liste1 = split /;/, uc($i);
		my ( $i_1, $i_2 ) = split /§/, $liste1[0];
		$Hf1_fmt{ $liste1[2] }{'chemin'} = $i_1;
		$Hf1_fmt{ $liste1[2] }{'noeud'}  = $i_2;
		$Hf1_fmt{ $liste1[2] }{'plat'}   = $liste1[1];

		if ( !defined( $liste1[3] ) ) {
			$Hf1_fmt{ $liste1[2] }{'metier'} = " ";
		}
		else {
			$Hf1_fmt{ $liste1[2] }{'metier'} = $liste1[3];
		}
		$Hf1_fmt{ $liste1[2] }{'noeud_plat'} = $liste1[4];
	}

}

sub test_compress {

    open( FICXML, "< $enc_open", "$opts{f}" )
        or die "erreur d'ouverture du fichier  $opts{f}";
    binmode( FICXML, "$enc_open" );
    $enc_open = ":encoding(latin9)";
}

sub arbreXML {
    my @contexte = $p->context;
    shift @contexte;
    shift @contexte;
    $arbre = uc( join( "_", @contexte ) );
}

sub constructionPlat {

    my $indice_xml;    # rang dans l'ordre xml
    my $indice_txt;    # rang dans le fichier plat txt
    my @div;           # liste des codes divergences
    my @txt;           # tableau des champs du fichier txt
    my $v;             # ligne
                       # if ( !defined( $entete[3] ) ) {        return;     }
    # 20141009 : forcer le nb éléments du fichier à produire au max des colonnes (cf alimenTables() )
    # 14/11/2016 Modif MC force le nombre de champs à 23 au lieu de 22 
    #$txt[22]='';
    #$txt[23]='';
    # 14/11/2016 Fin Modif MC force le nombre de champs à 23 au lieu de 22 
    $txt[18]='';
    
    &trace("contenu tableau xml :");
    for ( $indice_xml = 1; $indice_xml <= $#plat; $indice_xml++ ) {
        &trace(   $indice_xml
                . "donnee : "
                . $plat[$indice_xml]
                . "donnee code : "
                . $plat_code[$indice_xml] );
    }
    &trace("fin contenu tableau xml :");

    # TODO : AJout col
    for ( $indice_xml = 1; $indice_xml <= $#plat; $indice_xml++ ) {
        $indice_txt = $Hf1_fmt{$indice_xml}{'plat'};
        &trace(   "indice :"
                . $indice_xml
                . "indice plat : "
                . $indice_txt
                . "donnee : "
                . $plat[$indice_xml]
                . "donnee code : "
                . $plat_code[$indice_xml] );
        $txt[$indice_txt] = $plat[$indice_xml];
       # if ( $plat[$indice_xml] !~ m/^[\+\-]*[0-9]{1,}\.*[0-9]*[\+\-]*$/ ) {
        if ( $plat[$indice_xml] =~ m/^[\+\-]?[ ]*([0-9]*)\.(([0-9])*)[ ]*$/ ) {
            $txt[$indice_txt]  =~ tr/./,/;
        }
    }

  #RG:F: retraitement debit / credit par ligne en présence de Montant/sens :I
  #RG:F: retraitement debit / credit par ligne, sens hors plage D C +1 -1 :E
    if ( defined $plat[$pos_sens] && defined $plat[$pos_montant] ) {
        &trace( "Montant : " . $plat[$pos_montant] . " SENS :" . $plat[$pos_sens] );
        if ( uc( $plat[$pos_sens] ) eq "C" || $plat[$pos_sens] =~ /^\s*\-1\s*$/ ) {
            $plat[$pos_montant] =~ tr/./,/;
            $txt[10] = $plat[$pos_montant];
            $txt[9]  = 0;

        }
        elsif ( uc( $plat[$pos_sens] ) eq "D" || $plat[$pos_sens] =~ /^\s*\+1\s*$/ ) {
            $plat[$pos_montant] =~ tr/./,/;
            $txt[9]  = $plat[$pos_montant];
            $txt[10] = 0;
        }
        else {
            &trace( "Ligne :  $ch_plus_ligne, Valeur SENS incorrecte : "
                    . uc( $plat[$pos_sens] ) );
            exit 1;
        }

        
#     if ( defined $plat[21] && defined $plat[20] ) {
#         &trace( "Montant : " . $plat[20] . " SENS :" . $plat[21] );
#         if ( uc( $plat[21] ) eq "C" || $plat[21] =~ /^\s*\-1\s*$/ ) {
#             $txt[10] = $plat[20];
#             $txt[9]  = 0;
# 
#         }
#         elsif ( uc( $plat[21] ) eq "D" || $plat[21] =~ /^\s*\+1\s*$/ ) {
#             $txt[9]  = $plat[20];
#             $txt[10] = 0;
#         }
#         else {
#             &trace( "Ligne :  $ch_plus_ligne, Valeur SENS incorrecte : "
#                     . uc( $plat[21] ) );
#             exit 1;
#         }
    # correction bug 20141009 : après utilisation des champs 20 21 du xml
    # il faut les purger pour réduire la liste @plat à 19
    
    unshift @plat;
    unshift @plat;
    
    }

    shift @txt;

    &trace("contenu tableau plat :");
    for ( $indice_xml = 1; $indice_xml <= $#txt; $indice_xml++ ) {
        &trace(
            $indice_xml . "donnee : " . $txt[$indice_xml] . "donnee  : " );
    }

    for ( $indice_xml = 1; $indice_xml <= $#plat; $indice_xml++ ) {

#RG:T:Remise à vide du contenu des balises à chaque fin de ligne d'écriture:I
        $plat[$indice_xml] = undef
            if ( $Hf1_fmt{$indice_xml}{'chemin'} =~ /_ligne$/i );
    }
    my $rep = join( "|", @txt );

    &trace($rep);
        
    $rep = &conv_to_iso($rep);

    print $rep. "\n";
    $ch_plus_ligne++;

}

sub balise_debut {

# on exploite ici l'architecture des balises xml pas leur contenu
# sauf les attributs qui font parti de la balise :
# cas spécifique une balise avec un attribut mais pas de données est ignoré de base ...

    ( $p, $data, %attr ) = @_;
    &trace( "debut : " . $data );

    # utf8::decode($data);
    %Hattr = '';

    if (%attr) {
        foreach my $v ( keys %attr ) {
            $Hattr{$v} = $attr{$v};
        }
    }

    if ( $data =~ /^${flux1}$/ ) {
        $lock = 0;
    }
    elsif ( $data =~ /${debut}/ ) {
        $defautlocal = "";

        # balise xml d'une ligne (journal)
        $new_row     = 1;
        $i           = 0;
        $lock        = 0;
        $pfx         = "";    # data
        $pfx_naisdec = "";
        for ( my $l = 2; $l < 5; $l++ ) { $entete[$l] = ""; }
    }
    else {
        &trace("erreur : $data inattendu ");
    }

    # Nouveau tag ouvrant
    $tag = 1;
}


sub balise_texte {
    ( $p, $data ) = @_;

    #utf8::decode($data); incompatbile hp-ux
    my $ii = &existe_field;
    if ( $ii == 0 ) {

        #RG:F:prise en compte nouvelle col facultative:I
        $elem = $p->current_element;
        if (   ( $elem !~ /^\s*$/ )
            && ( $data !~ /^\s*$/ )
            && ( $elem ne 'DateCloture' ) )
        {
            &trace("$elem : $data champs nouveau ?");
            my $u_trouve = $ch_plus_col + 1;
            for ( my $u = 1; $u < $ch_plus_col + 1; $u++ ) {
                if ( $ch_plus[$u][0] eq $elem ) {
                    $u_trouve = $u;
                    last;
                }
            }
            if ( $u_trouve > $ch_plus_col ) { $ch_plus_col++; }
            $ch_plus[$u_trouve][0] = $elem;
            $ch_plus[$u_trouve][$ch_plus_ligne] = $data;
            &trace(   "rang $u_trouve ligne  $ch_plus_ligne valeur $data  "
                    . $ch_plus[$u_trouve][0] . ""
                    . $ch_plus[$u_trouve][$ch_plus_ligne] );
        }
        return;
    }
    $data = &reglesMetier( $ii, $data );
    #20141009 perte d'un champs si derniere position et contenu vide
    # if ( $data !~ /^\s*$/ ) {
        if ( ( $elem ne $svelem ) || ( $elem eq $svelem && $finsstruc == 1 ) )
        {
            $i++;
            if ( $new_row == 1 ) {

                # &constructionPlat;
                @plat      = '';
                @plat_code = '';
                $new_row   = 0;
                # force la liste des champs en sortie au nombre de champs cibles
                $plat[18]='';
            }
            $plat[$ii]      = $data;
            $plat_code[$ii] = $Hattr{'code'};
            $svelem         = $elem;
        }
        else {
            if ( defined $plat[$ii] ) {
                $plat[$ii] .= $data;
            }
            else {
                $plat[$ii]      = $data;
                $plat_code[$ii] = $Hattr{'code'};
            }
            $svelem = $elem;
        }
        $tag       = 0;
        $finsstruc = 0;
    # }
    &trace(
        "ii :" . $ii . " plat :" . $plat[$ii] . "code : " . $plat_code[$ii] );
}

sub balise_fin {
    ( $p, $data ) = @_;

    # code spécifique selon le type de balise de fin d'enregistrements
    #utf8::decode($data); incompatible hp-ux
    if ( $data =~ /^ligne$/i ) {
        &constructionPlat;
    }
}

sub prepare_fusion {
    return;

}

sub reglesMetier {

    my ( $ii, $valeurEntree, $metierforce ) = @_;
    my $valeurSortie = $valeurEntree;
    my $metier;
    if ( defined($metierforce) ) {
        $metier = $metierforce;
    }
    else {
        $metier = $Hf1_fmt{$ii}{'metier'};
    }
    my $heure;

#RG:F:Date Souple format accepté AAAA-MM-JJ ou AAAA-MM-JJThh;mm;ss  :I
#RG:F:Date Souple format accepté AAAA-MM-JJ ou AAAA-MM-JJThh;mm;ss  :I
#RG:F:Montant  sous la forme +- en debut ou en fin accepté:I
#RG:F:Montant  sous la forme numérique avec séparateur . uniquement accepté:I
#RG:F:Numéro de compte sous la forme numérique sur 3 positions, suivi alphanumerique:I

    if ( $metier eq 'DS' ) {
        if (( $valeurEntree !~ m/^\s*[0-9]{4}-[0-9]{2}-[0-9]{2}\s*$/ )
            && ( $valeurEntree
                !~ m/^\s*[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\s*$/
            )
            )
        {

            &trace( "Date incorrecte $valeurEntree \n", "X" );

        }
    }
    elsif ( $metier eq 'NU' ) {
    #2021 forcage fichier xml separateur , pour compatibilite fichiers plats
        $valeurSortie =~ tr/,/./;
        if ( $valeurSortie !~ m/^[\+\-]*[0-9]{1,}\.*[0-9]*[\+\-]*$/ ) {
        #if ( $valeurSortie !~ m/^[\+\-]*[0-9]{1,},*[0-9]*[\+\-]*$/ ) {
            &trace( "Somme incorrecte $valeurEntree \n", "X" );
        }

    }
    elsif ( $metier eq 'NC' ) {
        if ( $valeurEntree !~ m/^[0-9]{3}[0-9a-zA-Z]*$/ ) {
            &trace( "Num Compte incorrect $valeurEntree \n", "X" );
        }
    }

    return $valeurSortie;

}

sub trace {
    my ( $mess, $trace ) = @_;
    if ($bug) {
        &erreur( "E", ":ligne " . $ch_plus_ligne . ":" . $mess );
    }
    else {
        &erreur( $trace, ":ligne " . $ch_plus_ligne . ":" . $mess )
            if defined($trace);
    }
}

sub existe_field {
    $line = '';
    $elem = $p->current_element;
    &arbreXML;
    foreach my $ii ( keys %Hf1_fmt ) {
        my $field_fmt
            = $rHf1_fmt->{$ii}{'chemin'} . '_' . $rHf1_fmt->{$ii}{'noeud'};
        if ( $field_fmt eq $arbre ) {
            $line = $p->current_line;
            return $ii;
        }
    }
    if (   $line eq ''
        && $p->current_element ne $flux
        && $lock != 1
        && index( $p->current_line, $arbre ) != -1 )
    {
        &trace(   "\n "
                . $p->current_line
                . " balise ["
                . $p->current_element
                . "] inconnue, lock: $lock , --${arbre}--     \n " );
    }
    return 0;

}

END { unlink $FIFO if defined $FIFO }


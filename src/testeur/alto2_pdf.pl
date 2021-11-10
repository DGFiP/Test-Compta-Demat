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
my $currdir   = dirname( abs_path($0) );
require "$currdir/alto2_fonctions.pl";
use PDF::API2;
use PDF::Table;
use constant mm => 25.4 / 72;
use constant in => 1 / 72;
use constant pt => 1;
use utf8;

# pas de use strict pour définir en global les variables du module
my $p        = 0;
my $pdf      = PDF::API2->new();
my $pdftable = new PDF::Table;

#$font=$pdf->ttfont('georgia', -encode=>'utf8');
&new_page;
$font_name          = 'Helvetica';
$left_edge_of_table = 5 / mm;

# $ypos_of_last_line=280 / mm;

&meta;
&ajoute_rect( 210, 110 );
&ajoute_arc;
$font_size = 18;

sub meta() {
	my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime(time);
	$year += 1900;
	$mon  += 1;
	my $datecreate = sprintf( "%04d%02d%02d%02d%02d%02d",
		${year}, ${mon}, ${mday}, ${hour}, ${min}, ${sec} );
	my %h = $pdf->info(
		'Author'       => "ALTO2",
		'CreationDate' => ${datecreate},
		'ModDate'      => ${datecreate},
		'Creator'      => "ALTO2 $vers_java",
		'Producer'     => "PDF::API",
		'Title'        => "Rapport Technique Conformité A.47 A-1 du LPF",
		'Subject'      => "",
		'Keywords'     => "$file"
	);

}

sub new_page() {
	$p++;
	$page[$p] = $pdf->page( -mediabox => 'A4' );
	$page[$p]->cropbox( 5 / mm, 5 / mm, 200 / mm, 287 / mm );
	$gfx = $page[$p]->gfx;

	$txt = $page[$p]->text;

	$ypos_of_last_line = 284 / mm;

}

sub ajoute_rect() {

	my ( $w, $h ) = @_;

	#my $gfx= $page->gfx;

	# $ypos_of_last_line
	$gfx->fillcolor('lightcyan');
	$gfx->rect( 5 / mm, $ypos_of_last_line - 36 / mm, $w / mm, $h / mm );
	$gfx->fill;
}

sub ajoute_arc() {

	# my $gfx= $page->gfx;

	$gfx->strokecolor('white');

# The ->circle() function takes three parameters: The first two are the X and Y coordinates of the centre (in relation to the bottom left), the third is the radius.
	$gfx->circle( 180 / mm, $ypos_of_last_line - 45 / mm, 45 / mm );
	$gfx->circle( 170 / mm, $ypos_of_last_line - 48 / mm, 43 / mm );
	$gfx->circle( 160 / mm, $ypos_of_last_line - 40 / mm, 46 / mm );
	$gfx->stroke;
}

sub ajoute_liste() {
	my ( $table0, $width, $model ) = @_;
	if ( !defined($model) ) {
		$model = 1;
	}
	my @tref;
	foreach my $elt (@$table0) {
		my @tlis;
		push @tlis, "\x{BA} " . &conv_to_iso($elt);
		push @tref, \@tlis;
	}
	my $rsome = [@tref];
	&ajoute_table( $rsome, $width, $model );
}

sub ajoute_table() {

	# ref à une table de refs, taille, modele 1-2-3-4 colonnes
	my ( $table0, $width, $model ) = @_;
	my $border = 0;
	undef $hdr_props;
	if ( !defined($model) ) {
		$model = 1;
	}
	if ( $model == 1 ) {
		$col_props = [
			{
				min_w   => $width / mm,    # Minimum column width.
				max_w   => $width / mm,    # Maximum column width.
				justify => 'left',         # One of left|center|right ,

			},
		];
		$hdr_props = {
			bg_color => 'lightgrey',
			repeat   => 1
		};
		$border = 1;
	}
	elsif ( $model == 3 ) {
		$col_props = [
			{
				min_w => ( $width - 32 ) / 2 / mm,    # Minimum column width.
				max_w => $width / 2 / mm,             # Maximum column width.
				justify => 'left',    # One of left|center|right ,

			},
			{
				min_w => ( $width - 32 ) / 4 / mm,    # Minimum column width.
				max_w => $width / 4 / mm,             # Maximum column width.
				justify => 'center',    # One of left|center|right ,

			},
			{
				min_w => ( $width - 32 ) / 4 / mm,    # Minimum column width.
				max_w => $width / 4 / mm,             # Maximum column width.
				justify => 'center',    # One of left|center|right ,

			},
		];
		$hdr_props = {
			bg_color  => 'lightgrey',
			font_size => 11,
			repeat    => 1
		};
		$border = 1;
	}
	elsif ( $model == 2 ) {
		$col_props = [
			{
				min_w   => $width / 2 / mm,    # Minimum column width.
				max_w   => 90 / mm,            # Maximum column width.
				justify => 'left',             # One of left|center|right ,

			},
			{
				min_w   => $width / 2 / mm,    # Minimum column width.
				max_w   => 90 / mm,            # Maximum column width.
				justify => 'center',           # One of left|center|right ,

			}
		];
		$hdr_props = {
			bg_color  => 'white',
			font_size => 11,
			repeat    => 1
		};
		$border = 1;
	}
	elsif ( $model == 0 ) {
		$col_props = [
			{
				min_w   => $width / mm,    # Minimum column width.
				max_w   => $width / mm,    # Maximum column width.
				justify => 'left',         # One of left|center|right ,

			},
		];

	}

	# font => $pdf->corefont("Times", -encoding => "latin1"),
	# font_size => 10,
	# font_color=> 'blue',
	# background_color => '#FFFF00',

	# font       => $pdf->corefont("Times", -encoding => "utf8"),
	# font_size  => 10,
	# font_color => '#006666',

	( $end_page, $pages_spanned, $table_bot_y ) = $pdftable->table(

		# required params
		$pdf,
		$page[$p],
		$table0,
		x              => $left_edge_of_table / mm,
		start_y        => $ypos_of_last_line - 5 / mm,
		next_y         => $ypos_of_last_line - 5 / mm,
		start_h        => $ypos_of_last_line - 5 / mm,
		next_h         => $ypos_of_last_line - 5 / mm,
		w              => ($width) / mm,
		padding        => 4,
		padding_right  => 5,
		padding_top    => 5,
		padding_bottom => 5,
#		-gfx_color_odd  => "blue",
#		-gfx_color_even => "red",        #cell gfx color for even rows
		border         => $border,
		border_color   => 'grey',
		font_size      => $font_size,
		font         => $pdf->corefont( $font_name, -encoding => "utf8" ),
		column_props => $col_props,
		header_props => $hdr_props,
	);

# [-padding => "5",] # cell padding
# [-padding_top => "10",] #top cell padding, overides -pad
# [-padding_right  => "10",] #right cell padding, overides -pad
# [-padding_left  => "10",] #left padding padding, overides -pad
# [-padding_bottom  => "10",] #bottom padding, overides -pad
# [-border  => 1,] # border width, default 1, use 0 for no border
# [-border_color => "red",] # default black
# [-font  => $pdf->corefont("Helvetica", -encoding => "latin1"),] # default font
# [-font_size => 12,]
# [-font_color_odd => "purple",]
# [-font_color_even => "black",]

	if ( $pages_spanned > 1 ) {
		$p++;
		$page[$p] = $pdf->page( -mediabox => 'A4' );
		$page[$p]->cropbox( 5 / mm, 5 / mm, 200 / mm, 287 / mm );
		$txt               = $page[$p]->text;
		$ypos_of_last_line = 284 / mm;
	}
	else {
		$ypos_of_last_line = $table_bot_y
		  if $ypos_of_last_line > $table_bot_y;
	}
}

sub ajoute_paragraphe() {

	# paragraphe  , larg en millimetre, haut en milimetre
	my ( $text0, $width, $height, $color ) = @_;

	if ( defined $color ) {
		$txt->fillcolor($color); 
	}
	else {
		$txt->fillcolor('black');
	}
	$font = $pdf->corefont( $font_name, -encoding => "utf8" );
	$txt->font( $font, $font_size );

	# $txt->fillcolor('black');
	( $width_of_last_line, $ypos_of_last_line, $left_over_text ) =
	  $pdftable->text_block(
		$txt,
		$text0,
		-x        => $left_edge_of_table / mm,
		-y        => $ypos_of_last_line - 15 / mm,
		-w        => $width / mm,
		-h        => $height / mm,
		-lead     => $font_size * 1.2,
		-align    => $align,
		-parspace => 0
	  );

	# [-parspace => 0 | $extra_distance_between_paragraphs,]
	# [-align    => "left|right|center|justify|fulljustify",]
	# [-hang     => $optional_hanging_indent,]

}

sub sauve_pdf() {
	my ($nom_pdf) = @_;
	$pdf->saveas("$nom_pdf");
}

sub ombre() {
	my @a     = @_;
	my $old_y = $ypos_of_last_line;
	my $old_x = $left_edge_of_table;
	$a[3] = 'lightgrey';
	&ajoute_paragraphe(@a);
	$ypos_of_last_line  = $old_y + 0.11 / mm;
	$left_edge_of_table = $old_x + ( $font_size / 220 ) / mm;
	$a[3]               = 'grey';

	&ajoute_paragraphe(@a);
	$ypos_of_last_line = $old_y + 0.22 / mm;
	$left_edge_of_table = $old_x + ( $font_size / 110 ) / mm;

	$a[3] = 'black';
	&ajoute_paragraphe(@a);
	$left_edge_of_table = $old_x;
}

1;

use strict;
my ($workdir, $project, $database, $filesample, $help);

use Getopt::Long;
GetOptions(	'filesample|fs=s'		=>	\$filesample,
			'workdir|wd=s'		=>	\$workdir,
			'project|proj=s'		=>	\$project,
			'database|db=s'		=>	\$database,
			'help|h!'		=>	\$help,);
if ($help==1) {
	open HELP, "<$0";
	while (<HELP>) {	print "$_" if (/^##/);	}
	close HELP;	exit(0);
}
print STDERR "04.pep2taxon step4.4 \nparameters: $filesample\n$project\n$workdir\n$database\n";

open (SAM, "<$filesample") or die $!;
my %sampleID; my %rep_lab; my %sam_lab;
my $line = 0;
my @heads; my $filenamei; my $batchidi; my $samidi; my $replabi; my $samlabi;

while (<SAM>) {
	chomp; s/\r//g;
	$line ++;
	if ($line == 1) {
		@heads = split /\,/;
		for my $i (0..$#heads) {
			if ($heads[$i] eq "NameNew") {
				$filenamei = $i;
			}
			if ($heads[$i] eq "BatchID") {
				$batchidi = $i;
			}
			if ($heads[$i] eq "SampleID") {
				$samidi = $i;
			}
			if ($heads[$i] eq "Rep_label") {
				$replabi = $i;
			}
			if ($heads[$i] eq "Sample_label") {
				$samlabi = $i;
			}
		}
	}else{
		my @data = split /\,/;
		my $batchID = $data[$batchidi];
		$sampleID{$batchID} = $data[$samidi];
		$rep_lab{$batchID} = $data[$replabi];
		$sam_lab{$batchID} = $data[$samlabi];
	}
}

my @filter = qw /1 2 3 5 10 15 20/;
for my $filter (@filter) {
	system("ls $workdir/04.pep2taxon/01.matrix/02.taxon_matrix/filter$filter/$project\* > $workdir/04.pep2taxon/01.matrix/02.taxon_matrix/filter$filter/micropeptide.tmp");
	open (TMP, "<$workdir/04.pep2taxon/01.matrix/02.taxon_matrix/filter$filter/micropeptide.tmp") or die $!;
	while (<TMP>) {
		chomp; s/\r//g;
		my $file = $_;
		my $taxon;
		if ($file =~ /filter$filter\_(.*)_matrix/) {
				$taxon = $1;
		}
		open (IN, "<$file") or die $!;
		open (BREP, ">$workdir/04.pep2taxon/01.matrix/02.taxon_matrix/filter$filter/biorep/$project\_diann_$database\_filter$filter\_$taxon\_biorep.txt") or die $!;
		open (TREP, ">$workdir/04.pep2taxon/01.matrix/02.taxon_matrix/filter$filter/techrep/$project\_diann_$database\_filter$filter\_$taxon\_techrep.txt") or die $!;
		open (POOL, ">$workdir/04.pep2taxon/01.matrix/02.taxon_matrix/filter$filter/pool/$project\_diann_$database\_filter$filter\_$taxon\_pool.txt") or die $!;
		open (QC, ">$workdir/04.pep2taxon/01.matrix/02.taxon_matrix/filter$filter/qc/$project\_diann_$database\_filter$filter\_$taxon\_qc.txt") or die $!;
		open (OUT, ">$workdir/04.pep2taxon/01.matrix/02.taxon_matrix/filter$filter/sample/$project\_diann_$database\_filter$filter\_$taxon\_sample.txt") or die $!;
		open (ALL, ">$workdir/04.pep2taxon/01.matrix/02.taxon_matrix/filter$filter/all/$project\_diann_$database\_filter$filter\_$taxon\_all.txt") or die $!;
		my $line = 0; my @head;
		my @hsample; my @hall; my @hbiorep; my @htechrep; my @hpool; my @hqc;
		my @samplei; my @alli; my @biorepi; my @techrepi; my @pooli; my @qci;
		while (<IN>) {
			chomp; s/\r//g;
			$line ++;
			if ($line == 1) {
				@head = split /\t/;
				for my $i (1..$#head) {
					push @alli, $i;
					if ($sam_lab{$head[$i]} =~ /sample/) {
						push @samplei, $i;
					}
					if ($rep_lab{$head[$i]} =~ /biorep/) {
						push @biorepi, $i;
					}
					if ($rep_lab{$head[$i]} =~ /techrep/) {
						push @techrepi, $i;
					}
					if ($rep_lab{$head[$i]} =~ /pool/) {
						push @pooli, $i;
					}
					if ($rep_lab{$head[$i]} =~ /qc/) {
						push @qci, $i;
					}
				}
				for my $i (@alli) {
					push @hall, $head[$i];
				}
				for my $i (@samplei) {
					push @hsample, $sampleID{$head[$i]};
				}
				for my $i (@biorepi) {
					push @hbiorep, $head[$i];
				}
				for my $i (@techrepi) {
					push @htechrep, $head[$i];
				}
				for my $i (@pooli) {
					push @hpool, $head[$i];
				}
				for my $i (@qci) {
					push @hqc, $head[$i];
				}
				my $hallj = join "\t", "Taxon", @hall;
				print ALL "$hallj\n";
				my $hsamplej = join "\t", "Taxon", @hsample;
				print OUT "$hsamplej\n";
				my $hbiorepj = join "\t", "Taxon", @hbiorep;
				print BREP "$hbiorepj\n";
				my $htechrepj = join "\t", "Taxon", @htechrep;
				print TREP "$htechrepj\n";
				my $hpoolj = join "\t", "Taxon", @hpool;
				print POOL "$hpoolj\n";
				my $hqcj = join "\t", "Taxon", @hqc;
				print QC "$hqcj\n";
			}else{
				my @data = split /\t/;
				my $taxon_name = $data[0];
				my @dataall; my @datasample; my @databiorep; my @datatechrep; my @datapool; my @dataqc;
				for my $i (1..$#head) {
					if ($data[$i] eq "") {
						$data[$i] = "NA";
					}
				}
				my $all_notNA = 0;
				for my $i (@alli) {
					push @dataall, $data[$i];
					if ($data[$i] ne "NA") {
						$all_notNA ++;
					}
				}
				my $sample_notNA = 0;
				for my $i (@samplei) {
					push @datasample, $data[$i];
					if ($data[$i] ne "NA") {
						$sample_notNA ++;
					}
				}
				my $biorep_notNA = 0;
				for my $i (@biorepi) {
					push @databiorep, $data[$i];
					if ($data[$i] ne "NA") {
						$biorep_notNA ++;
					}
				}
				my $techrep_notNA = 0;
				for my $i (@techrepi) {
					push @datatechrep, $data[$i];
					if ($data[$i] ne "NA") {
						$techrep_notNA ++;
					}
				}
				my $pool_notNA = 0;
				for my $i (@pooli) {
					push @datapool, $data[$i];
					if ($data[$i] ne "NA") {
						$pool_notNA ++;
					}
				}
				my $qc_notNA = 0;
				for my $i (@qci) {
					push @dataqc, $data[$i];
					if ($data[$i] ne "NA") {
						$qc_notNA ++;
					}
				}
				if ($all_notNA != 0) {
					my $dataallj = join "\t", @dataall;
					print ALL "$taxon_name\t$dataallj\n";
				}
				if ($sample_notNA != 0) {
					my $datasamplej = join "\t", @datasample;
					print OUT "$taxon_name\t$datasamplej\n";
				}
				if ($biorep_notNA != 0) {
					my $databiorepj = join "\t", @databiorep;
					print BREP "$taxon_name\t$databiorepj\n";
				}
				if ($techrep_notNA != 0) {
					my $datatechrepj = join "\t", @datatechrep;
					print TREP"$taxon_name\t$datatechrepj\n";
				}
				if ($pool_notNA != 0) {
					my $datapoolj = join "\t", @datapool;
					print POOL "$taxon_name\t$datapoolj\n";
				}
				if ($qc_notNA != 0) {
					my $dataqcj = join "\t", @dataqc;
					print QC "$taxon_name\t$dataqcj\n";
				}
			}	
		}
	}
}

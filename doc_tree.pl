#!/usr/bin/perl
use Getopt::Long;
use Data::Dumper;

$indent_space     = "    ";
$indent_bar       = "|   ";
$indent_node      = "|-- ";
$indent_node_last = "`-- ";

sub print_node {
    my ($indent, $name, $comment) = @_;
    if ($comment) {
        print "$indent$name : $comment\n";
    } else {
        print "$indent$name\n";
    }
}

sub tree {
    my ($dir, $name, $indent) = @_;
	my @files = ();
    my @dirs = ();
    my @pat = ();
    $opt_debug && print STDERR "tree $dir, $name, $indent\n";

    if (-f "$dir/.tree") {
        open(TREEFILE, "< $dir/.tree") or die("error :$!");
        my $line = <TREEFILE>;
        chomp($line);
        &print_node($indent, $name, $line);   # 現在ディレクトリの表示
        while ($line = <TREEFILE>) {
            chomp($line);
            if ($line =~ /^\s*([^\s]+)(\s+(.*)|)/) {
                my @p = [$1, $3];
                push @pat, @p;
            }
        }
        close(TREEFILE);
    } else {
        &print_node($indent, $name, "");      # 現在ディレクトリの表示
    }

    $indent =~ s/${indent_node_last}/${indent_space}/g;
    opendir(DIR, $dir) or die("Can not open : $dir\n");
    @files = readdir(DIR);
    closedir(DIR);

    my $i = 0;
    foreach my $file(sort @files) {
        $i++;
        next if $file eq '.' || $file eq '..';
        next if $file eq ".tree";
        if(-d "$dir/$file") {
            push @dirs, "$file";
            next;
        }
        foreach $p (@pat) {
            my $re = $$p[0];
            my $comment = $$p[1];
            $re =~ s/\./\\./g;
            $re =~ s/\*/\.\*/g;
            if ($file =~ /${re}/) {
                if ($i == @files && @dirs == 0) {
                    &print_node($indent . $indent_node_last, $file, $$p[1]);
                } else {
                    &print_node($indent . $indent_node, $file, $$p[1]);
                }
            }
        }
    }
    for (my $i = 0; $i < @dirs; $i++) {
        my $subdir = $dirs[$i];
        if ($i == @dirs - 1) {
            &tree("$dir/$subdir", $subdir, $indent . $indent_node_last);
        } else {
            &tree("$dir/$subdir", $subdir, $indent . $indent_node);
        }
    }
}

GetOptions('debug' => \$opt_debug);

# usage: ./doc_tree.pl [dir]
if (@ARGV >= 1) {
    &tree(@ARGV[0], @ARGV[0], "");
} else {
    &tree(".", ".", "");
}

exit 0;

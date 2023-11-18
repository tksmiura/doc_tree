#!/usr/bin/perl
use Data::Dumper;

$indent_space     = "    ";
$indent_bar       = "|   ";
$indent_node      = "|-- ";
$indent_node_last = "`-- ";

sub print_node {
    my ($indent, $name, $comment, $last_i, $last_f) = @_;
    for (my $i = 0; $i < $indent; $i++) {
        if ($i == $indent - 1) {
            if (i < $last_i || $last_f) {
                print $indent_node_last;
            } else {
                print $indent_node;
            }
        } elsif ($i >= $last_i) {
            print $indent_bar;
        } else {
            print $indent_space;
        }
    }
    if ($comment) {
        print "$name : $comment\n";
    } else {
        print "$name\n";
    }
}

sub tree {
    my ($dir, $name, $indent, $last_i, $last_f) = @_;
	my @files = ();
    my @dirs = ();
    my @pat = ();

    if (-f "$dir/.tree") {
        open(TREEFILE, "< $dir/.tree") or die("error :$!");
        my $line = <TREEFILE>;
        chomp($line);
        &print_node($indent, $name, $line, $last_i, $last_f);
        while ($line = <TREEFILE>) {
            chomp($line);
            if ($line =~ /^\s*([^\s]+)(\s+(.*)|)/) {
                my @p = [$1, $3];
                push @pat, @p;
            }
        }
        close(TREEFILE);
    } else {
        &print_node($indent, $name, "", $last_i, $last_f);
    }
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
                    &print_node($indent + 1, $file, $$p[1], $last_i, 1);
                } else {
                    &print_node($indent + 1, $file, $$p[1], $last_i, 0);
                }
            }
        }
    }
    for (my $i = 0; $i < @dirs; $i++) {
        my $subdir = $dirs[$i];
        if ($i == @dirs - 1) {
            if ($last_f) {
                &tree("$dir/$subdir", $subdir, $indent + 1, $last_i + 1, 0);
            } else {
                &tree("$dir/$subdir", $subdir, $indent + 1, $last_i, 1);
            }
        } else {
            &tree("$dir/$subdir", $subdir, $indent + 1, $last_i, 0);
        }
    }
}

# usage: ./doc_tree.pl [dir]
if (@ARGV >= 1) {
    &tree(@ARGV[0], @ARGV[0], 0, 0, 1);
} else {
    &tree(".", ".", 0, 0, 1);
}

exit 0;

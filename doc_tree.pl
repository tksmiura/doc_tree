#!/usr/bin/perl
use Getopt::Long;
use Data::Dumper;

$indent_space     = "    ";
$indent_bar       = "|   ";
$indent_node      = "|-- ";
$indent_node_last = "`-- ";

sub print_indent {
    my ($indent_list) = @_;
    my @indent = @$indent_list;
    #print Dumper @indent;
    foreach my $i (@indent) {
        if ($i == 1) {
            print $indent_bar;
        } elsif ($i == 2) {
            print $indent_node_last;
        } elsif ($i == 3) {
            print $indent_node;
        } else {
            print $indent_space;
        }
    }
}
sub print_nodes {
    my ($tree_ref, $indent_list) = @_;   # ツリー構造, インデントリスト
    my @tree = @$tree_ref;
    my @indent = @$indent_list;
    my $i;
    for ($i = 0; $i < @tree; $i++) {
        my $l = $tree[$i];
        if (ref($l) eq "ARRAY") {
            my @sub_indent = @indent;
            if ($i == @tree - 1) {
                push @sub_indent, 2;
            } else {
                push @sub_indent, 3;
            }
            &print_nodes($l, \@sub_indent);
        } elsif ($i == 0) {
            &print_indent(\@indent);
            print "$l\n";
            if (@indent > 0 && $indent[$#indent] == 2) {
                $indent[$#indent] = 0;
            }
            if (@indent > 0 && $indent[$#indent] == 3) {
                $indent[$#indent] = 1;
            }
        } elsif ($i == @tree - 1) {
            &print_indent(\@indent);
            print "$indent_node_last$l\n";
        } else {
            &print_indent(\@indent);
            print "$indent_node$l\n";
        }
    }
}

sub tree {
    my ($dir, $name) = @_;   # ディレクトリパス、ディレクトリ名
	my @files = ();
    my @dirs = ();
    my @pat = ();
    my @result = ();

    $opt_debug && print STDERR "tree $dir, $name\n";
    if (-f "$dir/.tree_ignore") {           # .tree_ignoreがあればそのディレクトリは無視
        return;
    }
    if (-f "$dir/.tree") {
        open(TREEFILE, "< $dir/.tree") or die("error :$!");
        my $line = <TREEFILE>;
        chomp($line);
        push @result, "$name : $line";
        while ($line = <TREEFILE>) {
            chomp($line);
            if ($line =~ /^\s*([^\s]+)(\s+(.*)|)/) {
                my @p = [$1, $3];
                push @pat, @p;
            }
        }
        close(TREEFILE);
    } else { #.treeのない場合
        push @result, "$name";
    }

    opendir(DIR, $dir) or die("Can not open : $dir\n");
    @files = readdir(DIR);
    closedir(DIR);

    my $i = 0;
    my $printed;
    foreach my $file(sort @files) {
        $i++;
        next if $file eq '.' || $file eq '..';
        next if $file eq ".tree";
        next if $file eq ".git";
        $printed = 0;

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
                push @result, "$file : $$p[1]";
                $printed = 1;
                last;
            }
        }
        if (!$printed && $opt_brief && -r "$dir/$file") {
            #            my $head = `head $dir/$file | grep breif`;
            my $head = `head $dir/$file |grep \@brief`;
#            print "debug $dir$file $head\n";
            if ($head =~ /\@brief\s+(.*)/) {
                push @result, "$file : $1";
            }
        }
    }
    for (my $i = 0; $i < @dirs; $i++) {
        my $subdir = $dirs[$i];
        my $sub_tree = &tree("$dir/$subdir", $subdir);
        push @result, $sub_tree;
    }

    return \@result;
}

# usage: ./doc_tree.pl [-b] [dir]
GetOptions('debug' => \$opt_debug, 'brief' => \$opt_brief);


if (@ARGV >= 1) {
    $tree = &tree(@ARGV[0], @ARGV[0]);
} else {
    $tree = &tree(".", ".");
};

#print Dumper $tree;
&print_nodes($tree, []);

exit 0;

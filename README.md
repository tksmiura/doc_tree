# doc_tree

Explain the directory structure.

## usage

   1. make .tree file
   2. write Explanatory text to .tree file<BR>
      first line is explain directory.<BR>
      other lines are explain files.<BR>

```
ビルドディレクトリ
*.c ソースファイル
*.h ヘッダファイル
Makefile  メイクファイル
```

   3 run doc_tree

```
$./doc_tree <dir>
```

## sample

```
$ ./doc_tree.pl sample/
sample/
|-- inc : インクルード
|-- lib : ライブラリ
`-- src : ビルドディレクトリ
    |-- Makefile : メイクファイル
    |-- test.c : ソースファイル
    `-- test.h : ヘッダファイル
```

# doitex.rb

Script to automatically parse doi citations from LaTeX documents and download
the corresponding references from CrossRef.

## Usage

Just cite references in your LaTeX document using the format `\cite{doi:<doi>}`.
Then, after running `latex`, `pdflatex`, `xelatex`, etc., run
```
ruby doitex.rb <aux_file> <bib_file>
```
Your `bib_file` will automatically be augmented with the missing references.
If you are compiling a LaTeX document called `article.tex` with a bibliography file `references.bib`, run
```
pdflatex article
ruby doitex.rb article.aux references.bib
bibtex article
pdflatex article
pdflatex article
```
Hopefully in the future I/you/we can incorporate this into a latexmk workflow.

### Using a mapping file

You can also specify a key-to-doi mapping file in YAML format:
```
citekey1: doi1
citekey2: doi2
...
```
This might be useful if you want to use identifiable citation keys in your
latex document, almost like a barebones bibtex file. Then just call doitex with the `-m` option:
```
ruby doitex.rb -m <ref_map> <aux_file> <bib_file>
```

### Citations that don't have a DOI

No problem! `doitex` just adds missing references to an existing `bib` file,
so you can have anything else in there too.

## Dependencies

- [bibtex-ruby](https://github.com/inukshuk/bibtex-ruby])
- [serrano](https://github.com/sckott/serrano)

## Installation

You need ruby (comes with macOS and generally with Linux). I've tested this on Ruby 2.4.2, but raise issues if you find compatibility problems.
Then, just install the dependencies:
```
gem install bibtex-ruby serrano
```

### CrossRef polite pool

CrossRef has a **polite pool**. To get into it, either specify your email address on the command line with the `-e` flag, or set the `CROSSREF_EMAIL` environmental variable.

## Future work (contributions welcome!)

1. Create a proper gem.
2. Figure out how to add doitex to the latexmk workflow.

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

## Dependencies

- [https://github.com/inukshuk/bibtex-ruby](bibtex-ruby)
- [https://github.com/sckott/serrano](serrano)

## Future work (contributions welcome!)

1. Create a proper gem.
2. Figure out how to add doitex to the latexmk workflow.

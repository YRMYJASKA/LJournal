# LJournal

A LaTeX journalling system. The system here is inspired what is outlined in a
[blog post](https://castel.dev/post/research-workflow/).

# Installation

## Requirements
- ```yq``` (via ```python -m pip install yq```) and ```jq``` (via your package manager),
- AucTeX (via ```(package-use tex)``` or similar).
- ```f.el``` 



## Downloading

### Using ```ljournal.el``` directly
1. Download the ```ljournal.el``` file in this git repo.
2. TODO: finish this explanation.

## Setting up
It is recommended that you define a configuration directory from which ljournal will extract
its default preamble file from for projects. 

# Usage
Use ```ljournal-create-project``` to create a skeleton for a journalling project
at chosen directory. Then you can add notes via ```ljournal-add-note``` and choosing
the project you want. Then emacs visits the new note file which is a bare-bones
TeX file with only a time-stamp. After done writing a note for today, 
you can compile the project with ```ljournal-compile-project``` which will create a ```main.tex```
file in the root directory of the project and compile it using ```TeX-command-master``` to preserve
your unique compilation commands.

You can alter the title, author, and abstract in the ```metadata.yaml``` file for every project 
located in their respective roots.

## Structure of a lJournal projecst
The projects are structure as follows:
```
.
├── main.tex              <--- Main file created by compilation.
├── metadata.yaml         <--- Contains info about project such as title and author.
├── preamble.tex          <--- Copied skeleton preamble from configuration dir.
└── sections              <--- Directory containing all notes.
     └── 2022-04-12       <--- A directory for a specific day.
        └── section.tex     <--- Corresponding note for that day.
    └── 2022-04-13
        └── section.tex

```

## Configuration options
You are intended to customize these variables using ```customize-variable```.

- ```ljournal-dateformat```: which dateformat to use for time-stamps. Implicitly also determines
the frequency of notes taken. (default: ```"%Y-%m-%d"```).
- ```ljournal-section-filename```: filename of the files created for notes. (default ```section.tex```) 
- ```ljournal-config-dir```: directory containing ```preamble.tex``` that is used as a default
preamble file for the main pdf created by the notes. (default: ```nil```)
- ```ljournal-projects```: a list of all active projects that you can add notes to. Maintained by ```ljournal-add-project```. 
If editing manually, make sure that you create the skeleton properly.
(default: ```nil```)
- ```ljournall-default-author```: pretty self-explanatory. (default: ```""```)

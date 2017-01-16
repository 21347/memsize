# memsize
Small pascal program to find and size memory on 286-based IBM compatible machines that the BIOS does not see.

## Background

Some time ago, I aquired an old Everex RAM 8000 memory expansion card for the ISA16 bus. It was fully equipped with DRAM, the system - a Commodore PC 10-III with 1 MiB of onboard DRAM - did not find it. I cound not find any software for this card, documentation is also very rare. I tried some configurations and other computers and came to the conclusion, that it might be configured not to beginn at address 0x00100000 (1 Meg) but at 0x00400000. To test my assumption, I wrote that short program to test and find memory that the computers BIOS did not find - it stops at the first 64 KiB block it cannot write to (you may have a look at the original IBM BIOS' source code which is available on the web - I bet the code did not change a lot over decades...)

## Installation

Take your favourite 80286 based computer and load the executable on a floppy disk. It should wirk with almost all flavours of DOS, however I tested it with M$ DOS v5 only lately.

## Usage example

Parameters are as follows:

```
 MEMSIZE [options]

 Optinos:
   /NoA20    : Do not change A20
   /DisA20   : Switch A20 off instead of on
   /16M      : Test all 16MiB, not above 1MiB
   /Dump     : Print LOADALL parameters
   /Halt     : Halt system after execution
   /?, /Help : Show this little info
```

When executing in a [PCem](https://pcem-emulator.co.uk/) emulated Ami 286 system, it might look like this: [PCem Screenshot](PCem-AMI286.png?raw=true)

## Development setup

### FreePascal 3.0
Note: up to now, the program can be compiled, but not executed.

Take a look on the [FreePascal Wiki](http://wiki.freepascal.org/DOS) to learn how to install a MS-DOS crosscompiler for FreePascal. It works pretty well, however it generates only 8086 code. This does not hurt, except for the 80286 specific stuff (like the Mashine Status Word for example, or "SHL reg, imm8" for logical shifts). Those instructions have been framed in FPC-specific IFDEFs. To compile MEMSIZE, you may use something like this:

```sh
ppcross8086 -WmTiny -Wtcom MEMSIZE.PAS
```

### Turbo Pascal 7
You need to have (or find) a functioning copy of Borland's Turbo Pascal, e.g. version 7. This can be done e.g. in DOSbox. Copy all 4 .PAS-Files, and compile "CPU286.PAS" first. After that, you can compile "MEMSIZE.PAS".


### Localization
All language-specific strings (I hope) are stored in separate source files. You may choose your favourite translation by changing the respective define in "MEMSIZE.PAS":

```pascal
{Localization:}
{$I MSLANGDE.PAS}
```

Currently, "MSLANGDE.PAS" and "MSLANGEN.PAS" for German and English are available.

## Release History

* 0.2.0
    * FIX: should not work on all IBM286 compatibles now
    * CHANGE: FreePascal can now be used to compile the sources for DOS, the program itself however does not work by now
* 0.1.0
    * changed to real-mode and LOADALL, using TP7
* 0.0.1
    * 1st version using protected mode exceptions, quit buggy and non portable

## Foreign code

Parts of this software (as noted in the sources) is based in Rober R. Collin's exccelent LOADALL code for the 80286 processor, see [his page about the LOADALL-instruction](http://www.rcollins.org/articles/loadall/tspec_a3_doc.html) for details.

## Meta

Alexander J. L. Hofmann – https://www.nerdlingen.de – Kontakt@nerdlingen.de

Distributed under the GNU GPLv3 license. See ``LICENSE`` for more information.

[https://github.com/21347/memsize](https://github.com/21347/memsize)


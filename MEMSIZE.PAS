(*
   MEMSIZE - Find and size memory not found by the BIOS
   Copyright (C) 2017  Alexander J. L. Hofmann

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software Foundation,
   Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA

   ===========

   Some routines are based on the excelent source and
   information by Robert R. Collins (rcollins@x86.org)
   http://www.rcollins.org/articles/loadall/tspec_a3_doc.html
*)

(* $G will generate 286 compatible code in TP7, uncomment in FreePascal *)
{$G+}


program Memsize;

uses Dos, Crt, Cpu286;

type
  DescCache286 = packed record
    Addr_A15_A00:word;
    Addr_A23_A16:byte;
    Access:byte;
    Limit:word;
  end;

  LDAllStruct = packed record
    reserved1:array[0..2] of word;
    MSW:word;
    reserved2:array[0..6] of word;
    TR_REG,
    FLAGS,
    IP,
    LDT_REG,
    DS_REG,
    SS_REG,
    CS_REG,
    ES_REG,
    DI_REG,
    SI_REG,
    BP_REG,
    SP_REG,
    BX_REG,
    DX_REG,
    CX_REG,
    AX_REG:word;
    ES_DESC,
    CS_DESC,
    SS_DESC,
    DS_DESC,
    GDT_DESC,
    LDT_DESC,
    IDT_DESC,
    TSS_DESC:DescCache286;
  end;

const
  LDAllSize = SizeOf(LDAllStruct);

var
  LDAllParams:LDAllStruct;
  LDALLDest:array [0..LDAllSize] of byte absolute $0080:$0000;
  LDAllSave:array [0..LDAllSize] of Byte;

  {Config: Dump LOADALL-Parameters before executing the instruction}
  conf_DumpParams:boolean;
  {Config: A20 nicht steuern vor dem Start}
  conf_NoA20:boolean;
  {Config: System anhalten nach dem Test}
  conf_Halt:boolean;
  {Config: DISABLE Gate A20 instead of enabling it}
  conf_DisableA20:boolean;
  {Config: Test all 16M, not only 1MiB upwards}
  conf_16M:boolean;

{Localization:}
{$I MSLANGEN.PAS}

{Convert Integer to it's hexadecimal representation}
function IntToHex(n: LongInt; digits: Integer): string;
const
  hexdigits: array [0..15] of char = '0123456789ABCDEF';
var
  s: string;
  i: Integer;
begin
  s := '';
  for i := 1 to digits do begin
    s:=hexdigits[Word(n) and $000F]+s;
    n:=n shr 4;
  end;
  IntToHex:=s;
end;

{Simple kack to clear the keyboard buffer}
procedure CrtClearKeyboardBuffer;
begin
  while KeyPressed do ReadKey;
end;

{Calculate the 32-Bit address from a real-mode address
 Input:  ES:SI - RealMode address
 Output: DX:AX - physical address}
{$IFDEF FPC}
(* Freepascal currently generates code for the 8086 only. This program contains
only a few instructions that are not present int the 8086 family; to be precise: 
8086 does not have the shl reg, imm instruction. *)
procedure GetPhysicalAddress_ASM; assembler;
asm
  push cx
  xor cx, cx
  mov cl, 4
  mov ax, es  {Point to controll block}
  xor dh, dh
  mov dl, ah  {HiByte of the 32-bit address}
  shr dl, cl  {use only the higher 4 bits}
  shl ax, cl  {remove the top 4bit of the segment}
  add ax, si  {Add offset from LoWord}
  adc dx, 0   {Adjust HiByte and move overflow to LoByte}
  pop cx
end;
{$ELSE}
procedure GetPhysicalAddress_ASM; assembler;
asm
  mov ax, es  {Point to controll block}
  xor dh, dh
  mov dl, ah  {HiByte of the 32-bit address}
  shr dl, 4   {use only the higher 4 bits}
  shl ax, 4   {remove the top 4bit of the segment}
  add ax, si  {Add offset from LoWord}
  adc dx, 0   {Adjust HiByte and move overflow to LoByte}
end;
{$ENDIF}

{Dump contents of the parameters prepared to be sent to LOADALL}
procedure PrintParams;
begin
  CrtClearKeyboardBuffer;
  Writeln('LDAll-Params: ');
  Write('MSW :', IntToHex(LDAllParams.MSW, 4));
  Writeln('; TR_REG:', IntToHex(LDAllParams.TR_REG, 4));
  Write('FLAGS :', IntToHex(LDAllParams.FLAGS, 4));
  Writeln('IP:', IntToHex(LDAllParams.IP, 4));
  Writeln('LDT_REG  :', IntToHex(LDAllParams.LDT_REG, 4));
  Writeln('DS_REG   :', IntToHex(LDAllParams.DS_REG, 4));
  Writeln('SS_REG   :', IntToHex(LDAllParams.SS_REG, 4));
  Writeln('CS_REG   :', IntToHex(LDAllParams.CS_REG, 4)); 
  Writeln('ES_REG   :', IntToHex(LDAllParams.ES_REG, 4)); 
  Writeln('DI_REG   :', IntToHex(LDAllParams.DI_REG, 4)); 
  Writeln('SI_REG   :', IntToHex(LDAllParams.SI_REG, 4)); 
  Writeln('BP_REG   :', IntToHex(LDAllParams.BP_REG, 4));
  Writeln('SP_REG   :', IntToHex(LDAllParams.SP_REG, 4)); 
  Writeln('BX_REG   :', IntToHex(LDAllParams.BX_REG, 4)); 
  Writeln('DX_REG   :', IntToHex(LDAllParams.DX_REG, 4));
  Writeln('CX_REG   :', IntToHex(LDAllParams.CX_REG, 4)); 
  Writeln('AX_REG   :', IntToHex(LDAllParams.AX_REG, 4));
  Writeln('ES_DESC  :', IntToHex(LDAllParams.ES_DESC.Addr_A15_A00, 4),', ',
    IntToHex(LDAllParams.ES_DESC.Addr_A23_A16, 2),', ',
	IntToHex(LDAllParams.ES_DESC.Access, 2),', ',
	IntToHex(LDAllParams.ES_DESC.Limit, 4));
  Writeln('CS_DESC  :', IntToHex(LDAllParams.CS_DESC.Addr_A15_A00, 4),', ',
    IntToHex(LDAllParams.CS_DESC.Addr_A23_A16, 2),', ',
	IntToHex(LDAllParams.CS_DESC.Access, 2),', ',
	IntToHex(LDAllParams.CS_DESC.Limit, 4)); 
  Writeln('SS_DESC  :', IntToHex(LDAllParams.SS_DESC.Addr_A15_A00, 4),', ',
    IntToHex(LDAllParams.SS_DESC.Addr_A23_A16, 2),', ',
	IntToHex(LDAllParams.SS_DESC.Access, 2),', ',
	IntToHex(LDAllParams.SS_DESC.Limit, 4)); 
  Writeln('DS_DESC  :', IntToHex(LDAllParams.DS_DESC.Addr_A15_A00, 4),', ',
    IntToHex(LDAllParams.DS_DESC.Addr_A23_A16, 2),', ',
	IntToHex(LDAllParams.DS_DESC.Access, 2),', ',
	IntToHex(LDAllParams.DS_DESC.Limit, 4)); 
  Writeln('GDT_DESC :', IntToHex(LDAllParams.GDT_DESC.Addr_A15_A00, 4),', ',
    IntToHex(LDAllParams.GDT_DESC.Addr_A23_A16, 2),', ',
	IntToHex(LDAllParams.GDT_DESC.Access, 2),', ',
	IntToHex(LDAllParams.GDT_DESC.Limit, 4)); 
  Writeln('LDT_DESC :', IntToHex(LDAllParams.LDT_DESC.Addr_A15_A00, 4),', ',
    IntToHex(LDAllParams.LDT_DESC.Addr_A23_A16, 2),', ',
	IntToHex(LDAllParams.LDT_DESC.Access, 2),', ',
	IntToHex(LDAllParams.LDT_DESC.Limit, 4));
  Writeln('IDT_DESC :', IntToHex(LDAllParams.IDT_DESC.Addr_A15_A00, 4),', ',
    IntToHex(LDAllParams.IDT_DESC.Addr_A23_A16, 2),', ',
	IntToHex(LDAllParams.IDT_DESC.Access, 2),', ',
	IntToHex(LDAllParams.IDT_DESC.Limit, 4)); 
  Writeln('TSS_DESC :', IntToHex(LDAllParams.TSS_DESC.Addr_A15_A00, 4),', ',
    IntToHex(LDAllParams.TSS_DESC.Addr_A23_A16, 2),', ',
	IntToHex(LDAllParams.TSS_DESC.Access, 2),', ',
	IntToHex(LDAllParams.TSS_DESC.Limit, 4));
  writeln(str_PressKeyToTest);
  repeat until KeyPressed;
  CrtClearKeyboardBuffer;
end;

{Main function to test a given 64k-block of ram,
Input: LoWord + HiByte: adress of memory to be tested
Output: true when the 1st byte of memory in this block can be written}
function Testmem(LoWord:word; HiByte:byte):boolean;
var
  i:integer;
  status:word;
label
  ZielLabel;
begin
  {Clear LOADALL-Data to 0}
  FillChar(LDAllParams, SizeOf(LDAllStruct), 0);
  with LDAllParams do begin
    FLAGS:=2; {TODO: Where is the 2 from?}
    ES_DESC.Access:=$93;
    ES_DESC.Limit:=$FFFF;
    DS_DESC.Access:=$93;
    DS_DESC.Limit:=$FFFF;
    SS_DESC.Access:=$93;
    SS_DESC.Limit:=$FFFF;
    CS_DESC.Access:=$9B;
    CS_DESC.Limit:=$FFFF;
    Ldt_Desc.Addr_A23_A16:=$06;
    Ldt_Desc.Access:=$82;
    Ldt_Desc.Limit:=$0088;
    Idt_Desc.Limit:=$03FF;
    TSS_Desc.Addr_A23_A16:=$05;
    TSS_Desc.Access:=$98;
    TSS_Desc.Limit:=$0008;
  end;
  asm
    {Backup registers}
    push ax
    push dx
    push es
    push si
    {CodeSegment}
    mov ax, cs
    mov word ptr [LDAllParams.CS_REG], ax
    mov es, ax
    mov si, 0
    call GetPhysicalAddress_ASM
    mov word ptr [LDAllParams.CS_Desc.Addr_A15_A00], ax
    mov byte ptr [LDAllParams.CS_Desc.Addr_A23_A16], dl
    {DataSegment}
    mov ax, ds
    mov word ptr [LDAllParams.DS_REG], ax
    mov es, ax
    mov si, 0
    call GetPhysicalAddress_ASM
    mov word ptr [LDAllParams.DS_Desc.Addr_A15_A00], ax
    mov byte ptr [LDAllParams.DS_Desc.Addr_A23_A16], dl
    {ES will point to the memory to test}
    mov ax, LoWord
    mov word ptr [LDAllParams.ES_Desc.Addr_A15_A00], ax
    mov al, HiByte
    mov byte ptr [LDAllParams.ES_Desc.Addr_A23_A16], al
    {SS}
    mov ax, ss
    mov word ptr [LDAllParams.SS_REG], ax
    mov es, ax
    mov si, 0
    call GetPhysicalAddress_ASM
    mov word ptr [LDAllParams.SS_Desc.Addr_A15_A00], ax
    mov byte ptr [LDAllParams.SS_Desc.Addr_A23_A16], dl
    {copy Machine Status Word}
{$IFDEF FPC}
    db 0Fh, 01h, 0E0h {smsw ax; smsw off course did not exist for the 8086 so the assembler will complain}
{$ELSE}
    smsw ax
{$ENDIF}
    mov word ptr [LDAllParams.MSW], ax
    {where to continue after LOADALL}
    mov word ptr [LDAllParams.IP], offset ZielLabel
    {Other registers}
    mov word ptr [LDAllParams.DI_REG], DI
    mov word ptr [LDAllParams.SI_REG], SI
    mov word ptr [LDAllParams.BP_REG], BP
    mov word ptr [LDAllParams.SP_REG], SP
    mov word ptr [LDAllParams.BX_REG], BX
    mov word ptr [LDAllParams.DX_REG], DX
    mov word ptr [LDAllParams.CX_REG], CX
    mov word ptr [LDAllParams.AX_REG], AX
  end;
  if conf_DumpParams then PrintParams;
  {Make a backup of the data about to be overwritten}
  Move(LDAllDest, LDAllSave, LDAllSize);
  {Write prepared data to $0800...}
  Move(LDAllParams, LDAllDest, LDAllSize);
  asm
    {Magic!}
    db 0Fh, 05h
  end;
  {In case of error...}
  Move(LDAllSave, LDAllDest, LDAllSize);
  writeln;
  Writeln(str_ErrorLine1);
  writeln(str_ErrorLine2);
  while true do begin asm hlt end; end;
  {End of error handler}
ZielLabel:
  asm
    {This is where we should be after a successfull LOADALL}
    {ES points to the memory to be tested. So back it up, write
     something to it and test...}
    nop
    mov ax, $A55A
    xor si, si
{$IFDEF FPC}
    {Backup}
    mov dx, word ptr ES:[SI]
    {Write...}
    mov word ptr ES:[SI], ax
    nop
    {Read}
    mov ax, word ptr ES:[SI]
    {Restore}
    mov word ptr ES:[SI], dx
{$ELSE}
    {Backup}
    mov dx, word ptr [ES:SI]
    {Write...}
    mov word ptr [ES:SI], ax
    nop
    {Read}
    mov ax, word ptr [ES:SI]
    {Restore}
    mov word ptr [ES:SI], dx
{$ENDIF}

    mov [status], ax {=$A55A if successfull}
    {Restore some registeres...}
    pop si
    pop es
    pop dx
    pop ax
  end;
  {End}
  Testmem:=(status = $A55A);
  {Restore original data that was overwritten for LOADALL}
  Move(LDAllSave, LDAllDest, LDAllSize);
end;

{Test the requested address-range, start either at 1MiB or 0.
If conf_16M is set, it will start testing a address 0. This should
normally display 640KiB of base memory, and a 384KiB large "hole" where
the bios resides; on a standard AT286 system this area os not writable.}
procedure TestAllMem;
var
  i:integer;
  count, oldData, totalBlocks: word;
  blockStart:byte;
  pos,posB,memStart:longint;
  blockInfos:array [0..255] of byte; {TODO: might use much less memory when using bits and not bytes ;-)}
begin
  count:=0;
  for i:=0 to 255 do blockInfos[i]:=0;
  {if conf_16M is set, then start at 0 - otherwise start at block 16}
  if conf_16M then begin
    totalBlocks := 256; (* 64KB-Steps times 256 = 16 MiB *)
    blockStart := 0;
    memStart := 0;
  end
  else begin
    totalBlocks := 240; (* 64KB-Steps times 240 = 15 MiB *)
    blockStart := 16;
    memStart := 1024*1024;
  end;

  {Test all requested blocks and store the results}
  for i:=0 to totalBlocks-1 do begin
    if TestMem(0, blockStart+i) then begin
      Inc(count);
      blockInfos[i]:=1;
    end;
  end;

  {Output sumary}
  if conf_16M then write(str_BlocksFound)
  else Write(str_BlocksOver1MB);
  writeln(count);
  writeln;

  {Summ up blocks and output the data as a table}
  writeln(str_Details);
  writeln(str_TableHeader);
  oldData:=blockInfos[0];
  pos:=memStart;
  posB:=0;
  count:=1;
  for i:=1 to totalBlocks-1 do begin
    if (blockInfos[i]<>oldData) or (i=totalBlocks-1) then begin
      posB:=memStart;
      posB:=posB+LongInt(i)*LongInt(65536)-1;
      Write('  ',count:3,', ',IntToHex(pos, 8),' - ',IntToHex(posB,8),': ');
      if oldData=0 then write(str_NA)
      else write(str_Existent);
      writeln(' (',(posB-pos+1) div 1024,' KiB)');
      oldData:=blockInfos[i];
      pos:=posB+1;
      Inc(count);
    end;
  end;
end;

{Parse parameters given to the program and store the configuration
int it's respective variables}
procedure ParseParams;
var
  i,a:integer;
  s:string;
begin
  conf_NoA20 := false;
  conf_DumpParams := false;
  conf_Halt := false;
  conf_DisableA20 := false;
  conf_16M := false;

  for i:=1 to ParamCount do begin
    s := ParamStr(i);
    for a:=1 to Length(s) do s[a]:=UpCase(s[a]);
    if s = str_SwitchNoA20  then conf_NoA20 := true;
    if s = str_SwitchDisA20 then conf_DisableA20 := true;
    if s = str_Switch16M    then conf_16M := true;
    if s = str_SwitchDump   then conf_DumpParams := true;
    if s = str_SwitchHalt   then conf_Halt := true;
    if (s = str_SwitchHelp) or (s = '/?') then PrintUsage;
  end;
end;

{Read one word from the CMOS-RAM}
{$IFDEF FPC}
function ReadCMOSWord(addr:byte):word;
var res:word;
begin
  asm
    push ax
    push cx
    xor ax, ax
    xor cx, cx
    mov al, addr
    out 70h, al
    in al, 71h
    mov cl, al
    mov al, addr
    inc al
    out 70h, al
    in al, 71h
    mov ch, al
    mov res, cx
    pop cx
    pop ax
  end;
  ReadCMOSWord:=res; {Word(lo) or (Word(hi) shl 8);}
end;
{$ELSE}
function ReadCMOSWord(addr:byte):word;
var lo, hi:byte;
begin
  PORT[$70]:=addr;
  lo:=PORT[$71];
  PORT[$70]:=addr+1;
  hi:=PORT[$71];
  ReadCMOSWord:=Word(lo) or (Word(hi) shl 8);
end;
{$ENDIF}

begin
  {Print greeting, copyright}
  PrintGreeting;
  writeln('(GPLv3, ',str_Copy,' 2017 Alexander J. L. Hofmann)');
  {Parse params - will print the usage and exit if requested}
  ParseParams;
  Writeln;

  {Enable/Disable A20?}
  if conf_NoA20 then begin
    Writeln(str_A20NotChanged);
  end
  else begin
    if conf_DisableA20 then begin
      if Disable_gate20 <> 0 then
        writeln(str_A20DisableError)
      else
        writeln(str_A20DisableSuccess);
    end
    else begin
      if Enable_gate20 <> 0 then
        writeln(str_A20Error)
      else
        writeln(str_A20Success);
    end;
  end;

  {Tell us what the BIOS thinks we have:}
  Writeln('CMOS:');
  Write('- Base memory: ');
  Write(ReadCMOSWord($15)); Writeln(' KiB.');
  Write('- XMS (configured): ');
  Write(ReadCMOSWord($17)); Writeln(' KiB.');
  Write('- XMS (discovered): ');
  Write(ReadCMOSWord($30)); Writeln(' KiB.'); 
  writeln;

  {Test memory!}
  writeln;
  TestAllMem;
  Writeln;
  {If configured, halt the system}
  if conf_Halt then begin
    Writeln(str_SystemHalted);
    while true do
      asm hlt end;
  end
  {Else display some text and wait for a keystroke to exit}
  else begin
    CrtClearKeyboardBuffer;
    Writeln(str_PressKeyToExit);
    repeat until KeyPressed;
    CrtClearKeyboardBuffer;
  end;
end.


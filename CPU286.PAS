(* CPU286.PAS - Routines to control memory acces on 80286 compatible CPUs

Based on and translated from the excelent source and
information by Robert R. Collins (rcollins@x86.org)
http://www.rcollins.org/articles/loadall/tspec_a3_doc.html

*)

unit Cpu286;

interface

function Enable_gate20:byte;
function Disable_gate20:byte;
function Gate_A20:byte;
function Empty_8042:byte;

implementation

const
        KBC_CTL         =     $060    ; (* 8042 control port     *)
        KBC_STAT        =     $064    ; (* 8042 status port      *)
        inpt_buf_full   =     2       ; (* Input buffer full    *)
        enable_bit20    =     $0df    ; (* enable A20 command   *)
        disable_bit20   =     $0dd    ; (* disable A20 command  *)

function Enable_gate20:byte; assembler;
asm
  mov     ah,enable_bit20
  Call    Gate_A20
end;

function Disable_gate20:byte; assembler;
asm
  mov     ah,disable_bit20
  Call    Gate_A20
end;

(*
; Input:   AH = DD ==> A20 gated off (A20 always 0)
;          AH = DF ==> A20 gated on  (CPU controls A20)
; Output:  AL = 0  ==> Operation successful
;          AL = 2  ==> Operation failed, 8042 can't accept cmd
; Register(s) modified:  AX *)
function Gate_A20:byte; assembler;
label A20_Fail, DLY;
asm
  pushf                   (* save interrupt status            *)
  cli                     (* disable ints while using 8042    *)
  Call    Empty_8042      (* insure 8042 input buffer empty   *)
  jnz     A20_Fail        (* ret: 8042 unable to accept cmd   *)
  out     $0ED, ax        (* I/O Delay                        *)
  mov     al,0D1h         (* 8042 cmd to write output port    *)
  out     KBC_STAT,al     (* output cmd to 8042               *)
  Call    Empty_8042      (* wait for 8042 to accept cmd      *)
  jnz     A20_Fail        (* ret: 8042 unable to accept cmd   *)
  mov     al,ah           (* 8042 port data                   *)
  out     KBC_CTL,al      (* output port data to 8042         *)
  Call    Empty_8042      (* wait for 8042 to port data       *)
  push    cx              (* save it                          *)
  mov     cx,14h
DLY:
  out     $0ED, ax        (* Wait for KBC to execute the      *)
  loop    DLY             (*  command.  (about 25uS)          *)
  pop     cx              (* restore it                       *)
A20_Fail:
  popf                    (* restore flags                    *)
end;

(*
; EMPTY_8042:  This routine waits for the 8042 buffer to empty.
;---------------------------------------------------------------
; Input:   None
; Output:  AL = 0, 8042 input buffer empty:     ZF
;          AL = 2, Time out; 8042 buffer full:  NZ
; Register(s) modified:  AX
;---------------------------------------------------------------
  Empty_8042    proc    near
;---------------------------------------------------------------
*)
function Empty_8042:byte; assembler;
label Try_KBC;
asm
  push    cx               (* save CX                       *)
  xor     cx,cx            (* CX=0:  timeout value          *)
Try_KBC:
  out     $0ED, ax         (* IO-Delay                      *)
  in      al,KBC_STAT      (* read 8042 status port         *)
  and     al,inpt_buf_full (* input buffer full flag (D1)   *)
  loopnz  Try_KBC          (* loop until input buffer empty
                              or timeout                    *)
  pop     cx               (* restore CX                    *)
end;

end.

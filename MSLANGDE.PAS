(*
   MEMSIZE - Find and size memory not found by the BIOS (German translation)
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
*)

const
  {Strings for the main program}
  str_NameAndVersion = 'Real-Mode-16MB-Tester v0.2';
  str_A20NotChanged = 'A20 wird nicht gesteuert.';
  str_A20Success = 'Gate A20 wurde angeschalten.';
  str_A20Error = 'Gate A20 konnte nicht gesteuert werden.';
  str_A20DisableError = 'A20 konnte nicht deaktiviert werden.';
  str_A20DisableSuccess = 'A20 wurde deaktiviert.';
  str_BlocksOver1MB = 'Speicherblîcke oberhalb 1MB: ';
  str_BlocksFound = 'Gefundene Speicherblîcke: ';
  str_SystemHalted = 'System angehalten.';
  str_PressKeyToExit = 'Zum beenden Taste drÅcken...';
  
  {Strings during Testing}
  str_Details = 'Details:';
  str_TableHeader = '    #  Bereich              Status   (Grî·e)';
  str_NA = 'N/A     ';
  str_Existent = 'Existent';
  str_ErrorLine1 = '=== Uuups, ich sollte nicht sichtbar sein - Falsche CPU !? ===';
  str_ErrorLine2 = '=== System angehalten !                                    ===';
  str_PressKeyToTest = 'Taste druecken zum Testen...';
  
  {Switches}
  str_SwitchNoA20 = '/NOA20';
  str_SwitchDisA20 = '/DISA20';
  str_Switch16M = '/16M';
  str_SwitchDump = '/DUMP';
  str_SwitchHalt = '/HALT';
  str_SwitchHelp = '/HELP';
  
  {Other stuff}
  str_Copy = '∏';

procedure PrintGreeting;
begin
  Writeln(str_NameAndVersion);
  Writeln('==========================');
end;

procedure PrintUsage;
begin
  Writeln(' Parameter:');
  writeln(' MEMSIZE [options]');
  writeln;
  writeln(' Optinos:');
  writeln('   /NoA20    : Die A20-Leitung nicht steuern');
  writeln('   /DisA20   : A20 aus- stat anschalten');
  writeln('   /16M      : Alle 16MiB testen, nicht erst ab 1MiB');
  writeln('   /Dump     : Parameter des LOADALL-Befehls ausgeben');
  writeln('   /Halt     : Nach Programmende System anhalten');
  writeln('   /?, /Help : Diese Info anzeigen');
  halt;
end;

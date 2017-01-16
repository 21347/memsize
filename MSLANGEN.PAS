(*
   MEMSIZE - Find and size memory not found by the BIOS (English translation)
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
  str_A20NotChanged = 'A20 line will not be changed.';
  str_A20Success = 'Gate A20 was changed successfully.';
  str_A20Error = 'Gate A20 could  not be changed.';
  str_A20DisableError = 'Gate A20 could not be deactivated.';
  str_A20DisableSuccess = 'Gate A20 was deactivated.';
  str_BlocksOver1MB = 'Available blocks above 1MB: ';
  str_BlocksFound = 'Available blocks: ';
  str_SystemHalted = 'System halted.';
  str_PressKeyToExit = 'Press any key to exit.';
  
  {Strings during Testing}
  str_Details = 'Details:';
  str_TableHeader = '    #  Range                Status   (Size) ';
  str_NA = 'N/A     ';
  str_Existent = 'Existent';
  str_ErrorLine1 = '=== Whoops, I should not be visible. Wrong CPU? ===';
  str_ErrorLine2 = '=== System halted !                             ===';
  str_PressKeyToTest = 'Pres any key to run the test...';
  
  {Switches}
  str_SwitchNoA20 = '/NOA20';
  str_SwitchDisA20 = '/DISA20';
  str_Switch16M = '/16M';
  str_SwitchDump = '/DUMP';
  str_SwitchHalt = '/HALT';
  str_SwitchHelp = '/HELP';
  
  {Other stuff}
  str_Copy = '(C)';

procedure PrintGreeting;
begin
  Writeln(str_NameAndVersion);
  Writeln('==========================');
end;

procedure PrintUsage;
begin
  Writeln(' Usage:');
  writeln(' MEMSIZE [options]');
  writeln;
  writeln(' Optinos:');
  writeln('   /NoA20    : Do not change A20');
  writeln('   /DisA20   : Switch A20 off instead of on');
  writeln('   /16M      : Test all 16MiB, not above 1MiB');
  writeln('   /Dump     : Print LOADALL parameters');
  writeln('   /Halt     : Halt system after execution');
  writeln('   /?, /Help : Show this little info');
  halt;
end;

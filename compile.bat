del c:\tmp\%1.hex
..\..\pasmo  --hex --output %1.hex  --verbose  --listing %1.lst %1.asm 
copy %1.hex c:\tmp\%1.hex

SECTIONS {
   .text   0  : { *(.text) }
   .rodata  : { *(.rodata) }
   .data 0x30000000 : AT(0x800)
   { 
      data_loadaddr = LOADADDR(.data);
      data_start = .;
      *(.data) 
      data_end = .;
   }
   .bss  : { *(.bss) *(.COMMON) }
}

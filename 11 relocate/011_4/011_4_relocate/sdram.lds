SECTIONS {
   .text   0  : { *(.text) }
   .rodata  : { *(.rodata) }
   .data 0x30000000 : AT(0x800)
   { 
      data_loadaddr = LOADADDR(.data);
      . = ALIGN(4);
      data_start = .;
      *(.data) 
      data_end = .;
   }
   . = ALIGN(4);
   bss_start = .;
   .bss  : { *(.bss) *(.COMMON) }
   bss_end = .;
}

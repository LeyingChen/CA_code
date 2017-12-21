****brief file description of myCPU****

   files                         description
|-myCPU /
|  |--soc_lite_top.v             ����ģ�飬�����mmuģ���ʵ����
|  |  |--mips_cpu.v              CPU����ģ��
|  |  |  |--reg_file.v           �Ĵ�����ģ��
|  |  |  |--nextpc_gen.v         nextPC����ģ��
|  |  |  |--fetch_stage.v        ȡָ��ģ��
|  |  |  |--decode_stage.v       ���뼶ģ��
|  |  |  |--execute_stage.v      ִ�м�ģ��
|  |  |  |  |--alu.v             aluģ��
|  |  |  |--memory_stage.v       �ô漶ģ��
|  |  |  |--writeback_stage.v    д�ؼ�ģ��
|  |  |  |--mult.v               �˷�ģ�飬����IP��
|  |  |  |--div.v                ����ģ��
|  |  |  |--HILO_reg.v           HI/LO�Ĵ���ģ��
|  |  |  |--awesome_CP0.v        CP0ģ�飬����status��cause��CP0�Ĵ����������index��entryhi��entrylo0��entrylo1��pagemask�Ĵ�����
|  |  |  |--mmu.v                MMUģ�飬����32��TLB���������ʵ��ַ��ת����
|  |--README                     myCPU�е��ļ�����

****brief file description of myCPU****

   files                      description
|-myCPU /
|  |--mips_cpu.v              rtl code of top module of CPU
|  |  |--reg_file.v           rtl code of registers file module
|  |  |--nextpc_gen.v         rtl code of PC-generating module
|  |  |--fetch_stage.v        rtl code of instruction-fetching(1st) stage
|  |  |--decode_stage.v       rtl code of instruction-decoding(2nd) stage
|  |  |--execute_stage.v      rtl code of executing(3rd) stage
|  |  |  |--alu.v             rtl code of Arithmetic Logical Unit
|  |  |--memory_stage.v       rtl code of the memory-accessing(4th) stage
|  |  |--writeback_stage.v    rtl code of the writing-back(5th) stage
|  |  |--mult.v               rtl code of multiplier using IP catalog
|  |  |--div.v                rtl code of divider using IP catalog
|  |  |--HILO_reg.v           rtl code of HI/LO registers
|  |--README                  file description & updating log

update log v3.3.4
58个测试通过
上板除法未通过
代码风格未修改
多余接口未删除

module nr_mcu(clk, enable, code_addr, code_din, emif_addr, emif_wr_n, emif_rd_n, emif_din, emif_dout);
   parameter        INTER_NUM = 32;
   parameter        INTER_NUM_2 = 5;
   input            clk;
   input            enable;
   output [15:0]    code_addr;
   input [39:0]     code_din;
   output [31:0]    emif_addr;
   reg [31:0]       emif_addr;
   output           emif_wr_n;
   reg              emif_wr_n;
   output           emif_rd_n;
   reg              emif_rd_n;
   output [31:0]    emif_din;
   reg [31:0]       emif_din;
   input [31:0]     emif_dout;
   
   
   localparam [7:0]  EMIF_RD_CODE = 8'h01;
   localparam [7:0]  EMIF_WR_CODE = 8'h02;
   
   localparam [7:0]  JUMP_GO_CODE = 8'h11;
   localparam [7:0]  JUMP_EQ_CODE = 8'h12;
   localparam [7:0]  JUMP_NQ_CODE = 8'h13;
   
   localparam [7:0]  INTER_RD_CODE = 8'h21;
   localparam [7:0]  INTER_WR_CODE = 8'h22;
   localparam [7:0]  SET_R0_CODE = 8'h23;
   
   localparam [7:0]  ADD_R0_CODE = 8'h31;
   localparam [7:0]  AND_R0_CODE = 8'h32;
   localparam [7:0]  OR_R0_CODE = 8'h33;
   localparam [7:0]  XOR_R0_CODE = 8'h34;
   localparam [7:0]  SHL_R0_CODE = 8'h35;
   localparam [7:0]  SHR_R0_CODE = 8'h36;
   localparam [7:0]  SHL4_R0_CODE = 8'h37;
   localparam [7:0]  SHR4_R0_CODE = 8'h38;
   
   localparam [7:0]  DELAY_CODE = 8'h41;
   
   localparam [7:0]  CALLON_CODE = 8'h51;
   localparam [7:0]  CALLBK_CODE = 8'h52;
   
   localparam [4:0]  c_idle = 0,
                    c_code = 1,
                    c_read = 2,
                    c_write = 3,
                    c_jump = 4,
                    c_jumpe = 5,
                    c_jumpn = 6,
                    c_callon = 7,
                    c_callbk = 8,
                    c_iread = 9,
                    c_iwrite = 10,
                    c_setR0 = 11,
                    c_addR0 = 12,
                    c_andR0 = 13,
                    c_orR0 = 14,
                    c_xorR0 = 15,
                    c_shl = 16,
                    c_shr = 17,
                    c_shl4 = 18,
                    c_shr4 = 19,
                    c_delay = 20,
                    c_opt1 = 21,
                    c_err = 22;

   reg [4:0]        c_state;
   reg [1:0]        code_cnt;
   reg [7:0]        code_opt;
   reg [31:0]       code_data;
   reg [31:0]       inter_reg[INTER_NUM-1:0];
   reg [31:0]       inter_R0;
   reg [3:0]        emif_read_cnt;
   reg [3:0]        emif_wr_cnt;
   reg [15:0]       code_addr_i;
   reg [15:0]       code_addr_bk1;
   reg [15:0]       code_addr_bk2;
   reg [15:0]       code_addr_bk3;
   reg [15:0]       code_addr_bk4;
   reg [31:0]       delay_cnt;
   
   
   always @(posedge clk)
      begin
         if (enable == 1'b0)
            c_state <= c_idle;
         else
            case (c_state)
               (c_idle) :
                  c_state <= c_code;
               (c_code) :
                  if (code_cnt == 2'b11)
                  begin
                     if (code_opt == EMIF_RD_CODE)
                        c_state <= c_read;
                     else if (code_opt == EMIF_WR_CODE)
                        c_state <= c_write;
                     else if (code_opt == JUMP_GO_CODE)
                        c_state <= c_jump;
                     else if (code_opt == JUMP_EQ_CODE)
                        c_state <= c_jumpe;
                     else if (code_opt == JUMP_NQ_CODE)
                        c_state <= c_jumpn;
                     else if (code_opt == CALLON_CODE)
                        c_state <= c_callon;
                     else if (code_opt == CALLBK_CODE)
                        c_state <= c_callbk;
                     else if (code_opt == INTER_RD_CODE)
                        c_state <= c_iread;
                     else if (code_opt == INTER_WR_CODE)
                        c_state <= c_iwrite;
                     else if (code_opt == SET_R0_CODE)
                        c_state <= c_setR0;
                     else if (code_opt == ADD_R0_CODE)
                        c_state <= c_addR0;
                     else if (code_opt == AND_R0_CODE)
                        c_state <= c_andR0;
                     else if (code_opt == OR_R0_CODE)
                        c_state <= c_orR0;
                     else if (code_opt == XOR_R0_CODE)
                        c_state <= c_xorR0;
                     else if (code_opt == SHL_R0_CODE)
                        c_state <= c_shl;
                     else if (code_opt == SHR_R0_CODE)
                        c_state <= c_shr;
                     else if (code_opt == SHL4_R0_CODE)
                        c_state <= c_shl4;
                     else if (code_opt == SHR4_R0_CODE)
                        c_state <= c_shr4;
                     else if (code_opt == DELAY_CODE)
                        c_state <= c_delay;
                     else
                        c_state <= c_err;
                  end
               (c_read) :
                  if (emif_read_cnt == 4'h9)
                     c_state <= c_opt1;
               (c_write) :
                  if (emif_wr_cnt == 4'h5)
                     c_state <= c_opt1;
               (c_jump) :
                  c_state <= c_idle;
               (c_jumpe) :
                  c_state <= c_idle;
               (c_jumpn) :
                  c_state <= c_idle;
               (c_callon) :
                  c_state <= c_idle;
               (c_callbk) :
                  c_state <= c_idle;
               (c_iread) :
                  c_state <= c_opt1;
               (c_iwrite) :
                  c_state <= c_opt1;
               (c_setR0) :
                  c_state <= c_opt1;
               (c_addR0) :
                  c_state <= c_opt1;
               (c_andR0) :
                  c_state <= c_opt1;
               (c_orR0) :
                  c_state <= c_opt1;
               (c_xorR0) :
                  c_state <= c_opt1;
               (c_shl) :
                  c_state <= c_opt1;
               (c_shr) :
                  c_state <= c_opt1;
               (c_shl4) :
                  c_state <= c_opt1;
               (c_shr4) :
                  c_state <= c_opt1;
               (c_delay) :
                  if (delay_cnt == code_data)
                     c_state <= c_opt1;
               
               (c_opt1) :
                  c_state <= c_idle;
               (c_err) :
                  c_state <= c_err;
               default :
                  c_state <= c_idle;
            endcase
      end
   
   
   always @(posedge clk)
      begin
         if (c_state == c_code)
            code_cnt <= code_cnt + 1'b1;
         else
            code_cnt <= {2{1'b0}};
         if (c_state == c_read)
            emif_read_cnt <= emif_read_cnt + 1'b1;
         else
            emif_read_cnt <= {4{1'b0}};
         if (c_state == c_write)
            emif_wr_cnt <= emif_wr_cnt + 1'b1;
         else
            emif_wr_cnt <= {4{1'b0}};
         if (c_state == c_delay)
            delay_cnt <= delay_cnt + 1'b1;
         else
            delay_cnt <= {32{1'b0}};
      end
   
   
   always @(posedge clk)
      begin
         if ((c_state == c_code) & (code_cnt == 2'b10))
         begin
            code_opt <= code_din[39:32];
            code_data <= code_din[31:0];
         end
      end
   
   
   always @(posedge clk)
      begin
         if (c_state == c_read)
         begin
            if (emif_read_cnt == 4'h0)
            begin
               emif_addr <= code_data;
               emif_wr_n <= 1'b1;
               emif_rd_n <= 1'b1;
               emif_din <= {32{1'b0}};
            end
            else if (emif_read_cnt == 4'h1)
               emif_rd_n <= 1'b0;
            else if (emif_read_cnt == 4'h9)
               emif_rd_n <= 1'b1;
         end
         else if (c_state == c_write)
         begin
            if (emif_wr_cnt == 4'h0)
            begin
               emif_addr <= code_data;
               emif_wr_n <= 1'b1;
               emif_rd_n <= 1'b1;
               emif_din <= inter_R0;
            end
            else if (emif_wr_cnt == 4'h4)
               emif_wr_n <= 1'b0;
            else if (emif_wr_cnt == 4'h5)
               emif_wr_n <= 1'b1;
         end
         else
         begin
            emif_addr <= {32{1'b0}};
            emif_wr_n <= 1'b1;
            emif_rd_n <= 1'b1;
            emif_din <= {32{1'b0}};
         end
      end
   
   
   always @(posedge clk)
      begin
         if ((c_state == c_read) & (emif_read_cnt == 4'h9))
            inter_R0 <= emif_dout;
         else if (c_state == c_iread)
            inter_R0 <= inter_reg[(code_data[INTER_NUM_2 - 1:0])];
         else if (c_state == c_setR0)
            inter_R0 <= code_data;
         else if (c_state == c_addR0)
            inter_R0 <= inter_reg[(code_data[INTER_NUM_2 - 1:0])] + inter_R0;
         else if (c_state == c_andR0)
            inter_R0 <= {32{inter_reg[(code_data[INTER_NUM_2 - 1:0])]}} & inter_R0;
         else if (c_state == c_orR0)
            inter_R0 <= {32{inter_reg[(code_data[INTER_NUM_2 - 1:0])]}} | inter_R0;
         else if (c_state == c_xorR0)
            inter_R0 <= {32{inter_reg[(code_data[INTER_NUM_2 - 1:0])]}} ^ inter_R0;
         else if (c_state == c_shl)
            inter_R0 <= {inter_R0[30:0], 1'b0};
         else if (c_state == c_shr)
            inter_R0 <= {1'b0, inter_R0[31:1]};
         else if (c_state == c_shl4)
            inter_R0 <= {inter_R0[27:0], 4'b0000};
         else if (c_state == c_shr4)
            inter_R0 <= {4'b0000, inter_R0[31:4]};
      end
   
   
   always @(posedge clk)
      begin
         if (c_state == c_iwrite)
            inter_reg[(code_data[INTER_NUM_2 - 1:0])] <= inter_R0;
      end
   
   
   always @(posedge clk)
      begin
         if (enable == 1'b0)
            code_addr_i <= {16{1'b0}};
         else if (c_state == c_opt1)
            code_addr_i <= code_addr_i + 1'b1;
         else if (c_state == c_jump)
            code_addr_i <= code_data[15:0];
         else if (c_state == c_jumpe)
         begin
            if (inter_R0 == 32'h00000000)
               code_addr_i <= code_data[15:0];
            else
               code_addr_i <= code_addr_i + 1'b1;
         end
         else if (c_state == c_jumpn)
         begin
            if (inter_R0 != 32'h00000000)
               code_addr_i <= code_data[15:0];
            else
               code_addr_i <= code_addr_i + 1'b1;
         end
         else if (c_state == c_callon)
         begin
            code_addr_i <= code_data[15:0];
            code_addr_bk1 <= code_addr_i + 1'b1;
            code_addr_bk2 <= code_addr_bk1;
            code_addr_bk3 <= code_addr_bk2;
            code_addr_bk4 <= code_addr_bk3;
         end
         else if (c_state == c_callbk)
         begin
            code_addr_i <= code_addr_bk1;
            code_addr_bk1 <= code_addr_bk2;
            code_addr_bk2 <= code_addr_bk3;
            code_addr_bk3 <= code_addr_bk4;
         end
      end
   
   assign code_addr = code_addr_i;
   
endmodule



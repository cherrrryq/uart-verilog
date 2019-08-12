`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: 
// Module Name: uart_tx
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart_tx(
        input        clk,
        input        rst,
        input [3:0]  baud,          //波特率选择
        input [3:0]  data_byte,     //发送信号
        input        en,            //时钟分频使能
        output reg   tx_well,      //串口信号输出
        output reg   rx_tx         

    );
    
reg          uart_state,       bps_clk;
reg  [15:0]  bps_cn, /*基数*/  div_cnt;/*分频*/
reg  [3:0]   bps_cnt;
reg  [7:0]   data_reg;
    
parameter start =0, stop=1;

always @(posedge clk or negedge rst)
begin
   if(rst)
        bps_cn <= 16'b0;    
else    begin
    case(baud)            //系统时钟50mhz计算
      0: bps_cn <= 31;    //bps_9600 
      1: bps_cn <= 2603;  //bps_19200
      2: bps_cn <= 1302;  //bps_38400
      3: bps_cn <= 433;   //bps_57600    
      4: bps_cn <= 18;    //bps_115200
      default:
         bps_cn <= 5207;  //bps_9600
      endcase   end    end

always @(posedge clk, negedge rst)
begin
  if(rst)
  begin
      bps_clk <= 1'b0;div_cnt <= 1'b0;
  end
  else if(uart_state)
  begin
      if(div_cnt == bps_cn) 
      begin
      bps_clk <= 1;div_cnt <= 0;
      end  else  begin
      bps_clk <= 0;div_cnt <= div_cnt + 1;
end  end  end 

always @(posedge clk or negedge rst) 
begin
  if(rst)
      bps_cnt <= 0;
  else if(tx_well)
      bps_cnt <= 0;
  else 
  begin
      if (bps_cnt == 11)
          bps_cnt <= 0;
      else if(bps_clk)
          bps_cnt <= bps_cnt + 1;
      else 
          bps_cnt <= bps_cnt;
end  end
  
always @(posedge clk or negedge rst)
begin   if(rst)
      rx_tx <= 0;
else   begin
    case(bps_cnt)
           0:rx_tx <= 1;
           1:rx_tx <= start;
           2:rx_tx <= data_reg[0];
           3:rx_tx <= data_reg[1];
           4:rx_tx <= data_reg[2];
           5:rx_tx <= data_reg[3];
           6:rx_tx <= data_reg[4];
           7:rx_tx <= data_reg[5];
           8:rx_tx <= data_reg[6];
           9:rx_tx <= data_reg[7];    
           10:rx_tx <= stop;
           default:rx_tx <= 1;
endcase  end  end

always @(posedge clk or negedge rst)
begin
   if(rst)   tx_well <= 0;
else if(bps_cnt == 14)
             tx_well <= 1;
else         tx_well <= 0;  end 

always @(posedge clk or negedge rst)
begin   if(rst)   uart_state <= 0;
else if(en)       uart_state <= 1;
       else if(tx_well)
                  uart_state <= 0;
else              uart_state <= uart_state;
end 
    
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: NingHeChuan
// 
// Create Date:    13:18:40 12/04/2016 
// Design Name: 
// Module Name:    uart_byte_rx 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module uart_byte_rx(
	 input mclk,//ϵͳʱ��50Mhz
	 input rst_n,
	 input [3:0] baud_set,
	 input rs232_rx,
	 
	 //output reg wr_en,
	//output reg [7:0] data_byte,
	 output reg uart_state,
	 //output	reg	[15:0]	ram_addr,
	 output	reg rx_done,
	 output reg [7:0] data_byte
	 //output	reg	[15:0]	dout
    );



reg [15:0] bps_DR;//�����ʲ���
reg [7:0] bps_cnt;//��Ƶ����,���ռ����Ƿ��ͼ�����16��
reg bps_clk;//��Ƶʱ��
reg [15:0] div_cnt;//��Ƶ����
reg s0_rs232_rx, s1_rs232_rx;//ͬ���Ĵ�������������̬
reg tmp0_rs232_rx, tmp1_rs232_rx;//���ݼĴ���
wire nedege;//�����ʼλ,�½��ؼ��
reg [2:0] r_data_byte [7:0];//��ʾ8��λ��Ϊ3�ļĴ���
reg [2:0] START_BIT, STOP_BIT;

//�����ʲ��ұ�
always @(posedge mclk or negedge rst_n) 
begin
	if(!rst_n)
		bps_DR <= 0;	
	else 
	begin
		case(baud_set)
		0: bps_DR <= 324;//bps_9600x16
		//0: bps_DR <= 1;//bps_9600x16 just for test
		1: bps_DR <= 162;//bps_19200x16
		2: bps_DR <= 80;//bps_38400x16
		3: bps_DR <= 53;//bps_57600x16
		4: bps_DR <= 26;//bps_115200x16
		default: bps_DR <= 324;//bps_9600x16
		endcase
	end
end	 

//��Ƶ������ʱ��
always @(posedge mclk or negedge rst_n)
begin
	if(!rst_n)
	begin
		bps_clk <= 0;
		div_cnt <= 0;
	end
	else if(uart_state)
	begin
		if(div_cnt == bps_DR) 
		begin
			bps_clk <= 1;
			div_cnt <= 0;
		end
		else 
		begin
			bps_clk <= 0;
			div_cnt <= div_cnt + 1;
		end
	end
end

//bps_cnt
always @(posedge mclk or negedge rst_n) 
begin
	if(!rst_n)
		bps_cnt <= 0;
	else if(rx_done || (bps_cnt == 12) && (START_BIT > 2))
		bps_cnt <= 0;
	else
	begin
		if (bps_cnt == 159)
			bps_cnt <= 0;
		else if(bps_clk)
			bps_cnt <= bps_cnt + 1;
		else 
			bps_cnt <= bps_cnt;
	end
end

//��ʼλ�����̣�������ͬ������,������������̬�ķ���
always @(posedge mclk or negedge rst_n) 
begin
	if(!rst_n) 
	begin
		s0_rs232_rx <= 0;
		s1_rs232_rx <= 0;
	end
	else 
	begin
		s0_rs232_rx <= rs232_rx;
		s1_rs232_rx <= s0_rs232_rx;
	end
end

//���ݼĴ���
always @(posedge mclk or negedge rst_n) 
begin
	if(!rst_n) 
	begin
		tmp0_rs232_rx <= 0;
		tmp1_rs232_rx <= 0;
	end
	else 
	begin
		tmp0_rs232_rx <= s1_rs232_rx;
		tmp1_rs232_rx <= tmp0_rs232_rx;
	end
end

assign nedege = !tmp0_rs232_rx & tmp1_rs232_rx;//�½��ؼ��

//�����ź�rx_done
always @(posedge mclk or negedge rst_n)
begin
	if(!rst_n)
		rx_done <= 0;
	else if(bps_cnt == 159)
		rx_done <= 1;
	else
		rx_done <= 0;
end

//���ݶ�ȡ
always @(posedge mclk or negedge rst_n)
begin
	if(!rst_n)
	begin
		START_BIT <= 0;//��ʼλ
		r_data_byte[0] <= 3'b0;
		r_data_byte[1] <= 3'b0;
		r_data_byte[2] <= 3'b0;
		r_data_byte[3] <= 3'b0;
		r_data_byte[4] <= 3'b0;
		r_data_byte[5] <= 3'b0;
		r_data_byte[6] <= 3'b0;
		r_data_byte[7] <= 3'b0;
		STOP_BIT <= 0;//����λ
	end
	else if(bps_clk)
	begin
		case(bps_cnt)
		0:begin
			START_BIT <= 0;//��ʼλ
			r_data_byte[0] <= 3'b0;
			r_data_byte[1] <= 3'b0;
			r_data_byte[2] <= 3'b0;
			r_data_byte[3] <= 3'b0;
			r_data_byte[4] <= 3'b0;
			r_data_byte[5] <= 3'b0;
			r_data_byte[6] <= 3'b0;	
			r_data_byte[7] <= 3'b0;
			STOP_BIT <= 0;//����λ
		end
		5,6,7,8,9,10:START_BIT <= START_BIT + s1_rs232_rx;
		21,22,23,24,25,26:r_data_byte[0] <= r_data_byte[0] + s1_rs232_rx;
		37,38,39,40,41,42:r_data_byte[1] <= r_data_byte[1] + s1_rs232_rx;
		53,54,55,56,57,58:r_data_byte[2] <= r_data_byte[2] + s1_rs232_rx;
		69,70,71,72,73,74:r_data_byte[3] <= r_data_byte[3] + s1_rs232_rx;
		85,86,87,88,89,90:r_data_byte[4] <= r_data_byte[4] + s1_rs232_rx;
		101,102,103,104,105,106:r_data_byte[5] <= r_data_byte[5] + s1_rs232_rx;
		117,118,119,120,121,122:r_data_byte[6] <= r_data_byte[6] + s1_rs232_rx;
		133,134,135,136,137,138:r_data_byte[7] <= r_data_byte[7] + s1_rs232_rx;
		149,150,151,152,153,154:STOP_BIT <= STOP_BIT + s1_rs232_rx;
		default:;
		endcase
	end
end

//�������
always @(posedge mclk or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_byte <= 8'b0;
	end
	else if(bps_cnt == 159)
	begin
		data_byte[0] <= r_data_byte[0][2];
		data_byte[1] <= r_data_byte[1][2];
		data_byte[2] <= r_data_byte[2][2];
		data_byte[3] <= r_data_byte[3][2];
		data_byte[4] <= r_data_byte[4][2];
		data_byte[5] <= r_data_byte[5][2];
		data_byte[6] <= r_data_byte[6][2];
		data_byte[7] <= r_data_byte[7][2];
	end
end

//UART_stateΪ1����ʾæ��0����
always @(posedge mclk or negedge rst_n)
begin
	if(!rst_n)
		uart_state <= 1'b0;	
	else if(rx_done)
		uart_state <= 1'b0;	
	else if(nedege)
		uart_state <= 1'b1;
	else 
		uart_state <= uart_state;
end
/* 
//-----------------------------------------------
always @(posedge mclk or negedge rst_n)begin	
	if(!rst_n)
		wr_en <= 1'b0;
	else if(rx_done)
		wr_en <= ~wr_en;
	else 
		wr_en <= wr_en;
	
	end

//--------------------------------------------
reg 	[7:0]	data_byte_r0;
always @(posedge mclk)
	data_byte_r0 <= data_byte;
		
		
reg 	[15:0]	dout_r;
reg 	[7:0]	data_byte_r;
always @(posedge mclk or negedge rst_n)begin	
	if(!rst_n)begin
		data_byte_r <= 'd0;
		dout_r <= 'd0;
	end
	else if(rx_done == 1'b1)begin
		data_byte_r <= data_byte_r0;
		dout_r <= {data_byte_r, data_byte_r0};//MSB -> LSB
	end
	else begin
		data_byte_r <= data_byte_r;
		dout_r <= dout_r;
	end
end

always @(posedge mclk or negedge rst_n)begin	
	if(!rst_n)
		dout <= 'd0;
	else if(wr_en == 1'b1)
		dout <= dout_r;
	else 
		dout <= dout;
end

//----------------------------------------------
	
wire 	posdge;
reg 	wr_en1, wr_en2;
always @(posedge mclk or negedge rst_n) 
begin
	if(!rst_n) 
	begin
		wr_en1 <= 0;
		wr_en2 <= 0;
	end
	else 
	begin
		wr_en1 <= wr_en;
		wr_en2 <= wr_en1;
	end
end

assign posdge = wr_en1 & !wr_en2;//�����ؼ��	
	 */

/* //-------------------------------------------------------
//ram_addr
reg	[15:0]	ram_addr_r;
always @(posedge mclk or negedge rst_n)begin	
	if(!rst_n)
		ram_addr_r <= 'd0;
	else if(rx_done == 1'b1)
		ram_addr_r <= ram_addr_r + 1'b1;
	else
		ram_addr_r <= ram_addr_r;
end

always @(*)
	ram_addr = ram_addr_r; */
	
endmodule 
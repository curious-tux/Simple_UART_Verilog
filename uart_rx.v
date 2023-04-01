`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/01/2023 02:59:21 PM
// Design Name: 
// Module Name: uart_rx
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


module uart_rx#(
    CLK_FREQ = 125000000,
    BAUD_RATE = 115200
)(
    input clk,
    input reset,
    output [7:0] uart_rx_reg,
    input rx,
    output reg uart_rx_data_available
    );
    
    localparam CLK_DIV = (CLK_FREQ/BAUD_RATE/2)-1; /*Formula for clock division*/ 
    reg [$clog2(CLK_DIV):0] counter;
	/*
	     _______        ---------
		|       |      |         |
	____|       |______|         |______
		    _              _
	       | |            | |
	_______| |____________|	|___________ -> In Rx we sample the data at midpoint of Baud clock (wait untill counter reaches midpoint)

         _             _
		| |           | |
	____| |___________| |_______ -> In TX we place the data at posedge of baud clock
	*/
    
    localparam IDLE = 0;
    localparam START = 1;
    localparam RX = 2;
    localparam STOP = 3;
    
    reg [3:0] BITS;
    
    reg [2:0] STATE;
    
	reg [7:0] shift_reg;
/*
	We have to copy the rx first to shift reg and then to uart_rx_reg to avoid Uncertain state (called as double flopping)
 */

    initial begin /*Just for simulation*/
            counter <= 0;
            uart_rx_data_available <= 0;
            STATE <= IDLE;
            BITS <= 0;
            shift_reg <= 0;
        end
    
           
    always@(posedge clk)
    begin
        if(reset)
        begin
            STATE <= IDLE;
            uart_rx_data_available <= 0;
            counter <= 0;
        end
        else
        begin
            case(STATE)
                
                IDLE:
                begin
                      counter <= 0;
                      uart_rx_data_available <= 0;
                      if(!rx) /*Start condition*/
                        STATE <= START;  
                end
                
                START:
                begin
                    BITS <= 0;
                    shift_reg <= 0;
                    if(counter == (CLK_DIV/2)-1) /*mid point also one clock less because we were in IDLE state for one clock*/
                    begin
                        if(!rx)
                        begin
                            STATE <= RX;
                            counter <= 0;
                        end
                        else
                            STATE <= IDLE; /*False Start*/
                    end
                    else
                        counter <= counter + 1;
                end
                
                RX:
                    if(counter == CLK_DIV/2)
                    begin
                        counter <= 0;
                        shift_reg[BITS] <= rx; /*Sample the data*/
                        BITS <= BITS + 1;
                        if(BITS > 7)
                        begin
                            STATE <= STOP;
                            counter <= 0;
                        end
                    end
                    else
                        counter <= counter + 1;              
                STOP:
                begin
                    if(counter == CLK_DIV/2)
                    begin
                        if(rx)
                        begin
                            uart_rx_data_available <= 1;
						   /* 
							* this signal will be high only for one clock signal and hence can be easily missed	
							* So we can add one more state say DUMMY and wait
						    * in that state for some clock signal just to ensure
						    * signal is detected by other modules
						    */
                            STATE <= IDLE;
                            counter <= 0;
                        end
                    end
                    else
                        counter <= counter + 1;
                end
                
                
            endcase  
        end
    end
assign uart_rx_reg = shift_reg;
endmodule


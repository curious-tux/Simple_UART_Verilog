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


module uart_tx#(
    CLK_FREQ = 125000000,
    BAUD_RATE = 115200
)(
    input clk,
    input reset,
    input [7:0] uart_tx_reg,
    input data_valid,
    output reg tx,
    output reg uart_tx_done
    );
    
    localparam CLK_DIV = (CLK_FREQ/BAUD_RATE/2)-1;
    reg baud_clk;
    reg [$clog2(CLK_DIV):0] counter;
    
    localparam IDLE = 0;
    localparam START = 1;
    localparam TX = 2;
    localparam STOP = 3;
    
    reg [7:0] shift_reg;
    
    reg [2:0] STATE;
    reg [2:0] BITS;
    initial begin
        counter <= 0;
        uart_tx_done <= 0;
        baud_clk <= 0;
        STATE <= IDLE;
        tx <= 1;
        shift_reg <= 0;
        BITS <= 0;
    end
    
    always@(posedge clk)
    begin
        if(counter == CLK_DIV)
            counter <= 0;
        else
            counter <= counter + 1;   
    end    
    
    always@(posedge clk)
    begin
        if(counter == CLK_DIV)
            baud_clk <= !baud_clk;
    end
    
    always@(posedge baud_clk)
    begin
        if(reset)
            STATE <= IDLE;
        else
        begin
            case(STATE)
                IDLE:
                begin
                    if(data_valid)
                    begin
                        STATE <= START;
                        shift_reg <= uart_tx_reg;
                    end
                end
                
                START:
                begin
                        tx <= 0;
                        STATE <= TX;
                        BITS <= 0; 
                end
                
                TX:
                begin
                    if(BITS != 7)
                    begin
                        BITS <= BITS + 1;
                        tx <= shift_reg[0];
                        shift_reg = {1'b0,shift_reg[7:1]};
                    end
                    else
                        STATE <= STOP;
                end
                
                STOP:
                begin
                    tx <= 1;
                    uart_tx_done <= 1;
                    if(!data_valid)
                    begin
                        STATE <= IDLE;
                        uart_tx_done <= 0;
                    end
                end
                
            endcase
        end
    end
endmodule


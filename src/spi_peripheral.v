`default_nettype none

module spi_peripheral (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       mosi,
    input  wire       ncs,
    input  wire       sclk,
    output reg  [7:0] en_reg_out_7_0,
    output reg  [7:0] en_reg_out_15_8,
    output reg  [7:0] en_reg_pwm_7_0,
    output reg  [7:0] en_reg_pwm_15_8,
    output reg  [7:0] pwm_duty_cycle
);

    reg mosi_sync1, mosi_sync2;
    reg ncs_sync1,  ncs_sync2,  ncs_sync3;
    reg sclk_sync1, sclk_sync2, sclk_sync3;

    wire sclk_rising =  sclk_sync2 && !sclk_sync3;
    wire ncs_rising  =  ncs_sync2  && !ncs_sync3;
    wire ncs_falling = !ncs_sync2  &&  ncs_sync3;

    reg [15:0] shift_reg;
    reg [4:0]  bit_count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mosi_sync1 <= 1'b0;
            mosi_sync2 <= 1'b0;
            ncs_sync1  <= 1'b1;
            ncs_sync2  <= 1'b1;
            ncs_sync3  <= 1'b1;
            sclk_sync1 <= 1'b0;
            sclk_sync2 <= 1'b0;
            sclk_sync3 <= 1'b0;
        end else begin
            mosi_sync1 <= mosi;
            mosi_sync2 <= mosi_sync1;
            ncs_sync1  <= ncs;
            ncs_sync2  <= ncs_sync1;
            ncs_sync3  <= ncs_sync2;
            sclk_sync1 <= sclk;
            sclk_sync2 <= sclk_sync1;
            sclk_sync3 <= sclk_sync2;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 16'b0;
            bit_count <= 5'b0;

            en_reg_out_7_0  <= 8'h00;
            en_reg_out_15_8 <= 8'h00;
            en_reg_pwm_7_0  <= 8'h00;
            en_reg_pwm_15_8 <= 8'h00;
            pwm_duty_cycle  <= 8'h00;
        end else begin
            if (ncs_falling) begin
                shift_reg <= 16'b0;
                bit_count <= 5'b0;
            end else if (!ncs_sync2 && sclk_rising && bit_count < 5'd16) begin
                shift_reg <= {shift_reg[14:0], mosi_sync2};
                bit_count <= bit_count + 5'd1;
            end else if (ncs_rising && bit_count == 5'd16) begin
                if (shift_reg[15]) begin
                    case (shift_reg[14:8])
                        7'h00: en_reg_out_7_0  <= shift_reg[7:0];
                        7'h01: en_reg_out_15_8 <= shift_reg[7:0];
                        7'h02: en_reg_pwm_7_0  <= shift_reg[7:0];
                        7'h03: en_reg_pwm_15_8 <= shift_reg[7:0];
                        7'h04: pwm_duty_cycle  <= shift_reg[7:0];
                        default: begin end
                    endcase
                end
            end
        end
    end

endmodule
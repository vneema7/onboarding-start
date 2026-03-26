`default_nettype none

module spi_peripheral (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       sclk,
    input  wire       mosi,
    input  wire       ncs,

    output reg [7:0] en_reg_out_7_0,
    output reg [7:0] en_reg_out_15_8,
    output reg [7:0] en_reg_pwm_7_0,
    output reg [7:0] en_reg_pwm_15_8,
    output reg [7:0] pwm_duty_cycle
);

    reg sclk_ff1, sclk_ff2;
    reg ncs_ff1, ncs_ff2;
    reg mosi_ff1, mosi_ff2;

    reg [15:0] shift_reg;
    reg [4:0] bit_count;

    wire sclk_rising;
    wire ncs_falling;

    assign sclk_rising = (sclk_ff2 == 1'b0) && (sclk_ff1 == 1'b1);
    assign ncs_falling = (ncs_ff2 == 1'b1) && (ncs_ff1 == 1'b0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk_ff1 <= 1'b0;
            sclk_ff2 <= 1'b0;
            ncs_ff1  <= 1'b1;
            ncs_ff2  <= 1'b1;
            mosi_ff1 <= 1'b0;
            mosi_ff2 <= 1'b0;

            shift_reg <= 16'h0000;
            bit_count <= 5'd0;

            en_reg_out_7_0  <= 8'h00;
            en_reg_out_15_8 <= 8'h00;
            en_reg_pwm_7_0  <= 8'h00;
            en_reg_pwm_15_8 <= 8'h00;
            pwm_duty_cycle  <= 8'h00;
        end else begin
            sclk_ff2 <= sclk_ff1;
            sclk_ff1 <= sclk;

            ncs_ff2 <= ncs_ff1;
            ncs_ff1 <= ncs;

            mosi_ff2 <= mosi_ff1;
            mosi_ff1 <= mosi;

            if (ncs_falling) begin
                shift_reg <= 16'h0000;
                bit_count <= 5'd0;
            end else if (!ncs_ff1 && sclk_rising) begin
                if (bit_count == 5'd15) begin
                    if (shift_reg[14] == 1'b1) begin
                        case (shift_reg[13:7])
                            7'h00: en_reg_out_7_0  <= {shift_reg[6:0], mosi_ff2};
                            7'h01: en_reg_out_15_8 <= {shift_reg[6:0], mosi_ff2};
                            7'h02: en_reg_pwm_7_0  <= {shift_reg[6:0], mosi_ff2};
                            7'h03: en_reg_pwm_15_8 <= {shift_reg[6:0], mosi_ff2};
                            7'h04: pwm_duty_cycle  <= {shift_reg[6:0], mosi_ff2};
                            default: begin
                            end
                        endcase
                    end

                    shift_reg <= 16'h0000;
                    bit_count <= 5'd0;
                end else begin
                    shift_reg <= {shift_reg[14:0], mosi_ff2};
                    bit_count <= bit_count + 5'd1;
                end
            end
        end
    end

endmodule
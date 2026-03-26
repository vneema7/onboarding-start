`default_nettype none

module spi_peripheral (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       sclk,
    input  wire       mosi,
    input  wire       ncs,

    output reg  [7:0] en_reg_out_7_0,
    output reg  [7:0] en_reg_out_15_8,
    output reg  [7:0] en_reg_pwm_7_0,
    output reg  [7:0] en_reg_pwm_15_8,
    output reg  [7:0] pwm_duty_cycle
);

    reg [15:0] shift_reg;
    reg [4:0]  bit_count;

    wire [15:0] next_shift;
    assign next_shift = {shift_reg[14:0], mosi};

    always @(posedge sclk or posedge ncs or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg       <= 16'h0000;
            bit_count       <= 5'd0;
            en_reg_out_7_0  <= 8'h00;
            en_reg_out_15_8 <= 8'h00;
            en_reg_pwm_7_0  <= 8'h00;
            en_reg_pwm_15_8 <= 8'h00;
            pwm_duty_cycle  <= 8'h00;
        end else if (ncs) begin
            shift_reg <= 16'h0000;
            bit_count <= 5'd0;
        end else begin
            shift_reg <= next_shift;

            if (bit_count == 5'd15) begin
                if (next_shift[15]) begin
                    case (next_shift[14:8])
                        7'h00: en_reg_out_7_0  <= next_shift[7:0];
                        7'h01: en_reg_out_15_8 <= next_shift[7:0];
                        7'h02: en_reg_pwm_7_0  <= next_shift[7:0];
                        7'h03: en_reg_pwm_15_8 <= next_shift[7:0];
                        7'h04: pwm_duty_cycle  <= next_shift[7:0];
                        default: begin end
                    endcase
                end
                bit_count <= 5'd0;
            end else begin
                bit_count <= bit_count + 5'd1;
            end
        end
    end

    wire _unused = clk;

endmodule
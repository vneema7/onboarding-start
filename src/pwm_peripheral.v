/*
 * Copyright (c) 2024 Damir Gazizullin
 * SPDX-License-Identifier: Apache-2.0
 */

/*
 * Copyright (c) 2024 Damir Gazizullin
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module pwm_peripheral (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] en_reg_out_7_0,
    input  wire [7:0] en_reg_out_15_8,
    input  wire [7:0] en_reg_pwm_7_0,
    input  wire [7:0] en_reg_pwm_15_8,
    input  wire [7:0] pwm_duty_cycle,
    output wire [15:0] out
);

    // 10 MHz / (13 * 256) = 3004.8 Hz
    localparam [3:0] CLK_DIV_TRIG = 4'd12;

    reg [3:0] clk_counter;
    reg [7:0] pwm_counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_counter <= 4'd0;
            pwm_counter <= 8'd0;
        end else begin
            if (clk_counter == CLK_DIV_TRIG) begin
                clk_counter <= 4'd0;
                pwm_counter <= pwm_counter + 8'd1;
            end else begin
                clk_counter <= clk_counter + 4'd1;
            end
        end
    end

    wire pwm_signal;
    assign pwm_signal = (pwm_duty_cycle == 8'hFF) ? 1'b1 : (pwm_counter < pwm_duty_cycle);

    assign out[0]  = en_reg_out_7_0[0]  ? (en_reg_pwm_7_0[0]  ? pwm_signal : 1'b1) : 1'b0;
    assign out[1]  = en_reg_out_7_0[1]  ? (en_reg_pwm_7_0[1]  ? pwm_signal : 1'b1) : 1'b0;
    assign out[2]  = en_reg_out_7_0[2]  ? (en_reg_pwm_7_0[2]  ? pwm_signal : 1'b1) : 1'b0;
    assign out[3]  = en_reg_out_7_0[3]  ? (en_reg_pwm_7_0[3]  ? pwm_signal : 1'b1) : 1'b0;
    assign out[4]  = en_reg_out_7_0[4]  ? (en_reg_pwm_7_0[4]  ? pwm_signal : 1'b1) : 1'b0;
    assign out[5]  = en_reg_out_7_0[5]  ? (en_reg_pwm_7_0[5]  ? pwm_signal : 1'b1) : 1'b0;
    assign out[6]  = en_reg_out_7_0[6]  ? (en_reg_pwm_7_0[6]  ? pwm_signal : 1'b1) : 1'b0;
    assign out[7]  = en_reg_out_7_0[7]  ? (en_reg_pwm_7_0[7]  ? pwm_signal : 1'b1) : 1'b0;

    assign out[8]  = en_reg_out_15_8[0] ? (en_reg_pwm_15_8[0] ? pwm_signal : 1'b1) : 1'b0;
    assign out[9]  = en_reg_out_15_8[1] ? (en_reg_pwm_15_8[1] ? pwm_signal : 1'b1) : 1'b0;
    assign out[10] = en_reg_out_15_8[2] ? (en_reg_pwm_15_8[2] ? pwm_signal : 1'b1) : 1'b0;
    assign out[11] = en_reg_out_15_8[3] ? (en_reg_pwm_15_8[3] ? pwm_signal : 1'b1) : 1'b0;
    assign out[12] = en_reg_out_15_8[4] ? (en_reg_pwm_15_8[4] ? pwm_signal : 1'b1) : 1'b0;
    assign out[13] = en_reg_out_15_8[5] ? (en_reg_pwm_15_8[5] ? pwm_signal : 1'b1) : 1'b0;
    assign out[14] = en_reg_out_15_8[6] ? (en_reg_pwm_15_8[6] ? pwm_signal : 1'b1) : 1'b0;
    assign out[15] = en_reg_out_15_8[7] ? (en_reg_pwm_15_8[7] ? pwm_signal : 1'b1) : 1'b0;

endmodule
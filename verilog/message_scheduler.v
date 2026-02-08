module message_schedule (
    input wire clk,
    input wire reset,
    input wire input_valid,
    input wire [511:0] block_in,
    output reg [31:0] W0_out,
    output reg [31:0] W1_out,
    output reg valid_out
);
    reg [5:0] t;
    reg [31:0] W [0:15];
    localparam IDLE = 1'b0;
    localparam PROCESS = 1'b1;
    reg state;

    function [31:0] ROTR;
        input [31:0] x;
        input [4:0] n;
        ROTR = (x >> n) | (x << (32 - n));
    endfunction

    function [31:0] SHR;
        input [31:0] x;
        input [4:0] n;
        SHR = x >> n;
    endfunction

    function [31:0] sigma0;
        input [31:0] x;
        sigma0 = ROTR(x, 7) ^ ROTR(x, 18) ^ SHR(x, 3);
    endfunction

    function [31:0] sigma1;
        input [31:0] x;
        sigma1 = ROTR(x, 17) ^ ROTR(x, 19) ^ SHR(x, 10);
    endfunction

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            t <= 0;
            W0_out <= 32'b0;
            W1_out <= 32'b0;
            valid_out <= 0;
            state <= IDLE;

            W[0] <= 32'b0;
            W[1] <= 32'b0;
            W[2] <= 32'b0;
            W[3] <= 32'b0;
            W[4] <= 32'b0;
            W[5] <= 32'b0;
            W[6] <= 32'b0;
            W[7] <= 32'b0;
            W[8] <= 32'b0;
            W[9] <= 32'b0;
            W[10] <= 32'b0;
            W[11] <= 32'b0;
            W[12] <= 32'b0;
            W[13] <= 32'b0;
            W[14] <= 32'b0;
            W[15] <= 32'b0;
        end else begin
            case (state)
                IDLE: begin
                    t <= 0;
                    valid_out <= 0;

                    if (input_valid) begin
                        W[0]  <= block_in[511:480];
                        W[1]  <= block_in[479:448];
                        W[2]  <= block_in[447:416];
                        W[3]  <= block_in[415:384];
                        W[4]  <= block_in[383:352];
                        W[5]  <= block_in[351:320];
                        W[6]  <= block_in[319:288];
                        W[7]  <= block_in[287:256];
                        W[8]  <= block_in[255:224];
                        W[9]  <= block_in[223:192];
                        W[10] <= block_in[191:160];
                        W[11] <= block_in[159:128];
                        W[12] <= block_in[127:96];
                        W[13] <= block_in[95:64];
                        W[14] <= block_in[63:32];
                        W[15] <= block_in[31:0];
								
						W0_out  <= block_in[511:480];
                        W1_out  <= block_in[479:448];
						valid_out <= 1;
								
								
                        state <= PROCESS;
                    end
                end

                PROCESS: begin
                        if (t < 31) begin
                            W0_out <= W[((2*t)+2) % 16];
                            W1_out <= W[((2*t)+3) % 16];
                            valid_out <= 1;

                            if (t < 24) begin
                                W[(2*t + 16) % 16] <= sigma1(W[(2*t + 14) % 16]) + W[(2*t + 9) % 16] +
                                                      sigma0(W[(2*t + 1) % 16]) + W[(2*t) % 16];

                                W[(2*t + 17) % 16] <= sigma1(W[(2*t + 15) % 16]) + W[(2*t + 10) % 16] +
                                                      sigma0(W[(2*t + 2) % 16]) + W[(2*t + 1) % 16];
                            end

                            t <= t + 1;
                        end else begin
                            valid_out <= 0;
                            state <= IDLE;
                        end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule


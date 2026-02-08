module sha256_top (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        start_block,
    input  wire [511:0] block_in,
	 input  wire block_valid,

    output reg         busy,
    output wire [255:0] hash_out,
	 output wire         comp_done,
	 output reg [5:0] count
);

    localparam IDLE = 1'b0;
    localparam PROCESSING = 1'b1;

    reg state, next_state;

    wire [31:0] ms_W0_out;
    wire [31:0] ms_W1_out;
    wire        ms_valid_out;

    wire [5:0]  comp_t;
    wire [31:0] k_K0_out;
    wire [31:0] k_K1_out;

    wire [31:0] comp_H_out_0, comp_H_out_1, comp_H_out_2, comp_H_out_3;
    wire [31:0] comp_H_out_4, comp_H_out_5, comp_H_out_6, comp_H_out_7;

    assign hash_out = {comp_H_out_0, comp_H_out_1, comp_H_out_2, comp_H_out_3,
                       comp_H_out_4, comp_H_out_5, comp_H_out_6, comp_H_out_7};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            busy <= 1'b0;
            count <= 6'b0;
        end else begin
            state <= next_state;
			count <= count + 1;

            if (next_state == PROCESSING && state == IDLE) begin
                busy <= 1'b1;
            end else if (next_state == IDLE && state == PROCESSING) begin
                busy <= 1'b0;
            end
        end
    end

    always @* begin
        next_state = state;

        case (state)
            IDLE: begin
                if (start_block) begin
                    next_state = PROCESSING;
                end
            end

            PROCESSING: begin
                if (comp_done) begin
                    next_state = IDLE;
                end
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

    message_schedule ms_inst (
        .clk         (clk),
        .reset       (!rst_n),
        .block_in  (block_in),
        .input_valid (block_valid),
        .W0_out      (ms_W0_out),
        .W1_out      (ms_W1_out),
        .valid_out   (ms_valid_out)
    );

    sha256_k_constants k_const_inst (
        .t           (comp_t),
        .K0_out      (k_K0_out),
        .K1_out      (k_K1_out)
    );

    sha256_compression comp_inst (
        .clk         (clk),
        .rst_n       (rst_n),
        .start       (start_block),
        .valid_in    (ms_valid_out),
        .W0_in       (ms_W0_out),
        .W1_in       (ms_W1_out),
        .K0_in       (k_K0_out),
        .K1_in       (k_K1_out),
        .H_out_0     (comp_H_out_0),
        .H_out_1     (comp_H_out_1),
        .H_out_2     (comp_H_out_2),
        .H_out_3     (comp_H_out_3),
        .H_out_4     (comp_H_out_4),
        .H_out_5     (comp_H_out_5),
        .H_out_6     (comp_H_out_6),
        .H_out_7     (comp_H_out_7),
        .comp_done   (comp_done),
        .t           (comp_t)
    );

endmodule

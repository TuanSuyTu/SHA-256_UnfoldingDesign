module top_wrapper (
    input wire clk,
    input wire rst_n,  
	 output wire comp_done_out,
    output wire [255:0] done_out    
);

    reg         start_block_internal;
    reg  [511:0] block_in_internal;
    reg         block_valid_internal;
	 wire [5:0] count;
    wire        busy_internal;
    wire [255:0] hash_out_internal;
    wire        hash_valid_internal;
    wire        comp_done_internal;

    reg started_flag;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            started_flag         <= 1'b0;
            start_block_internal <= 1'b0;
            block_valid_internal <= 1'b0;
            block_in_internal    <= 512'b0;
        end else begin
            if (!started_flag) begin
                start_block_internal <= 1'b1;
                block_valid_internal <= 1'b1;
                started_flag         <= 1'b1;
            end else begin
                start_block_internal <= 1'b0;
                block_valid_internal <= 1'b0;
                block_in_internal    <= 512'b0;
            end
        end
    end

    sha256_top uut (
        .clk         (clk),
        .rst_n       (rst_n),
        .start_block (start_block_internal),
        .block_in    (block_in_internal),
        .block_valid (block_valid_internal),
        .busy        (busy_internal),
        .hash_out    (hash_out_internal),
        .comp_done   (comp_done_internal),
		.count       (count)
    );

    assign done_out = hash_out_internal;
	assign comp_done_out = comp_done_internal;

endmodule
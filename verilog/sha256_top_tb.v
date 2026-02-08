`timescale 1ns / 1ps

module sha256_top_tb;

    localparam CLK_PERIOD = 10;
    
    reg clk;
    reg rst_n;
    reg start_block;
    reg [511:0] block_in;
    reg tb_block_valid;

    wire busy;
    wire [255:0] hash_out;
    wire tb_comp_done;
    wire [5:0] tb_count;

    reg [511:0] test_block_512;
    reg [255:0] expected_hash;
    integer errors;

    sha256_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .start_block(start_block),
        .block_in(block_in),
        .block_valid(tb_block_valid),
        .busy(busy),
        .hash_out(hash_out),
        .comp_done(tb_comp_done),
        .count(tb_count)
    );

    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end



    task reset;
    begin
        rst_n = 1'b0;
        start_block = 1'b0;
        block_in = 512'b0;
        tb_block_valid = 1'b0;
        # (CLK_PERIOD);          
        rst_n = 1'b1;
        # (CLK_PERIOD);
    end
    endtask



    task load_block;
        input [511:0] block;
        input [255:0] expected_hash;
        input       is_final_block;
    begin
        @(posedge clk);
        block_in = block;

        start_block = 1'b1;
        @(posedge clk);

        start_block = 1'b0;
        tb_block_valid = 1'b1;
        @(posedge clk);

        tb_block_valid = 1'b0;

        while (!tb_comp_done) begin
            @(posedge clk);
        end

        if (is_final_block) begin
            if (hash_out != expected_hash) begin
                errors = errors + 1;
            end
        end
        @(posedge clk); 
    end
    endtask

    initial begin
        errors = 0;

        // --- Test Case 1: "abc" (Single Block) ---
        reset();
        
        test_block_512 = {
            64'h6162638000000000, 
            64'h0000000000000000,
            64'h0000000000000000,
            64'h0000000000000000,
            64'h0000000000000000,
            64'h0000000000000000,
            64'h0000000000000000,
            64'h0000000000000018
        };
        expected_hash = 256'hba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad;
        load_block(test_block_512, expected_hash, 1'b1);

        // --- Test Case 2: "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXZ" (Two Blocks) ---
        reset();
        expected_hash = 256'h15f42e418f2cea4c05300d1c705ad8589bc5d90e28787855d07981c54eeb19fe;

        test_block_512 = {
            64'h6162636465666768, 
            64'h696a6b6c6d6e6f70, 
            64'h7172737475767778, 
            64'h797a303132333435, 
            64'h3637383941424344, 
            64'h45464748494a4b4c, 
            64'h4d4e4f5051525354, 
            64'h555657585a800000
        };
        load_block(test_block_512, expected_hash, 1'b0); 

        test_block_512 = {
            64'h0000000000000000,
            64'h0000000000000000,
            64'h0000000000000000,
            64'h0000000000000000,
            64'h0000000000000000,
            64'h0000000000000000,
            64'h0000000000000000,
            64'h00000000000001e8
        };
        load_block(test_block_512, expected_hash, 1'b1); 

        // --- Test Case 3: "aaaaaaaa..." (256 'a' , 5 Blocks) ---
        reset();

        expected_hash = 256'h02d7160d77e18c6447be80c2e355c7ed4388545271702c50253b0914c65ce5fe;

        test_block_512 = {
            64'h6161616161616161, 
            64'h6161616161616161, 
            64'h6161616161616161, 
            64'h6161616161616161, 
            64'h6161616161616161, 
            64'h6161616161616161, 
            64'h6161616161616161, 
            64'h6161616161616161
        };
        load_block(test_block_512, expected_hash, 1'b0); 

        test_block_512 = {
            64'h6161616161616161, 
            64'h6161616161616161, 
            64'h6161616161616161, 
            64'h6161616161616161, 
            64'h6161616161616161, 
            64'h6161616161616161, 
            64'h6161616161616161, 
            64'h6161616161616161
        };
        load_block(test_block_512, expected_hash, 1'b0); 

        test_block_512 = {
            64'h6161616161616161, 
            64'h6161616161616161, 
            64'h6161616161616161, 
            64'h6161616161616161, 
            64'h6161616161616161, 
            64'h6161616161616161, 
            64'h6161616161616161, 
            64'h6161616161616161
        };
        load_block(test_block_512, expected_hash, 1'b0); 

        test_block_512 = {
            64'h6161616161616161, 
            64'h6161616161616161, 
            64'h6161616161616161, 
            64'h6161616161616161, 
            64'h6161616161616161, 
            64'h6161616161616161, 
            64'h6161616161616161, 
            64'h6161616161616161
        };
        load_block(test_block_512, expected_hash, 1'b0); 

        test_block_512 = {
            64'h8000000000000000,
            64'h0000000000000000,
            64'h0000000000000000,
            64'h0000000000000000,
            64'h0000000000000000,
            64'h0000000000000000,
            64'h0000000000000000,
            64'h0000000000000800 
        };
        load_block(test_block_512, expected_hash, 1'b1); 

        if (errors == 0) begin
            $display("All tests passed!");
        end else begin
            $display("%0d tests failed!", errors);
        end

        $finish;
    end

endmodule
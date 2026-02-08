module sha256_compression (
    input wire        clk,
    input wire        rst_n,

    input wire        start,
    input wire        valid_in,

    input wire [31:0] W0_in,
    input wire [31:0] W1_in,
    input wire [31:0] K0_in,
    input wire [31:0] K1_in,

    output wire [31:0] H_out_0, output wire [31:0] H_out_1, output wire [31:0] H_out_2, output wire [31:0] H_out_3,
    output wire [31:0] H_out_4, output wire [31:0] H_out_5, output wire [31:0] H_out_6, output wire [31:0] H_out_7,

    output reg        comp_done,
    output wire [5:0] t
);

    reg [5:0] t_internal;
    reg [31:0] a, b, c, d, e, f, g, h;

    reg [31:0] H0_init, H1_init, H2_init, H3_init, H4_init, H5_init, H6_init, H7_init;

    reg processing;

    localparam IV0 = 32'h6a09e667; localparam IV1 = 32'hbb67ae85;
    localparam IV2 = 32'h3c6ef372; localparam IV3 = 32'ha54ff53a;
    localparam IV4 = 32'h510e527f; localparam IV5 = 32'h9b05688c;
    localparam IV6 = 32'h1f83d9ab; localparam IV7 = 32'h5be0cd19;

    assign t = (processing && t_internal < 32) ? (t_internal << 1) : 6'd0;

    function [31:0] Ch;
        input [31:0] x, y, z;
        Ch = (x & y) ^ (~x & z);
    endfunction

    function [31:0] Maj;
        input [31:0] x, y, z;
        Maj = (x & y) ^ (x & z) ^ (y & z);
    endfunction

    function [31:0] ROTR;
        input [31:0] x;
        input [4:0] n;
        ROTR = (x >> n) | (x << (32 - n));
    endfunction

    function [31:0] Sigma0;
        input [31:0] x;
        Sigma0 = ROTR(x, 5'd2) ^ ROTR(x, 5'd13) ^ ROTR(x, 5'd22);
    endfunction

    function [31:0] Sigma1;
        input [31:0] x;
        Sigma1 = ROTR(x, 5'd6) ^ ROTR(x, 5'd11) ^ ROTR(x, 5'd25);
    endfunction

    reg [31:0] T1, Temp1, Temp2, Temp10, Temp20;
    reg [31:0] T2;
    reg [31:0] T10;
    reg [31:0] T20;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            t_internal <= 6'd0;
            processing <= 1'b0;
            comp_done <= 1'b0;
            a <= 32'b0; b <= 32'b0; c <= 32'b0; d <= 32'b0;
            e <= 32'b0; f <= 32'b0; g <= 32'b0; h <= 32'b0;
            H0_init <= IV0; H1_init <= IV1; H2_init <= IV2; H3_init <= IV3;
            H4_init <= IV4; H5_init <= IV5; H6_init <= IV6; H7_init <= IV7;
        end else begin
            comp_done <= 1'b0;

            if (start && !processing) begin
                processing <= 1'b1;
                t_internal <= 6'd0;
                a <= H0_init; b <= H1_init; c <= H2_init; d <= H3_init;
                e <= H4_init; f <= H5_init; g <= H6_init; h <= H7_init;
            end else if (processing) begin
               

                if (t_internal == 31) begin
                    H0_init <= H0_init + Temp10 + Temp20 ; H1_init <= H1_init + Temp1 + Temp2; H2_init <= H2_init + a; H3_init <= H3_init + b;
                    H4_init <= H4_init + c + Temp10; H5_init <= H5_init + d + Temp1; H6_init <= H6_init + e; H7_init <= H7_init + f;
                    comp_done <= 1'b1;
                    processing <= 1'b0;
                    t_internal <= 0;

                end else if (t_internal < 31 && valid_in) begin
                    Temp1 = h + Sigma1(e) + Ch(e, f, g) + K0_in + W0_in;
                    Temp2 = Sigma0(a) + Maj(a, b, c);
                    Temp10 = g + Sigma1(d + T1) + Ch(d + T1, e, f) + K1_in + W1_in;
                    Temp20 = Sigma0(T1 + T2) + Maj(T1 + T2, a, b);
                    T1 = Temp1; T2 = Temp2; T10 = Temp10; T20 = Temp20;
                    h <= f;
                    g <= e;
                    f <= d + T1;
                    e <= c + T10;
                    d <= b;
                    c <= a;
                    b <= T1 + T2;
                    a <= T10 + T20;
                    t_internal <= t_internal + 1;
                end
            end
        end
    end

    assign H_out_0 = H0_init; assign H_out_1 = H1_init; assign H_out_2 = H2_init; assign H_out_3 = H3_init;
    assign H_out_4 = H4_init; assign H_out_5 = H5_init; assign H_out_6 = H6_init; assign H_out_7 = H7_init;

endmodule
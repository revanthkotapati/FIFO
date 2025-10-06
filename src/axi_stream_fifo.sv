module axi_stream_fifo #(
    parameter int DATA_WIDTH = 32,
    parameter int FIFO_DEPTH = 40
)(
    input  logic                   clk,
    input  logic                   rst,

    // AXI-Stream Input Interface (Write Port)
    input  logic                   s_tvalid,
    input  logic [DATA_WIDTH-1:0]  s_tdata,
    output logic                   s_tready,

    // AXI-Stream Output Interface (Read Port)
    output logic                   m_tvalid,
    output logic [DATA_WIDTH-1:0]  m_tdata,
    input  logic                   m_tready
);

    // Memory
    logic [DATA_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];

    // Pointers
    logic [$clog2(FIFO_DEPTH)-1:0] w_ptr, r_ptr;

    // Status flags
    logic full, empty;

    // Write logic
    always_ff @(posedge clk) begin
        if (s_tvalid && s_tready && !full) begin
            fifo_mem[w_ptr] <= s_tdata;
        end
    end

    // Write pointer update
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            w_ptr <= '0;
        end else if (s_tvalid && s_tready && !full) begin
            w_ptr <= w_ptr + 1;
        end
    end

    // Read data (sequential)
    always_comb begin
        if (rst) begin
            m_tdata = 32'h0;
        end else if (!empty && m_tready && m_tvalid) begin
            m_tdata = fifo_mem[r_ptr];
            end
        end

    // Read pointer update
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            r_ptr <= '0;
        end else if (!empty && m_tready) begin
            r_ptr <= r_ptr + 1;
        end
    end

//always_ff @(posedge clk or posedge rst) begin
//    if (rst)
//        m_tvalid <= 1'b0;
//    else if (!empty)
//        m_tvalid <= 1'b1;
//    else
//        m_tvalid <= 1'b0;
//end

    // s_tready: input side ready (not full)
    assign s_tready = ~full;

    // m_tvalid: output side valid (not empty)
    assign m_tvalid = ~empty;

    // Status flag logic
    assign empty = (w_ptr == r_ptr);
    assign full  = ((w_ptr + 1'b1) == r_ptr);

endmodule

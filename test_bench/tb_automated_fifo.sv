`timescale 1ns/1ps

module tb_fifo;

    parameter int DATA_WIDTH = 8;
    parameter int FIFO_DEPTH = 16;

  // 1.Port List
  logic clk;
  logic reset;

  logic        s_tvalid;
  logic [DATA_WIDTH-1:0] s_tdata;
  logic        s_tready;

  logic        m_tvalid;
  logic [DATA_WIDTH-1:0] m_tdata;
  logic        m_tready;

  // 2.Internal Variables
  int read_fd;
  int expected_fd;
  int wait_n;
  int data_counter;
  logic [31:0] input_val, expected_val;

  // 3.Input Files and Output Files
  localparam string INPUT_DATA_FILE      = "fifo_input_data.csv";
  localparam string EXPECTED_OUTPUT_FILE = "fifo_expected_output_data.csv";

  // 4.Design Module Instantiation
  axi_stream_fifo #(.DATA_WIDTH(DATA_WIDTH), .FIFO_DEPTH(FIFO_DEPTH)) DUT (
    .clk(clk),
    .rst(reset),
    .s_tvalid(s_tvalid),
    .s_tdata(s_tdata),
    .s_tready(s_tready),
    .m_tvalid(m_tvalid),
    .m_tdata(m_tdata),
    .m_tready(m_tready)
  );

  // 5.Clock Generation
  always #5 clk = ~clk;

  // 6.Reset Task
  task automatic reset_task;
  begin
    reset <= 1;
    repeat (3) @(posedge clk);
    reset <= 0;
    $display("INFO: Reset applied.");
  end
  endtask

  // 7. Input Conditions
  initial begin
    clk = 0;
    reset = 0;
    s_tvalid = 0;
    s_tdata  = 0;
    m_tready = 0;
    data_counter = 0;

    repeat (5) @(posedge clk);
    reset_task();

    fork
  send_input_from_file(INPUT_DATA_FILE,2);
  begin
    repeat(40) @(posedge clk);  // ? Allow data to arrive in FIFO
    read_and_check_output(EXPECTED_OUTPUT_FILE,3);
  end
  join


    $display("TESTBENCH: Simulation completed.");
    $finish;
  end

  // 8. Input Data Feeding Task
  task automatic send_input_from_file(input string FILE_NAME, input int throttle);
  begin
    read_fd = $fopen(INPUT_DATA_FILE, "r");
    if (read_fd == 0) $fatal("ERROR: Could not open input file.");

    while ($fscanf(read_fd, "%h\n", input_val) == 1) begin
      @(posedge clk);
      s_tdata  <= input_val;
      s_tvalid <= 1;
     // m_tready <=1;
      data_counter <= data_counter+1;
        $display("INFO: file content at line %0d is = %0h",data_counter,input_val);


      while (!s_tready) @(posedge clk);
      @(posedge clk);
      s_tvalid <= 0;

      wait_n = $urandom % throttle;
      repeat (wait_n) @(posedge clk);
 
    end

    $fclose(read_fd);
    $display("INFO: Input data sent successfully.");
  end
  endtask

  // 9. Self-Checking Task
  task automatic read_and_check_output(input string FILE_NAME, input int throttle);
  begin
    expected_fd = $fopen(EXPECTED_OUTPUT_FILE, "r");
    if (expected_fd == 0) $fatal("ERROR: Could not open expected output file.");

    while (!$feof(expected_fd)) begin
      m_tready <= 1;
      @(posedge clk);
      if (m_tvalid) begin
        $fscanf(expected_fd, "%h\n", expected_val);

        if (m_tdata === expected_val) begin
          $display("PASS: Output = %h, Expected = %h", m_tdata, expected_val);
        end else begin
          $display("FAIL: Output = %h, Expected = %h", m_tdata, expected_val);
          $stop;
        end

        m_tready <= 0;
        wait_n = $urandom % throttle;
        repeat (wait_n) @(posedge clk);
      end
    end

    $fclose(expected_fd);
    $display("INFO: Output data verified.");
  end
  endtask

endmodule

`timescale 1ns/1ps

module tb_minirv8;

    logic clk;
    logic rst;

    logic [7:0] pc_out;
    logic [7:0] acc_out;
    logic halted;

    integer i;
    integer failures;

    minirv8 dut (
        .clk(clk),
        .rst(rst),
        .pc_out(pc_out),
        .acc_out(acc_out),
        .halted(halted)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        failures = 0;

        // Fill unused program memory with NOP instructions.
        for (i = 0; i < 256; i = i + 1)
            dut.program_mem[i] = 8'h00;

        // Test program:
        //
        // Address  Instruction       Meaning
        // 00       LDI  5             A = 5
        // 02       ADDI 3             A = 8
        // 04       STA  0x10          MEM[0x10] = 8
        // 06       LDI  0             A = 0
        // 08       LDA  0x10          A = 8
        // 0A       SUBI 8             A = 0
        // 0C       JZ   +2            Branch to address 0x10
        // 0E       LDI  99            Must be skipped
        // 10       HLT                Stop execution

        dut.program_mem[8'h00] = 8'h10;
        dut.program_mem[8'h01] = 8'd5;

        dut.program_mem[8'h02] = 8'h20;
        dut.program_mem[8'h03] = 8'd3;

        dut.program_mem[8'h04] = 8'h60;
        dut.program_mem[8'h05] = 8'h10;

        dut.program_mem[8'h06] = 8'h10;
        dut.program_mem[8'h07] = 8'd0;

        dut.program_mem[8'h08] = 8'h70;
        dut.program_mem[8'h09] = 8'h10;

        dut.program_mem[8'h0A] = 8'h30;
        dut.program_mem[8'h0B] = 8'd8;

        dut.program_mem[8'h0C] = 8'h50;
        dut.program_mem[8'h0D] = 8'd2;

        dut.program_mem[8'h0E] = 8'h10;
        dut.program_mem[8'h0F] = 8'd99;

        dut.program_mem[8'h10] = 8'hF0;

        // Hold reset through the first rising clock edge.
        repeat (2) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        // Allow the program to execute, with a timeout.
        i = 0;
        while (!halted && i < 20) begin
            @(posedge clk);
            #1;
            i = i + 1;
        end

        $display("");
        $display("MiniRV-8 Simulation Results");
        $display("---------------------------");

        if (halted) begin
            $display("[PASS] CPU reached HLT");
        end
        else begin
            $display("[FAIL] CPU timed out");
            failures = failures + 1;
        end

        if (acc_out === 8'd0) begin
            $display("[PASS] Accumulator is 0");
        end
        else begin
            $display("[FAIL] Accumulator: got %0d, expected 0",
                     acc_out);
            failures = failures + 1;
        end

        if (dut.data_mem[8'h10] === 8'd8) begin
            $display("[PASS] Stored result MEM[0x10] = 8");
        end
        else begin
            $display("[FAIL] Memory result: got %0d, expected 8",
                     dut.data_mem[8'h10]);
            failures = failures + 1;
        end

        if (pc_out === 8'h10) begin
            $display("[PASS] Relative branch skipped LDI 99");
        end
        else begin
            $display("[FAIL] Final PC: got 0x%02h, expected 0x10",
                     pc_out);
            failures = failures + 1;
        end

        $display("Clock cycles observed: %0d", i);
        $display("Failures: %0d", failures);

        if (failures == 0)
            $display("RESULT: PASS");
        else
            $display("RESULT: FAIL");

        $finish;
    end

endmodule

`timescale 1ns/1ps

module tb_minirv8_extended;

    logic clk = 0;
    logic rst = 1;
    logic [7:0] pc_out;
    logic [7:0] acc_out;
    logic halted;

    integer i;
    integer cycles;
    integer failures = 0;

    minirv8 dut (
        .clk(clk),
        .rst(rst),
        .pc_out(pc_out),
        .acc_out(acc_out),
        .halted(halted)
    );

    always #5 clk = ~clk;

    task automatic reset_cpu;
        begin
            @(negedge clk);
            rst = 1;
            repeat (2) @(posedge clk);
            @(negedge clk);
            rst = 0;
        end
    endtask

    task automatic run_cpu;
        begin
            cycles = 0;
            while (!halted && cycles < 40) begin
                @(posedge clk);
                #1;
                cycles = cycles + 1;
            end
        end
    endtask

    task automatic check_value(
        input logic condition,
        input [8*80-1:0] message
    );
        begin
            if (condition === 1'b1)
                $display("[PASS] %0s", message);
            else begin
                $display("[FAIL] %0s", message);
                failures = failures + 1;
            end
        end
    endtask

    initial begin
        // Initialize program memory to NOP.
        for (i = 0; i < 256; i = i + 1)
            dut.program_mem[i] = 8'h00;

        // TEST 1: Negative relative branch loop.
        // LDI 3
        // SUBI 1
        // JZ +2       -> exit loop when A == 0
        // JMP -6      -> return to SUBI
        // STA 0x20
        // HLT

        dut.program_mem[8'h00] = 8'h10;
        dut.program_mem[8'h01] = 8'd3;
        dut.program_mem[8'h02] = 8'h30;
        dut.program_mem[8'h03] = 8'd1;
        dut.program_mem[8'h04] = 8'h50;
        dut.program_mem[8'h05] = 8'd2;
        dut.program_mem[8'h06] = 8'h40;
        dut.program_mem[8'h07] = 8'hFA; // -6
        dut.program_mem[8'h08] = 8'h60;
        dut.program_mem[8'h09] = 8'h20;
        dut.program_mem[8'h0A] = 8'hF0;

        reset_cpu();
        run_cpu();

        check_value(halted, "Negative-branch loop halted");
        check_value(acc_out === 8'd0, "Loop decremented accumulator to zero");
        check_value(dut.data_mem[8'h20] === 8'd0,
                    "Loop stored zero at data address 0x20");
        check_value(pc_out === 8'h0A, "Loop reached HLT at address 0x0A");

        // TEST 2: JZ must NOT branch when accumulator is nonzero.
        // LDI 1
        // JZ +2       -> not taken; next PC = 4
        // LDI 7
        // HLT

        dut.program_mem[8'h00] = 8'h10;
        dut.program_mem[8'h01] = 8'd1;
        dut.program_mem[8'h02] = 8'h50;
        dut.program_mem[8'h03] = 8'd2;
        dut.program_mem[8'h04] = 8'h10;
        dut.program_mem[8'h05] = 8'd7;
        dut.program_mem[8'h06] = 8'hF0;

        reset_cpu();
        run_cpu();

        check_value(halted, "Non-taken conditional branch program halted");
        check_value(acc_out === 8'd7,
                    "Non-taken branch continued to LDI 7");
        check_value(pc_out === 8'h06,
                    "Non-taken branch reached HLT at address 0x06");

        // TEST 3: Arithmetic wraps modulo 256.
        // LDI 250
        // ADDI 10       -> 4
        // STA 0x21
        // HLT

        dut.program_mem[8'h00] = 8'h10;
        dut.program_mem[8'h01] = 8'd250;
        dut.program_mem[8'h02] = 8'h20;
        dut.program_mem[8'h03] = 8'd10;
        dut.program_mem[8'h04] = 8'h60;
        dut.program_mem[8'h05] = 8'h21;
        dut.program_mem[8'h06] = 8'hF0;

        reset_cpu();
        run_cpu();

        check_value(halted, "Wraparound test program halted");
        check_value(acc_out === 8'd4,
                    "250 + 10 wrapped to 4 in 8-bit arithmetic");
        check_value(dut.data_mem[8'h21] === 8'd4,
                    "Wrapped result 4 was stored in data memory");

        $display("");
        $display("Extended Verification Summary");
        $display("------------------------------");
        $display("Checks:   10");
        $display("Failures: %0d", failures);

        if (failures == 0)
            $display("RESULT: PASS");
        else
            $display("RESULT: FAIL");

        $finish;
    end

endmodule

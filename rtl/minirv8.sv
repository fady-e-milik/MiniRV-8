`timescale 1ns/1ps

module minirv8 (
    input  logic       clk,
    input  logic       rst,
    output logic [7:0] pc_out,
    output logic [7:0] acc_out,
    output logic       halted
);

    logic [7:0] pc;
    logic [7:0] acc;

    // Separate 256-byte instruction and data memories.
    logic [7:0] program_mem [0:255];
    logic [7:0] data_mem    [0:255];

    integer i;

    localparam logic [7:0] OP_NOP  = 8'h00;
    localparam logic [7:0] OP_LDI  = 8'h10;
    localparam logic [7:0] OP_ADDI = 8'h20;
    localparam logic [7:0] OP_SUBI = 8'h30;
    localparam logic [7:0] OP_JMP  = 8'h40;
    localparam logic [7:0] OP_JZ   = 8'h50;
    localparam logic [7:0] OP_STA  = 8'h60;
    localparam logic [7:0] OP_LDA  = 8'h70;
    localparam logic [7:0] OP_HLT  = 8'hF0;

    // One instruction executes per active clock edge.
    // Multi-byte instructions use the byte at PC+1 as their operand.
    always_ff @(posedge clk) begin
        if (rst) begin
            pc     <= 8'h00;
            acc    <= 8'h00;
            halted <= 1'b0;

            for (i = 0; i < 256; i = i + 1)
                data_mem[i] <= 8'h00;
        end
        else if (!halted) begin
            case (program_mem[pc])

                OP_NOP: begin
                    pc <= pc + 8'd1;
                end

                OP_LDI: begin
                    acc <= program_mem[pc + 8'd1];
                    pc  <= pc + 8'd2;
                end

                OP_ADDI: begin
                    acc <= acc + program_mem[pc + 8'd1];
                    pc  <= pc + 8'd2;
                end

                OP_SUBI: begin
                    acc <= acc - program_mem[pc + 8'd1];
                    pc  <= pc + 8'd2;
                end

                OP_JMP: begin
                    // Signed offset relative to the next instruction.
                    pc <= pc + 8'd2
                        + $signed(program_mem[pc + 8'd1]);
                end

                OP_JZ: begin
                    if (acc == 8'h00)
                        pc <= pc + 8'd2
                            + $signed(program_mem[pc + 8'd1]);
                    else
                        pc <= pc + 8'd2;
                end

                OP_STA: begin
                    data_mem[program_mem[pc + 8'd1]] <= acc;
                    pc <= pc + 8'd2;
                end

                OP_LDA: begin
                    acc <= data_mem[program_mem[pc + 8'd1]];
                    pc  <= pc + 8'd2;
                end

                OP_HLT: begin
                    halted <= 1'b1;
                    // Keep PC at the HLT instruction.
                end

                default: begin
                    // Undefined opcode: stop rather than execute
                    // arbitrary instructions.
                    halted <= 1'b1;
                end

            endcase
        end
    end

    assign pc_out  = pc;
    assign acc_out = acc;

endmodule

// ============================================================================
// timer.v
//
// 32-bit memory-mapped hardware timer for PicoRV32
//
// Base Address : 0x4000_0000
//
// Register Map:
//   0x4000_0000 : TIMER_CNT
//                 [31:0] Current counter value
//                 Read-only
//
//   0x4000_0004 : TIMER_CMP
//                 [31:0] Compare value
//                 Read / Write
//
//   0x4000_0008 : TIMER_CTRL
//                 bit 0 : Timer enable
//                 bit 1 : Write 1 to clear MATCH flag and IRQ
//                 bit 2 : MATCH flag
//                 bit 31:3 : Reserved
//
// Reset:
//   Active HIGH
//
// Bus:
//   PicoRV32 native memory-style interface
//
// ============================================================================

module timer (

    input  wire        clk,
    input  wire        reset,

    // PicoRV32 memory interface
    input  wire        valid,
    output reg         ready,

    input  wire [3:0]  wstrb,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,

    // Interrupt
    output reg         irq

);

    // ========================================================================
    // Registers
    // ========================================================================

    reg [31:0] counter;
    reg [31:0] compare;

    reg        timer_en;
    reg        match_flag;


    // ========================================================================
    // Address offsets
    // ========================================================================

    localparam ADDR_CNT  = 4'h0;
    localparam ADDR_CMP  = 4'h4;
    localparam ADDR_CTRL = 4'h8;


    // ========================================================================
    // Bus transaction
    //
    // valid is asserted by PicoRV32 until ready is returned.
    //
    // We generate a one-cycle ready pulse.
    // ========================================================================

    wire bus_access = valid && !ready;

    wire bus_write  = bus_access && (|wstrb);

    wire bus_read   = bus_access && !(|wstrb);


    // ========================================================================
    // Timer state machine / registers
    // ========================================================================

    always @(posedge clk) begin

        // --------------------------------------------------------------------
        // RESET
        // --------------------------------------------------------------------
        if (!reset) begin

            counter    <= 32'h0000_0000;

            // 100,000,000 cycles
            // = 1 second at 100 MHz
            compare    <= 32'h05F5_E100;

            timer_en   <= 1'b1;

            match_flag <= 1'b0;

            irq        <= 1'b0;

            ready      <= 1'b0;

        end

        // --------------------------------------------------------------------
        // NORMAL OPERATION
        // --------------------------------------------------------------------
        else begin

            // Default: no bus response
            ready <= 1'b0;


            // =================================================================
            // TIMER OPERATION
            // =================================================================

            if (timer_en) begin

                // Check for compare match
                if ((compare != 32'h0000_0000) &&
                    (counter >= compare)) begin

                    // Restart counter
                    counter <= 32'h0000_0000;

                    // Set match status
                    match_flag <= 1'b1;

                    // Generate interrupt
                    irq <= 1'b1;

                end

                else begin

                    // Free-running counter
                    counter <= counter + 32'd1;

                end

            end


            // =================================================================
            // BUS ACCESS
            // =================================================================

            if (bus_access) begin

                // One-cycle acknowledge
                ready <= 1'b1;


                // -------------------------------------------------------------
                // WRITE
                // -------------------------------------------------------------

                if (bus_write) begin

                    case (addr[3:0])

                        // -----------------------------------------------------
                        // TIMER_CMP
                        // -----------------------------------------------------
                        ADDR_CMP: begin

                            if (wstrb[0])
                                compare[7:0]   <= wdata[7:0];

                            if (wstrb[1])
                                compare[15:8]  <= wdata[15:8];

                            if (wstrb[2])
                                compare[23:16] <= wdata[23:16];

                            if (wstrb[3])
                                compare[31:24] <= wdata[31:24];

                        end


                        // -----------------------------------------------------
                        // TIMER_CTRL
                        // -----------------------------------------------------
                        ADDR_CTRL: begin

                            // Enable bit
                            if (wstrb[0])
                                timer_en <= wdata[0];

                            // Clear match + IRQ
                            if (wstrb[0] && wdata[1]) begin

                                match_flag <= 1'b0;
                                irq        <= 1'b0;

                            end

                        end


                        default: begin
                            // No writable registers
                        end

                    endcase

                end

            end

        end

    end


    // ========================================================================
    // READ DATA
    //
    // Combinational read mux.
    //
    // This is important because PicoRV32 sees mem_ready and mem_rdata
    // together at the transaction boundary.
    // ========================================================================

    always @(*) begin

        case (addr[3:0])

            // ---------------------------------------------------------------
            // TIMER_CNT
            // ---------------------------------------------------------------
            ADDR_CNT:
                rdata = counter;


            // ---------------------------------------------------------------
            // TIMER_CMP
            // ---------------------------------------------------------------
            ADDR_CMP:
                rdata = compare;


            // ---------------------------------------------------------------
            // TIMER_CTRL
            //
            // bit 0 = enable
            // bit 1 = IRQ
            // bit 2 = match flag
            // ---------------------------------------------------------------
            ADDR_CTRL:
                rdata = {
                    29'h0000_0000,
                    match_flag,
                    irq,
                    timer_en
                };


            // ---------------------------------------------------------------
            // Invalid address
            // ---------------------------------------------------------------
            default:
                rdata = 32'h0000_0000;

        endcase

    end

endmodule
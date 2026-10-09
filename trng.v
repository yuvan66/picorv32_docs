// ============================================================================
// trng.v
//
// Memory-mapped True Random Number Generator for PicoRV32 (Xilinx 7-series)
//
// Base Address : 0x5000_0000
//
// Architecture
//   ring-oscillator bank (NUM_RO oscillators, all different odd lengths)
//     -> 2-FF synchroniser per oscillator (ASYNC_REG)
//     -> XOR of all oscillators
//     -> sampled once every (DIV+1) clk cycles
//     -> warm-up discard
//     -> continuous health tests on the raw bits
//          * Repetition Count Test      (NIST SP 800-90B 4.4.1)
//          * Adaptive Proportion Test   (NIST SP 800-90B 4.4.2, binary)
//     -> optional von Neumann de-biasing
//     -> 32-bit word assembly + 1-word output holding register
//
// Register Map (all 32-bit, word aligned)
//
//   0x5000_0000 : TRNG_DATA   (RO)
//                 [31:0] random word. READING POPS THE WORD (clears
//                 DATA_VALID). Returns 0 and sets UNDERFLOW if no word is
//                 available or a health test has failed.
//
//   0x5000_0004 : TRNG_STATUS (RO)
//                 bit 0 : DATA_VALID   a fresh word is waiting
//                 bit 1 : HEALTH_FAIL  RCT_FAIL | APT_FAIL (sticky)
//                 bit 2 : RCT_FAIL     repetition-count test failed (sticky)
//                 bit 3 : APT_FAIL     adaptive-proportion test failed (sticky)
//                 bit 4 : WARMUP_DONE  start-up discard finished
//                 bit 5 : UNDERFLOW    DATA read while empty/failed (sticky)
//
//   0x5000_0008 : TRNG_CTRL   (RW)
//                 bit 0 : EN       enable oscillators + sampling (reset: 0)
//                 bit 1 : VN_EN    von Neumann de-biasing        (reset: 1)
//                 bit 2 : IRQ_EN   irq = IRQ_EN & (DATA_VALID | HEALTH_FAIL)
//                 bit 3 : CLR      write 1: clear fail flags/UNDERFLOW,
//                                  flush data, restart warm-up (self-clearing)
//
//   0x5000_000C : TRNG_DIV    (RW)
//                 [15:0] sample period = DIV + 1 clk cycles
//                 (reset: DIV_RESET). Larger = more jitter accumulated per
//                 sample = better entropy per bit, lower throughput.
//
// Reset : Active HIGH (same convention as timer.v)
// Bus   : PicoRV32 native memory-style interface, one-cycle ready pulse
//
// NOTE ON ENTROPY / DEFAULTS
//   The default DIV, RCT_CUTOFF and APT_CUTOFF are conservative starting
//   points, NOT a certified entropy claim. For real use, capture raw bits
//   (VN_EN = 0) from your board and run the NIST SP 800-90B / dieharder
//   tools, then tune DIV and the cutoffs to the measured min-entropy.
//
// NOTE ON TOOLS (Vivado)
//   Ring oscillators are combinational loops. Vivado needs:
//     set_property SEVERITY {Warning} [get_drc_checks LUTLP-1]
//   plus false-path constraints from the oscillator outputs (see the
//   accompanying notes). The loops only exist under `SYNTHESIS; in
//   simulation a behavioural random source is used instead.
// ============================================================================


// ============================================================================
// Ring-oscillator bank
// ============================================================================
module trng_ro_bank #(
    parameter integer NUM_RO = 16
) (
    input  wire              clk,      // used by the simulation model only
    input  wire              en,
    output wire [NUM_RO-1:0] ro_out
);

`ifdef SYNTHESIS

    genvar i, j;
    generate
        for (i = 0; i < NUM_RO; i = i + 1) begin : g_ro

            // Oscillator i has LEN inverting stages (always odd): 3,5,7,...
            // Different lengths -> different frequencies -> they do not
            // phase-lock to each other.
            localparam integer LEN = 3 + 2*i;

            (* KEEP = "TRUE", DONT_TOUCH = "TRUE",
               ALLOW_COMBINATORIAL_LOOPS = "TRUE" *)
            wire [LEN-1:0] n;

            // Stage 0: NAND(feedback, en) -> acts as inverter when en = 1,
            // forces output high (loop stops) when en = 0.
            (* DONT_TOUCH = "TRUE" *)
            LUT2 #(.INIT(4'h7)) u_nand (
                .O (n[0]),
                .I0(n[LEN-1]),
                .I1(en)
            );

            // Stages 1..LEN-1: plain inverters
            for (j = 1; j < LEN; j = j + 1) begin : g_inv
                (* DONT_TOUCH = "TRUE" *)
                LUT1 #(.INIT(2'h1)) u_inv (
                    .O (n[j]),
                    .I0(n[j-1])
                );
            end

            assign ro_out[i] = n[LEN-1];
        end
    endgenerate

`else

    // ---- Simulation model: zero-delay loops cannot oscillate in an RTL
    // simulator, so emulate "jittery" oscillators with random bits.
    reg [NUM_RO-1:0] ro_sim = {NUM_RO{1'b0}};
    integer k;
    always @(posedge clk) begin
        for (k = 0; k < NUM_RO; k = k + 1)
            ro_sim[k] <= en ? ($random & 1) : 1'b1;
    end
    assign ro_out = ro_sim;

`endif

endmodule


// ============================================================================
// TRNG top (bus slave)
// ============================================================================
module trng #(
    parameter integer NUM_RO         = 16,
    parameter integer WARMUP_SAMPLES = 1024,
    parameter integer RCT_CUTOFF     = 32,     // consecutive identical bits
    parameter integer APT_WINDOW     = 1024,   // samples per window
    parameter integer APT_CUTOFF     = 680,    // max count of ref bit in window
    parameter [15:0]  DIV_RESET      = 16'd255 // sample period = DIV+1 cycles
) (
    input  wire        clk,
    input  wire        reset,          // active HIGH

    // PicoRV32 memory interface
    input  wire        valid,
    output reg         ready,
    input  wire [3:0]  wstrb,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,

    // Interrupt (level)
    output wire        irq
);

    // ------------------------------------------------------------------
    // Control / status registers
    // ------------------------------------------------------------------
    reg        en;
    reg        vn_en;
    reg        irq_en;
    reg [15:0] div;
    reg        underflow;
    reg        clr_pulse;

    reg        rct_fail;
    reg        apt_fail;
    reg        warm_done;
    reg        data_valid;
    reg [31:0] data_reg;

    wire health_fail = rct_fail | apt_fail;

    assign irq = irq_en & (data_valid | health_fail);

    // ------------------------------------------------------------------
    // Entropy source + synchronisers
    // ------------------------------------------------------------------
    wire [NUM_RO-1:0] ro_out;

    trng_ro_bank #(.NUM_RO(NUM_RO)) u_bank (
        .clk   (clk),
        .en    (en),
        .ro_out(ro_out)
    );

    (* ASYNC_REG = "TRUE" *) reg [NUM_RO-1:0] sync1;
    (* ASYNC_REG = "TRUE" *) reg [NUM_RO-1:0] sync2;

    always @(posedge clk) begin
        sync1 <= ro_out;
        sync2 <= sync1;
    end

    wire raw_xor = ^sync2;

    // ------------------------------------------------------------------
    // Sample tick generator
    // ------------------------------------------------------------------
    reg [15:0] div_cnt;
    reg        tick;
    reg        raw_bit;

    always @(posedge clk) begin
        if (!reset || !en) begin
            div_cnt <= 16'd0;
            tick    <= 1'b0;
            raw_bit <= 1'b0;
        end else begin
            tick <= 1'b0;
            if (div_cnt >= div) begin
                div_cnt <= 16'd0;
                tick    <= 1'b1;
                raw_bit <= raw_xor;
            end else begin
                div_cnt <= div_cnt + 16'd1;
            end
        end
    end

    // One-cycle delayed copy for the data path, so that a health-test
    // failure triggered by a sample is already visible before that sample
    // can reach the output.
    reg tick_d;
    reg bit_d;
    always @(posedge clk) begin
        tick_d <= tick;
        bit_d  <= raw_bit;
    end

    // ------------------------------------------------------------------
    // Warm-up + health tests (operate on raw sampled bits)
    // ------------------------------------------------------------------
    localparam integer WARM_W = $clog2(WARMUP_SAMPLES + 1);
    localparam integer RCT_W  = $clog2(RCT_CUTOFF + 2);
    localparam integer APT_IW = $clog2(APT_WINDOW);
    localparam integer APT_CW = $clog2(APT_WINDOW + 1);

    reg [WARM_W-1:0] warm_cnt;

    reg              rct_init;
    reg              rct_last;
    reg [RCT_W-1:0]  rct_run;

    reg [APT_IW-1:0] apt_idx;
    reg              apt_ref;
    reg [APT_CW-1:0] apt_cnt;

    always @(posedge clk) begin
        // sticky fail flags: cleared only by reset or software CLR
        if (!reset || clr_pulse) begin
            rct_fail <= 1'b0;
            apt_fail <= 1'b0;
        end

        if (!reset || clr_pulse || !en) begin
            warm_cnt  <= {WARM_W{1'b0}};
            warm_done <= 1'b0;
            rct_init  <= 1'b0;
            rct_last  <= 1'b0;
            rct_run   <= {RCT_W{1'b0}};
            apt_idx   <= {APT_IW{1'b0}};
            apt_ref   <= 1'b0;
            apt_cnt   <= {APT_CW{1'b0}};
        end else if (tick) begin

            if (!warm_done) begin
                // discard start-up samples
                if (warm_cnt == WARMUP_SAMPLES - 1) warm_done <= 1'b1;
                else                                warm_cnt  <= warm_cnt + 1'b1;
            end else begin

                // ---- Repetition Count Test ----
                if (!rct_init) begin
                    rct_init <= 1'b1;
                    rct_last <= raw_bit;
                    rct_run  <= 1;
                end else if (raw_bit == rct_last) begin
                    rct_run <= rct_run + 1'b1;
                    if (rct_run + 1 >= RCT_CUTOFF) rct_fail <= 1'b1;
                end else begin
                    rct_last <= raw_bit;
                    rct_run  <= 1;
                end

                // ---- Adaptive Proportion Test ----
                if (apt_idx == 0) begin
                    apt_ref <= raw_bit;
                    apt_cnt <= 1;
                    apt_idx <= 1;
                end else begin
                    if (raw_bit == apt_ref) begin
                        apt_cnt <= apt_cnt + 1'b1;
                        if (apt_cnt + 1 >= APT_CUTOFF) apt_fail <= 1'b1;
                    end
                    if (apt_idx == APT_WINDOW - 1) apt_idx <= {APT_IW{1'b0}};
                    else                           apt_idx <= apt_idx + 1'b1;
                end
            end
        end
    end

    // ------------------------------------------------------------------
    // Bus transaction (same handshake style as timer.v)
    // ------------------------------------------------------------------
    wire bus_access = valid && !ready;
    wire bus_write  = bus_access &&  (|wstrb);
    wire bus_read   = bus_access && !(|wstrb);

    localparam [2:0] REG_DATA   = 3'd0;
    localparam [2:0] REG_STATUS = 3'd1;
    localparam [2:0] REG_CTRL   = 3'd2;
    localparam [2:0] REG_DIV    = 3'd3;

    wire data_avail = data_valid && !health_fail;
    wire pop        = bus_read && (addr[4:2] == REG_DATA) && data_avail;

    // ------------------------------------------------------------------
    // Conditioner (von Neumann) + word assembly + output register
    // ------------------------------------------------------------------
    reg        vn_have;
    reg        vn_first;
    reg [31:0] shreg;
    reg [4:0]  sh_cnt;

    wire take  = tick_d && warm_done && !data_valid;
    wire out_v = take && (vn_en ? (vn_have && (vn_first != bit_d)) : 1'b1);
    wire out_b = vn_en ? vn_first : bit_d;

    always @(posedge clk) begin
        if (!reset || clr_pulse || !en || health_fail) begin
            vn_have    <= 1'b0;
            vn_first   <= 1'b0;
            sh_cnt     <= 5'd0;
            shreg      <= 32'h0;
            data_valid <= 1'b0;
            data_reg   <= 32'h0;
        end else begin

            if (pop) begin
                data_valid <= 1'b0;
                data_reg   <= 32'h0;     // do not leave a used word lying around
            end

            // von Neumann pairing state
            if (!vn_en) begin
                vn_have <= 1'b0;
            end else if (take) begin
                vn_have <= ~vn_have;
                if (!vn_have) vn_first <= bit_d;
            end

            // word assembly
            if (out_v) begin
                shreg <= {shreg[30:0], out_b};
                if (sh_cnt == 5'd31) begin
                    data_reg   <= {shreg[30:0], out_b};
                    data_valid <= 1'b1;
                    sh_cnt     <= 5'd0;
                end else begin
                    sh_cnt <= sh_cnt + 5'd1;
                end
            end
        end
    end

    // ------------------------------------------------------------------
    // Register read/write
    // ------------------------------------------------------------------
    always @(posedge clk) begin
        if (!reset) begin
            ready     <= 1'b0;
            rdata     <= 32'h0;
            en        <= 1'b0;
            vn_en     <= 1'b1;
            irq_en    <= 1'b0;
            div       <= DIV_RESET;
            underflow <= 1'b0;
            clr_pulse <= 1'b0;
        end else begin
            ready     <= 1'b0;
            clr_pulse <= 1'b0;

            if (bus_access) begin
                ready <= 1'b1;
                rdata <= 32'h0;

                // ---------------- READ ----------------
                if (bus_read) begin
                    case (addr[4:2])
                        REG_DATA: begin
                            if (data_avail) rdata     <= data_reg;
                            else            underflow <= 1'b1;
                        end
                        REG_STATUS:
                            rdata <= {26'h0, underflow, warm_done,
                                      apt_fail, rct_fail, health_fail,
                                      data_valid};
                        REG_CTRL:
                            rdata <= {29'h0, irq_en, vn_en, en};
                        REG_DIV:
                            rdata <= {16'h0, div};
                        default: ;
                    endcase
                end

                // ---------------- WRITE ---------------
                if (bus_write) begin
                    case (addr[4:2])
                        REG_CTRL: begin
                            if (wstrb[0]) begin
                                en     <= wdata[0];
                                vn_en  <= wdata[1];
                                irq_en <= wdata[2];
                                if (wdata[3]) begin
                                    clr_pulse <= 1'b1;
                                    underflow <= 1'b0;
                                end
                            end
                        end
                        REG_DIV: begin
                            if (wstrb[0]) div[7:0]  <= wdata[7:0];
                            if (wstrb[1]) div[15:8] <= wdata[15:8];
                        end
                        default: ;   // DATA / STATUS are read-only
                    endcase
                end
            end
        end
    end

endmodule

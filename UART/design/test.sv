`timescale 1ns/1ps
`include "UART_TX.v"
`include "UART_RX.v"

module top();

    bit clk;
    bit rst_n;
    bit [7:0] data_tx;
    bit en_tx;
    bit en_rx;

    logic u_tx_done;
    logic [7:0] data_rx;
    logic u_rx_done;
    logic parity_error;
    logic framing_error;
    wire tx_rx;

    uart_master u1(
        .clk(clk),
        .rst_n(rst_n),
        .data(data_tx),
        .en_tx(en_tx),
        .u_tx(tx_rx),
        .u_tx_done(u_tx_done)
    );

    uart_slave u2(
        .clk(clk),
        .rst_n(rst_n),
        .u_rx(tx_rx),
        .en_rx(en_rx),
        .data(data_rx),
        .u_rx_done(u_rx_done),
        .parity_error(parity_error),
        .framing_error(framing_error)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, top);
    end

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst_n = 1'b0;
        data_tx = 8'h00;
        en_tx = 1'b0;
        en_rx = 1'b0;

        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        send_and_check(8'b10010101);
        send_and_check(8'hA5);
        send_and_check(8'h00);
        send_and_check(8'hFF);

        $display("All UART loopback tests passed");
        #20 $finish;
    end

    task automatic send_and_check(input [7:0] payload);
        begin
            @(posedge clk);
            data_tx = payload;
            en_rx = 1'b1;
            en_tx = 1'b1;

            wait (u_tx_done);
            en_tx = 1'b0;

            wait (u_rx_done);
            en_rx = 1'b0;

            if (parity_error) begin
                $fatal(1, "Parity error for payload %b", payload);
            end

            if (framing_error) begin
                $fatal(1, "Framing error for payload %b", payload);
            end

            if (data_rx !== payload) begin
                $fatal(1, "UART mismatch: expected %b, got %b", payload, data_rx);
            end

            $display("PASS: sent %b, received %b", payload, data_rx);
        end
    endtask

endmodule

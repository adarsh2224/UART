module uart_slave(
    input clk,
    input rst_n,
    input u_rx,
    input en_rx,
    output reg [7:0] data,
    output reg u_rx_done,
    output reg parity_error,
    output reg framing_error
);

reg [2:0] state_rx;
reg [2:0] count;
reg [7:0] dout;
reg parity_bit;

localparam IDLE   = 3'b000;
localparam DATA   = 3'b001;
localparam PARITY = 3'b010;
localparam STOP   = 3'b011;
localparam DONE   = 3'b100;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_rx <= IDLE;
        count <= 3'd0;
        dout <= 8'd0;
        parity_bit <= 1'b0;
        data <= 8'd0;
        u_rx_done <= 1'b0;
        parity_error <= 1'b0;
        framing_error <= 1'b0;
    end
    else begin
        u_rx_done <= 1'b0;

        case (state_rx)
        IDLE: begin
            count <= 3'd0;

            if (en_rx && (u_rx == 1'b0)) begin
                parity_error <= 1'b0;
                framing_error <= 1'b0;
                state_rx <= DATA;
            end
        end

        DATA: begin
            dout[count] <= u_rx;

            if (count == 3'd7) begin
                count <= 3'd0;
                state_rx <= PARITY;
            end
            else begin
                count <= count + 3'd1;
            end
        end

        PARITY: begin
            parity_bit <= u_rx;
            parity_error <= (u_rx != ^dout);
            state_rx <= STOP;
        end

        STOP: begin
            framing_error <= (u_rx != 1'b1);

            if ((parity_bit == ^dout) && (u_rx == 1'b1)) begin
                data <= dout;
                state_rx <= DONE;
            end
            else begin
                state_rx <= IDLE;
            end
        end

        DONE: begin
            u_rx_done <= 1'b1;
            state_rx <= IDLE;
        end

        default: begin
            state_rx <= IDLE;
        end
        endcase
    end
end

endmodule

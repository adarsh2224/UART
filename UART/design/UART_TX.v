module uart_master(
    input clk,
    input rst_n,
    input [7:0] data,
    input en_tx,
    output reg u_tx,
    output reg u_tx_done
);

reg [2:0] state_tx;
reg [2:0] count;
reg [7:0] din;

localparam IDLE   = 3'b000;
localparam START  = 3'b001;
localparam DATA   = 3'b010;
localparam PARITY = 3'b011;
localparam STOP   = 3'b100;
localparam DONE   = 3'b101;

always @(negedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_tx <= IDLE;
        count <= 3'd0;
        din <= 8'd0;
        u_tx <= 1'b1;
        u_tx_done <= 1'b0;
    end
    else begin
        u_tx_done <= 1'b0;

        case (state_tx)
        IDLE: begin
            u_tx <= 1'b1;
            count <= 3'd0;

            if (en_tx) begin
                din <= data;
                state_tx <= START;
            end
        end

        START: begin
            u_tx <= 1'b0;
            state_tx <= DATA;
        end

        DATA: begin
            u_tx <= din[count];

            if (count == 3'd7) begin
                count <= 3'd0;
                state_tx <= PARITY;
            end
            else begin
                count <= count + 3'd1;
            end
        end

        PARITY: begin
            u_tx <= ^din;
            state_tx <= STOP;
        end

        STOP: begin
            u_tx <= 1'b1;
            state_tx <= DONE;
        end

        DONE: begin
            u_tx <= 1'b1;
            u_tx_done <= 1'b1;
            state_tx <= IDLE;
        end

        default: begin
            state_tx <= IDLE;
            u_tx <= 1'b1;
        end
        endcase
    end
end

endmodule

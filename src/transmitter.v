module transmitter(
    input clk, rst, tx_p, start_en,
    input [7:0] datain,
    output reg tx
);

parameter idle          = 2'b00;
parameter start         = 2'b01;
parameter data_transmit = 2'b10;
parameter stop          = 2'b11;

reg [1:0] state;
reg [2:0] index;
reg [7:0] data;

always @(posedge clk) begin
    if(rst) begin
        tx    <= 1'b1;
        state <= idle;
        index <= 0;
        data  <= 0;
    end
    else begin
        case(state)
            idle: begin
                tx <= 1'b1; 
                if(start_en) begin
                    data  <= datain;
                    state <= start;
                end
            end

            start: begin
                if(tx_p) begin
                    tx    <= 1'b0;
                    index <= 0;
                    state <= data_transmit;
                end
            end

            data_transmit: begin
                if(tx_p) begin
                    tx <= data[index];
                    if(index == 3'd7) begin
                        state <= stop;
                    end
                    else begin
                        index <= index + 1;
                    end
                end
            end

            stop: begin
                if(tx_p) begin
                    tx    <= 1'b1;
                    state <= idle;
                end
            end

            default: state <= idle;
        endcase
    end
end
endmodule

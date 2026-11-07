module baudrategenerator(
    input clk, rst,
    output reg tx_p, rx_p
);

reg [12:0] tx_counter;
reg [8:0] rx_counter;

always @(posedge clk) begin
    if(rst) begin
        tx_counter <= 0;
        rx_counter <= 0;
        tx_p       <= 0;
        rx_p       <= 0;
    end
    else begin
        if(tx_counter == 13'd5208) begin 
            tx_counter <= 0;
            tx_p       <= 1;
        end else begin
            tx_counter <= tx_counter + 1;
            tx_p       <= 0;
        end
        if(rx_counter == 9'd325) begin 
            rx_counter <= 0;
            rx_p       <= 1;
        end else begin
            rx_counter <= rx_counter + 1;
            rx_p       <= 0;
        end
    end
end
endmodule

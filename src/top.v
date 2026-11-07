module uart(
    input clk, rst, start_en, 
    input [7:0] input_data,
    output [7:0] data
);

wire tx_en, rx_en, intermediate_data;

baudrategenerator brg(
    .clk(clk),
    .rst(rst),
    .tx_p(tx_en),
    .rx_p(rx_en)
);

transmitter transmitter1(
    .clk(clk),
    .rst(rst),
    .tx_p(tx_en),
    .start_en(start_en),
    .datain(input_data),
    .tx(intermediate_data)
);

receiver receiver1(
    .data_transmitted(intermediate_data),
    .clk(clk),
    .rst(rst),
    .rx_p(rx_en),
    .data(data)
);

endmodule

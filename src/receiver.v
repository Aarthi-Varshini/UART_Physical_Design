module receiver(
    input data_transmitted, clk, rst, rx_p,
    output reg [7:0] data
);

parameter idle    = 2'b00;
parameter start   = 2'b01;
parameter received = 2'b10;
parameter stop    = 2'b11;

reg [1:0] state;
reg [3:0] clk_edge_count;
reg [2:0] index;
reg [7:0] temp;

always @(posedge clk) begin
    if(rst) begin
        state          <= idle;
        clk_edge_count <= 0;
        index          <= 0;
        temp           <= 0;
        data           <= 0;
    end
    else if(rx_p) begin
        case(state)
            idle: begin
                clk_edge_count <= 0;
                index          <= 0;
                if(data_transmitted == 1'b0) begin 
                    state <= start;
                end
            end

            start: begin
                if(clk_edge_count == 4'd7) begin
                    if(data_transmitted == 1'b0) begin
                        clk_edge_count <= 0;
                        state          <= received;
                    end else begin
                        state <= idle;
                    end
                end else begin
                    clk_edge_count <= clk_edge_count + 1;
                end
            end

            received: begin
                if(clk_edge_count == 4'd15) begin
                   clk_edge_count  <= 0;
                    temp[index]     <= data_transmitted;
                    if(index == 3'd7) begin
                        state <= stop;
                    end else begin
                        index <= index + 1;
                    end
                end else begin
                    clk_edge_count <= clk_edge_count + 1;
                end
            end

            stop: begin
                if(clk_edge_count == 4'd15) begin
                    data  <= temp;
                    state <= idle;
                end else begin
                    clk_edge_count <= clk_edge_count + 1;
                end
            end
            
            default: state <= idle;
        endcase
    end
end
endmodule

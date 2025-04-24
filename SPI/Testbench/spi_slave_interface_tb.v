module spi_slave_interface_tb();
    //parameters
    parameter MEM_DEPTH = 256;
    parameter MEM_ADDR_SIZE = 8;
    parameter MEM_INPUT_SIZE = 10;
    parameter MEM_WORD_SIZE = 8;
    ////////////////////////////////
    //input and output signals
    reg MOSI_tb;
    wire MISO_tb;
    reg clk_tb;
    reg SS_n_tb;
    reg rst_n_tb;
    //////////////////////////////////
    //instantiation of the module
    spi_slave_interface spi_dut (
                            MOSI_tb,
                            MISO_tb,
                            clk_tb,
                            SS_n_tb,
                            rst_n_tb
                        );
    /////////////////////////////
    reg [9:0] send_data;
    reg [7:0] address;
    reg [7:0] expected_data;
    reg [7:0] received_data;

    /////////////////////////////////////////
    //clk generation
    initial begin
        clk_tb=0;
        forever
            #5 clk_tb=~clk_tb;
    end
    ////////////////////////////////////////
    initial begin
        // test reset
        rst_n_tb = 0;
        SS_n_tb = 1;
        MOSI_tb = 0;
        send_data = 0;
        @(negedge clk_tb);
        //////////////////////////////////////////

        repeat (40) begin
            //test sending address for write
            rst_n_tb = 1;
            SS_n_tb = 0;
            send_data = $random;
            send_data[9:8] = 2'b00;
            address = send_data[7:0];
            send_data_task();
            @(negedge clk_tb);
            @(negedge clk_tb);
            SS_n_tb = 1;
            @(negedge clk_tb);
            @(negedge clk_tb);

            // test writing data
            SS_n_tb = 0;
            send_data = $random;
            send_data[9:8] = 2'b01;
            expected_data = send_data[7:0];
            send_data_task();
            @(negedge clk_tb);
            @(negedge clk_tb);
            SS_n_tb = 1;
            @(negedge clk_tb);
            @(negedge clk_tb);

            //test writing read address
            SS_n_tb = 0;
            send_data = address;
            send_data[9:8] = 2'b10;
            send_data_task();
            @(negedge clk_tb);
            @(negedge clk_tb);
            SS_n_tb = 1;
            @(negedge clk_tb);
            @(negedge clk_tb);

            //read data
            SS_n_tb = 0;
            send_data = 10'b1100000000;
            send_data_task();
            @(negedge clk_tb);
            @(negedge clk_tb);
            get_data_task();
            SS_n_tb = 1;
            @(negedge clk_tb);
        end

        @(negedge clk_tb);
        $stop;
    end

    // Task to send data to the DUT
    task send_data_task();
        integer i;
        begin
            @(negedge clk_tb);
            MOSI_tb = send_data[9];
            @(negedge clk_tb);
            for (i = 9; i >= 0; i = i - 1) begin
                MOSI_tb = send_data[i];
                @(negedge clk_tb);
            end
            MOSI_tb = 0;
        end
    endtask

    // Task to get data from the DUT
    task get_data_task();
        integer i;
        begin
            for (i = 7; i >= 0; i = i - 1) begin
                @(negedge clk_tb);
                received_data[i] = MISO_tb;
            end
            if(expected_data != received_data) begin
                $display("Test Failed: Expected Data = %h, Received Data = %h, Address = %h", expected_data, received_data, address);
            end
            else begin
                $display("Test Passed: Expected Data = %h, Received Data = %h, Address = %h", expected_data, received_data, address);
            end
        end
    endtask
    /////////////////////////////
endmodule

module gamblinggame_tb;
  parameter CLOCK_PERIOD = 5;

  logic clk;
  logic fundsbutton;
  logic [31:0] fundsadded, betamount;
  logic startbutton, wheelbutton;
  logic rst;
  logic [31:0] displayfunds, displaybet;
  logic [2:0] displaywheel0, displaywheel1, displaywheel2, displaydice;

  gamblinggame DUT (
    .clk(clk),
    .fundsbutton(fundsbutton),
    .fundsadded(fundsadded),
    .betamount(betamount),
    .startbutton(startbutton),
    .wheelbutton(wheelbutton),
    .rst(rst),
    .displayfunds(displayfunds),
    .displaybet(displaybet),
    .displaywheel0(displaywheel0),
    .displaywheel1(displaywheel1),
    .displaywheel2(displaywheel2),
    .displaydice(displaydice)
  );

  initial begin
    clk = 0;
    forever #CLOCK_PERIOD clk = ~clk;
  end

  initial begin
    #1
    fundsbutton = 0;
    fundsadded = 100;
    betamount = 10;
    startbutton = 0;
    wheelbutton = 0;
    rst = 1;

    #10 rst = 0;

    fundsbutton = 1;
    #10
    fundsbutton = 0;
    #10
    #10

    startbutton = 1;
    #10
    startbutton = 0;
    

    wheelbutton = 1;
    #20 wheelbutton = 0;
    #20
    betamount = 100;

    wheelbutton = 1;
    #10 wheelbutton = 0;
    betamount = 10;
    #10
    wheelbutton = 1;
    #20 wheelbutton = 0;

    #100

    betamount = 100;
    startbutton = 1;
    #10
    startbutton = 0;
    #10
    betamount = 10; 
    startbutton = 1;
    #10

    startbutton = 0;
    wheelbutton = 1;
    #10
    wheelbutton = 0;
    #60
    wheelbutton = 1;
    #10
    wheelbutton = 0;
    #60
    wheelbutton = 1;
    #10
    wheelbutton = 0;
    #60

    wheelbutton = 1;
    #10
    wheelbutton = 0;
    #200

    $stop;
  end

endmodule
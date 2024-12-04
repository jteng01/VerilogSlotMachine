`define ADDFUNDS 8'd0
`define WAITRELEASEFUNDS 8'd10
`define PLACEBET 8'd1
`define SPINWHEEL 8'd2
`define STOPWHEEL 8'd3
`define CHECKWIN 8'd5
`define ROLLDICE 8'd6
`define STOPDICE 8'd7
`define WINCREDITS 8'd8
`define DECREMENTCREDITS 8'd9
`define INCREMENTSPINCOUNTER 8'd11

module gamblinggame(clk, fundsbutton, fundsadded, betamount, startbutton, wheelbutton, rst, 
displayfunds, displaybet, displaywheel0, displaywheel1, displaywheel2, displaydice);
    input logic [31:0] fundsadded, betamount;
    input logic clk, fundsbutton, startbutton, wheelbutton, rst;
    output logic [31:0] displayfunds, displaybet;
    output logic [2:0] displaywheel0, displaywheel1, displaywheel2, displaydice;

    logic [7:0] ps;
    logic [7:0] ns;
    logic [7:0] nsr;

    logic [31:0] funds, nextfunds, bet;
    logic [1:0] selfunds;
    logic loadfunds, loadbet, enoughfunds;
    vDFFRL #(32) credits(clk, nextfunds, funds, rst, loadfunds); 
    vDFFRL #(32) betting(clk, betamount, bet, rst, loadbet);
    MUX3 #(32) fundsmux(funds+bet, funds-bet, funds+fundsadded, selfunds, nextfunds);
    assign enoughfunds = (funds >= betamount);
    
    logic[2:0] rngwheel;
    logic [2:0] wheel0, wheel1, wheel2;
    logic [2:0] loadwheel;
    logic [1:0] spincount; 
    logic win, donespins, incrementspin, unlock, rstspins, rstwheels;
    RNG #(3) generatewheel(clk, rst, 1, 7, rngwheel);
    vDFFRL #(3) wheel0ff(clk, rngwheel, wheel0, rst || rstwheels, (spincount == 0 && loadwheel));
    vDFFRL #(3) wheel1ff(clk, rngwheel, wheel1, rst || rstwheels, (spincount == 1 && loadwheel));
    vDFFRL #(3) wheel2ff(clk, rngwheel, wheel2, rst || rstwheels, (spincount == 2 && loadwheel));
    vDFFRL #(2) spincountff(clk, spincount+1, spincount, rst || rstspins, incrementspin);

    assign donespins = (spincount >= 2);
    assign win = ( wheel0 == wheel1 && wheel0 == wheel2);

    logic[2:0] rngdice, dice;
    logic startdispense, rstdcounter, stopdispense, loaddice;
    logic [2:0] dispensecounter;
    RNG #(3) generatedice(clk, rst, 1, 6, rngdice);
    vDFFRL #(3) diceff(clk, rngdice, dice, rst, loaddice || rstwheels);
    vDFFRL #(3) dispensecountff(clk, dispensecounter+1, dispensecounter, rst||rstdcounter, startdispense);
    assign stopdispense = (dispensecounter >= dice - 1);

    assign nsr = (rst) ? `PLACEBET : ns;

    assign displayfunds = funds;
    assign displaybet = bet;
    assign displaywheel0 = wheel0;
    assign displaywheel1 = wheel1;
    assign displaywheel2 = wheel2;
    assign displaydice = dice;

    always_ff @(posedge clk) begin
        ps <= nsr;
    end

    always_comb begin

        casex(ps)

        `PLACEBET : begin
            if (startbutton && enoughfunds)
                ns = `SPINWHEEL;

            else if (fundsbutton)
                ns = `ADDFUNDS;

            else
                ns = `PLACEBET;

            loadfunds = 0; loadbet = 1; loadwheel = 0; loaddice = 0; incrementspin = 0; startdispense = 0; selfunds = 0; rstwheels = 1; rstdcounter = 1; rstspins = 1;
        end

        `ADDFUNDS : begin
            loadfunds = 1; loadbet = 0; loadwheel = 0; loaddice = 0; incrementspin = 0; startdispense = 0; selfunds = 2; rstwheels = 1; rstdcounter = 0; rstspins = 0;

            ns = `WAITRELEASEFUNDS;
        end

        `WAITRELEASEFUNDS : begin
            if(fundsbutton)
                ns = `WAITRELEASEFUNDS;
            else 
                ns = `PLACEBET;
            
            loadfunds = 0; loadbet = 0; loadwheel = 0; loaddice = 0; incrementspin = 0; startdispense = 0; selfunds = 0; rstwheels = 1; rstdcounter = 0; rstspins = 0;
        end

        `SPINWHEEL : begin
            if(wheelbutton)
                ns = `STOPWHEEL;
            else
                ns = `SPINWHEEL;
            loadfunds = 0; loadbet = 0; loadwheel = 1; loaddice = 0; incrementspin = 0; startdispense = 0; selfunds = 0; rstwheels = 0; rstdcounter = 0; rstspins = 0;
        end


        `STOPWHEEL : begin
            if(wheelbutton)
                ns = `STOPWHEEL;
            else if(donespins)
                ns = `CHECKWIN;
            else
                ns = `INCREMENTSPINCOUNTER;

            loadfunds = 0; loadbet = 0; loadwheel = 0; loaddice = 0; incrementspin = 0; startdispense = 0; selfunds = 0; rstwheels = 0; rstdcounter = 0; rstspins = 0;
        end

        `INCREMENTSPINCOUNTER : begin
            ns = `SPINWHEEL;
    
            loadfunds = 0; loadbet = 0; loadwheel = 0; loaddice = 0; incrementspin = 1; startdispense = 0; selfunds = 0; rstwheels = 0; rstdcounter = 0; rstspins = 0;
        end

        `CHECKWIN : begin
            if(win)
                ns = `ROLLDICE;
            else
                ns = `DECREMENTCREDITS;

            loadfunds = 0; loadbet = 0; loadwheel = 0; loaddice = 0; incrementspin = 0; startdispense = 0; selfunds = 0; rstwheels = 0; rstdcounter = 0; rstspins = 0;
        end

        `DECREMENTCREDITS : begin
            ns = `PLACEBET;

            loadfunds = 1; loadbet = 0; loadwheel = 0; loaddice = 0; incrementspin = 0; startdispense = 0; selfunds = 1; rstwheels = 1; rstdcounter = 0; rstspins = 0;
        end

        `ROLLDICE : begin
            if(wheelbutton)
                ns = `STOPDICE;
            else
                ns = `ROLLDICE;
            
            loadfunds = 0; loadbet = 0; loadwheel = 0; loaddice = 1; incrementspin = 0; startdispense = 0; selfunds = 0; rstwheels = 0; rstdcounter = 0; rstspins = 0;
        end

        `STOPDICE : begin
            if(wheelbutton)
                ns = `STOPDICE;
            else
                ns = `WINCREDITS;

            loadfunds = 0; loadbet = 0; loadwheel = 0; loaddice = 0; incrementspin = 0; startdispense = 0; selfunds = 0; rstwheels = 0; rstdcounter = 0; rstspins = 0;
        end

        `WINCREDITS : begin
            if(~stopdispense)
                ns = `WINCREDITS;
            else
                ns = `PLACEBET;
            
            loadfunds = 1; loadbet = 0; loadwheel = 0; loaddice = 0; incrementspin = 0; startdispense = 1; selfunds = 0; rstwheels = 0; rstdcounter = 0; rstspins = 0;
        end
        

        
        default: begin
            loadfunds = 0; loadbet = 0; loadwheel = 0; loaddice = 0; incrementspin = 0; startdispense = 0; selfunds = 0; rstwheels = 1; rstdcounter = 1; rstspins = 1;
        end

        endcase

    end

endmodule




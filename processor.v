`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/06/2017 02:04:30 PM
// Design Name: 
// Module Name: processor
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`define word		[15:0]
`define opcode      [15:12]
`define opcodeSystemLen [4:0]
`define dest        [11:8]
`define src         [7:4]
`define Tsrc        [3:0]
`define	I	        [7:0]	// Immediate
`define regName     [3:0]
`define regsize		[15:0]
`define memsize 	[65535:0]
`define width		16

`define signBitPos 16'h8000
`define lnsOne 16'h4000
`define lnsZero 16'h0000
`define lnsNan 16'h8000
`define lnsPosinf 16'h7fff
`define lnsNeginf 16'hffff

`define tabsize [963:0]

//condition codes
`define fPos [0]
`define ltPos [1]
`define lePos [2]
`define eqPos [3]
`define nePos [4]
`define gePos [5]
`define gtPos [6]
`define tPos [7]

//op codes
`define OPad	4'b0000
`define OPan	4'b0001
`define OPor	4'b0010
`define OPno	4'b0011
`define OPeo	4'b0100
`define OPmi	4'b0101
`define OPal	4'b0110
`define OPdl	4'b0111
`define OPml	4'b1000
`define OPsr	4'b1001
`define OPbr	4'b1010
`define OPjr	4'b1011
`define OPli	4'b1100
`define OPsi	4'b1101
`define OPlo	4'b1110
`define OPcl	4'b1110
`define OPco	4'b1110
`define OPst	4'b1110
`define OPnl	4'b1110
`define OPsy	4'b1111

`define OPnop   5'b11111

module decode(opout, regdst, opin, ir);
    output reg `opcodeSystemLen opout;
    output reg `regName regdst;
    input wire `opcodeSystemLen opin;
    input `word ir;
    
    always@(opin, ir) begin
        case(ir`opcode)
//                `OPor: opout = `OPor;
//                `OPst: opout = `OPst;
            `OPco: 
                begin
                    case(ir `dest) //use dest as extended opcode
                        //cl
                        4'b0000: begin opout = `OPcl; regdst = 0; end
                        //co
                        4'b0001: begin opout = `OPco; regdst = 0; end
                        default:
                            case(ir `Tsrc) //use t src as extended opcode
                                //lo
                                4'b0010: begin opout = `OPlo; regdst <= ir `dest; end
                                //nl
                                //4'b0011: opout = `OPnl; //dont need to implement for this assignment
                                //st
                                4'b0100: begin opout = `OPst; regdst <= 0; end
                                default: begin opout = `OPnop; regdst <= 0; end //call a system stop because we shouldnt be here
                            endcase
                    endcase
                end
//                `OPno: opout = `OPno;
//                `OPmi: opout = `OPmi;
                `OPjr: begin opout = `OPjr; regdst <= 0; end
                `OPbr: begin opout = `OPbr; regdst <= 0; end
                `OPsy: begin opout = ir`opcode; regdst <= 0; end
            default: begin opout = ir `opcode; regdst <= ir `dest; end    // most instructions, state # is opcode
        endcase
    end
endmodule

module ALU(ALUResult, cond, condUndefined, instruct, currentTsrc, currentDst, a, b);
    
    output reg `word ALUResult;
    input wire `opcodeSystemLen instruct;
    input wire `word a, b;
    input wire `regName currentDst, currentTsrc;
    
    reg `word lnsSignBit;
    reg `word lnsMagnitude, lnsMagnitudeA, lnsMagnitudeB;
    
    output reg [7:0] cond;
    output reg condUndefined;
    
    initial
    begin
        cond = 8'b10000000; //t gt ge ne eq le lt f
        condUndefined = 1'b0;
    end

    
    always@(instruct, a, b, currentTsrc, currentDst) begin
        case(instruct)
            `OPad:
                begin
                    ALUResult = a+b;
                end
            `OPan: ALUResult = a&b;
            `OPeo: ALUResult = a^b;
            `OPmi: ALUResult = (~a)+1; //2's complement??
            `OPno: ALUResult = !a;
            `OPor: ALUResult = a|b;
            `OPsr: ALUResult = a >> b;
            `OPml: //not test yet TODO: make test case
                begin
                    if ((a == `lnsNan) || (b == `lnsNan))
                    begin
                        ALUResult = `lnsNan;
                    end
                    else
                    begin
                        if ((a == `lnsZero) || (b == `lnsZero))
                        begin
                            ALUResult = `lnsZero;
                        end
                        else
                        begin
                            if ((a == `lnsPosinf) || (b == `lnsPosinf))
                            begin
                                ALUResult = (`lnsPosinf | ((a ^ b) & `signBitPos));
                            end
                            else
                            begin
                                lnsSignBit = (a ^ b) & `signBitPos;
                                lnsMagnitude = ((((a & `lnsPosinf) - `lnsOne) + ((b & `lnsPosinf) - `lnsOne)) + `lnsOne);
                                if (lnsMagnitude >= `lnsPosinf)
                                begin
                                    lnsMagnitude = `lnsPosinf; // I think i remember Dietz saying we can use the Assign 0 solution for this comparison
                                    ALUResult = lnsSignBit | lnsMagnitude;
                                end
                                else
                                begin
                                    ALUResult = lnsSignBit | lnsMagnitude;
                                end
                            end
                        end
                    end
                end
            `OPdl: //not test yet TODO: make test case
                begin
                    if ((a == `lnsNan) || (b == `lnsNan))
                    begin
                        ALUResult = `lnsNan;
                    end
                    else
                    begin
                        if (b == `lnsZero)
                        begin
                            ALUResult = `lnsNan;
                        end
                        else
                        begin
                            if (a == `lnsZero)
                            begin
                                ALUResult = `lnsZero;
                            end
                            else
                            begin
                                if (b == `lnsPosinf) begin
                                    if (a == `lnsPosinf)
                                        ALUResult = `lnsNan;
                                    else
                                        ALUResult = `lnsZero; // (a/inf)->0
                                end
                                else
                                begin
                                    if (a == `lnsPosinf)
                                    begin
                                        ALUResult = a;
                                    end
                                    else
                                    begin
                                        lnsSignBit = (a ^ b) & `signBitPos;
                                        lnsMagnitude = ((((a & `lnsPosinf) - `lnsOne) - ((b & `lnsPosinf) - `lnsOne)) + `lnsOne);
                                        if (lnsMagnitude >= `lnsPosinf)
                                        begin
                                            lnsMagnitude = `lnsPosinf; // I think i remember Dietz saying we can use the Assign 0 solution for this comparison
                                            ALUResult = lnsSignBit | lnsMagnitude;
                                        end
                                        else
                                        begin
                                            ALUResult = lnsSignBit | lnsMagnitude;
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            `OPco: 
                begin
                    case(currentDst)
                        //cl
                        4'b0000:
                            begin
                                cond = 8'b10000000;
                                condUndefined = 1'b0;
                                
                                if ((a == `lnsNan) || (b == `lnsNan))
                                begin
                                    condUndefined = 1'b1;
                                end
                                else
                                begin
                                    if ((a & `signBitPos) != (b & `signBitPos))
                                    begin
                                        if ((a & `signBitPos) == 0) //a>b?
                                        begin
                                            cond`gtPos = 1;
                                            cond`nePos = 1;
                                            cond`gePos = 1;
                                        end
                                        else //a<b?
                                        begin
                                            cond`ltPos = 1;
                                            cond`nePos = 1;
                                            cond`lePos = 1;
                                        end
                                    end
                                    else
                                    begin
                                        if (a == b) //does a = b?
                                        begin
                                            cond`eqPos = 1;
                                            cond`lePos = 1;
                                            cond`gePos = 1;
                                        end
                                        else 
                                        begin //a and b have the same sign so their magnitudes need to be compared
                                            lnsMagnitudeA = a & `lnsPosinf;
                                            lnsMagnitudeB = b & `lnsPosinf;
                                            
                                            if ((a & `signBitPos) == 0)
                                            begin //a and b are both positve values
                                                if (lnsMagnitudeA < lnsMagnitudeB) //a < b?
                                                begin
                                                     cond`ltPos = 1;
                                                     cond`nePos = 1;
                                                     cond`lePos = 1;
                                                end
                                                else //a > b??
                                                begin
                                                    cond`gtPos = 1;
                                                    cond`nePos = 1;
                                                    cond`gePos = 1;
                                                end
                                            end
                                            else
                                            begin //a and b are both negative values
                                                if (lnsMagnitudeA < lnsMagnitudeB) //a > b?
                                                begin
                                                    cond`gtPos = 1;
                                                    cond`nePos = 1;
                                                    cond`gePos = 1;
                                                end
                                                else //a < b??
                                                begin
                                                     cond`ltPos = 1;
                                                     cond`nePos = 1;
                                                     cond`lePos = 1;
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        //co
                        4'b0001: 
                            begin
                                cond = 8'b10000000;
                                condUndefined = 1'b0;
                            
                                if (a == b)
                                begin
                                    cond`eqPos = 1;
                                    cond`lePos = 1;
                                    cond`gePos = 1;
                                end
                                else
                                begin
                                    if(a > b)
                                    begin
                                        cond`gtPos = 1;
                                        cond`nePos = 1;
                                        cond`gePos = 1;
                                    end
                                    else
                                    begin
                                        if(a < b)
                                        begin
                                            cond`ltPos = 1;
                                             cond`nePos = 1;
                                             cond`lePos = 1;
                                        end
                                    end
                                end
                            end
                        default:
                            case(currentTsrc)
    //                        //lo
    //                        4'b0010: ; //just passthrough stage1srcvalue
                            //nl
                            4'b0011:
                                begin
                                    ALUResult = (a & `lnsPosinf) ? (a ^ `signBitPos) : a;
                                end
                            default: ALUResult = a;
                            endcase
                    endcase
                end
            default: ALUResult = a;
        endcase
    end

endmodule

module processor(halt, reset, clk);
    output reg halt;
    input reset, clk;
    
    reg `word regfile `regsize;
    reg `word mainmem `memsize;
    reg `word subtab `tabsize;
    reg `word addtab `tabsize;
    
    reg `word ir, nextPC;
        //TsrcValue - Tsrc value returned right after a reg file read
        //srcValue - src value returned right after a reg file read
        //dstValue - dst value returned right after a reg file read
    reg `word TsrcValue, srcValue, dstValue;
    wire `opcodeSystemLen op; //entering operation code
    wire `regName regdst; //entering destination register address, if 0 then no write to registers occurs
    wire `word ALUResult; //ALU output
    reg `word pc; //program counter
    
    //intermediate buffer variables
    reg `opcodeSystemLen stage0op, stage1op, stage2op; //opcodes for each stage
        //stage*Tsrc - address of T source register
        //stage*src - address of source register
        //stage*dst - address of destination register
        //stage*regdst - also the address of desination register but if 0, then no write it to occur
    reg `regName stage0Tsrc, stage0src, stage0dst, stage0regdst;
    reg `regName stage1Tsrc, stage1src, stage1dst, stage1regdst;
    reg `regName stage2Tsrc, stage2src, stage2dst, stage2regdst;
        //stage*TsrcValue - regfile[stage*Tsrc]
        //stage*srcValue - regfile[stage*src]
        //stage*dstValue - regfile[stage*dst]
    reg `word stage1TsrcValue, stage1srcValue, stage1dstValue;
    reg `word stage2Value;
    
    wire [7:0] conditions; //comes from ALU
    wire condUndefined; //comes from ALU
    
    reg isSquash, rrsquash; //bits used to control instruction squashing
    
    //sign extend immediate
    wire `word sexi;
    assign sexi = { (ir[7] ? 8'b11111111 : 8'b00000000), (ir `I) };
    
    reg `word sexi_delayed; //used for load immediate
    always@(posedge clk)
    begin
        sexi_delayed <= sexi;
    end
    
    always@(reset)begin
        halt = 0;
        pc = 0;
        stage0op = `OPnop;
        stage1op = `OPnop;
        stage2op = `OPnop;
        //$readmemh0(regfile);
        $readmemh("E:/nextcloud/School/EE480/Assignment4/assignment4/data.list",regfile);
        //$readmemh1(mainmem);
        $readmemh("E:/nextcloud/School/EE480/Assignment4/assignment4/text.list",mainmem);
        //$readmemh1(addtab);
        $readmemh("E:/nextcloud/School/EE480/Assignment4/assignment4/addtab.list",addtab);
        //$readmemh1(subtab);
        $readmemh("E:/nextcloud/School/EE480/Assignment4/assignment4/subtab.list",subtab);
    end
    
    //instruction decoder
    decode inst_decode(op, regdst, stage0op, ir);
    //arithmetic logic unit
    ALU inst_ALU(ALUResult, conditions, condUndefined, stage1op, stage1Tsrc, stage1dst, stage1srcValue, stage1TsrcValue);
    
    //instruction register
    always@(*) ir = mainmem[pc];
                                        
    //compute srcValue, with value forwarding
    always @(*) if (stage0op == `OPli) srcValue = sexi_delayed; // catch immediate for li
                else srcValue = ( (stage1regdst === 4'bXXXX) ? regfile[stage0src] : (((stage1regdst && (stage0src == stage1regdst)) ? ALUResult :
                                    ( (stage2regdst === 4'bXXXX) ? regfile[stage0src] : (((stage2regdst && (stage0src == stage2regdst)) ? stage2Value :
                                        regfile[stage0src]))))));
                                    
    //compute TsrcValue, with value forwarding
    always @(*) TsrcValue = ( (stage1regdst === 4'bXXXX) ? regfile[stage0Tsrc] : (((stage1regdst && (stage0Tsrc == stage1regdst)) ? ALUResult :
                                ( (stage2regdst === 4'bXXXX) ? regfile[stage0Tsrc] : (((stage2regdst && (stage0Tsrc == stage2regdst)) ? stage2Value :
                                    regfile[stage0Tsrc]))))));
    
    //compute dstval, with value forwarding
    always @(*) dstValue = ( (stage1regdst === 4'bXXXX) ? regfile[stage0dst] : (((stage1regdst && (stage0dst == stage1regdst)) ? ALUResult :
                               ( (stage2regdst === 4'bXXXX) ? regfile[stage0dst] : (((stage2regdst && (stage0dst == stage2regdst)) ? stage2Value :
                                    regfile[stage0dst]))))));
    
    //new pc
    always @(*) nextPC = (((stage1op == `OPbr) && (conditions[stage1dst] == 1)) ? (pc + sexi) : 
                            ( ((stage1op == `OPjr) && (conditions[stage1Tsrc] == 1)) ? (stage1dstValue) :
                            (pc + 1)));
    
    //IS squash - for jr and br
    always@(*)
    begin
        isSquash = (((stage1op == `OPbr) && (conditions[stage1dst] == 1)) || ((stage1op == `OPjr) && (conditions[stage1Tsrc] == 1)));
    end
    
    //TODO: check if needed, if so - why?
    //RR squash - 
    always@(*)
    begin
        rrsquash = isSquash;
    end
    
    //fetch instruction stage 0
    always@(posedge clk)
    begin
        if(!halt)
        begin
            //write stage 0's buffer
            stage0op <= (isSquash ? `OPnop : op);
            stage0regdst <= (isSquash ? 0 : regdst);
            stage0Tsrc <= ir `Tsrc;
            stage0src <= ir `src;
            stage0dst <= ir `dest;
            pc <= nextPC;
        end
    end
    
    //reg read state 1
    always@(posedge clk)
    begin
        if(!halt)
        begin
            //load stage 1's information buffer
            stage1op <= (rrsquash ? `OPnop : stage0op);
            stage1regdst <= (rrsquash ? 0 : stage0regdst);
            stage1srcValue <= srcValue;
            stage1TsrcValue <= TsrcValue;
            stage1dstValue <= dstValue;
            stage1Tsrc <= stage0Tsrc;
            stage1src <= stage0src;
            stage1dst <= stage0dst;
        end
    end
    
    //ALU operation stage 2
    always@(posedge clk)
    begin
        if(!halt)
        begin
            //load stage 2's information buffer
            stage2op <= stage1op;
            stage2regdst <= stage1regdst;
            stage2Tsrc <= stage1Tsrc;
            stage2src <= stage1src;
            stage2dst <= stage1dst;
            stage2Value <= ( (stage1op == `OPsi) ? ( (stage1dstValue << 8)|({stage1src,stage1Tsrc}&8'b11111111)) : ((stage1op == `OPli) ? stage1srcValue : ((stage1op == `OPlo && stage1dst != 0 && stage1dst != 1 && stage1Tsrc == 2) ? mainmem[stage1srcValue] : ALUResult)));
            if (stage1op == `OPst && stage1dst != 0 && stage1dst != 1 && stage1Tsrc == 4) mainmem[stage1srcValue] <= stage1dstValue;
            if (stage1op == `OPsy) halt <= 1;
        end
    end
    
    reg `word previousstage2Value;
    //reg write stage 3
    always@(posedge clk)
    begin
        if(!halt)
        begin
                if (stage2regdst !=0) regfile[stage2regdst] <= stage2Value;
        end
    end
endmodule

module processor_tb();
    reg reset = 0;
    reg clk = 0;
    wire halted;
    integer i = 0;
    processor PE(halted, reset, clk);
    initial begin
        //$dumpfile;
        //$dumpvars(0, PE);
        #10 reset = 1;
        #10 reset = 0;
        while (!halted && (i < 200)) begin
            #10 clk = 1;
            #10 clk = 0;
            i=i+1;
        end
        $finish;
    end
endmodule
